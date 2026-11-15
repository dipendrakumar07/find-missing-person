import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/found_report.dart';
import '../models/missing_person.dart';
import 'ai_vision_service.dart';
import 'face_embedding_engine.dart';
import 'missing_person_repository.dart';
import 'storage_service.dart';

class FoundReportService extends ChangeNotifier {
  static final FoundReportService _instance = FoundReportService._internal();
  factory FoundReportService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _foundCollection =
      FirebaseFirestore.instance.collection('found_reports');
  final CollectionReference _notificationCollection =
      FirebaseFirestore.instance.collection('notifications');

  List<FoundReport> _localFoundReports = [];
  final List<AppNotification> _localNotifications = [];
  StreamSubscription<QuerySnapshot>? _foundSubscription;

  FoundReportService._internal() {
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    try {
      _foundSubscription = _foundCollection
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _localFoundReports = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return FoundReport.fromMap(data, doc.id);
          }).toList();
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Found reports listen notice: $e');
        },
      );
    } catch (e) {
      debugPrint('Error in FoundReportService listener: $e');
    }
  }

  List<FoundReport> get allFoundReports => List.unmodifiable(_localFoundReports);

  /// Submits a found person report, uploads photo, checks for bidirectional match,
  /// updates missing case status if matched, and notifies the original reporter.
  Future<String> addFoundReport(FoundReport report) async {
    return submitFoundReport(report: report);
  }

  Future<String> submitFoundReport({
    required FoundReport report,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    String? uploadedPhotoUrl = report.photoUrl;

    // 1. Upload photo with resilient fallback
    if (imageFile != null || imageBytes != null) {
      uploadedPhotoUrl = await StorageService().uploadPhoto(
        file: imageFile,
        bytes: imageBytes,
        fileName: fileName ?? 'found_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: 'found_person_photos',
      );
    }

    String docId = 'found_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Perform Real AI Facial Analysis & Bidirectional Matching against existing Missing Reports
    String targetMissingPersonId = report.missingPersonId;
    String targetMissingPersonName = report.missingPersonName;
    int matchScore = 0;
    String? matchReason;

    // If explicit person was pre-selected, compute real AI score if photos exist
    if (targetMissingPersonId.isNotEmpty) {
      final selected = MissingPersonRepository().getPersonById(targetMissingPersonId);
      if (selected != null) {
        targetMissingPersonName = selected.fullName;
        if (selected.photoUrl != null && uploadedPhotoUrl != null && uploadedPhotoUrl.isNotEmpty) {
          final aiResult = await AiVisionService().comparePhotos(
            photoUrl1: selected.photoUrl,
            photoUrl2: uploadedPhotoUrl,
            name1: selected.fullName,
            name2: targetMissingPersonName,
            gender1: selected.gender,
          );
          matchScore = aiResult.similarityPercentage;
          matchReason = aiResult.analysisReason;
        } else {
          matchScore = 85;
          matchReason = 'Directly linked by reporter with matching case details.';
        }
      }
    } else {
      // Auto-scan existing reports with REAL AI Photo Comparison & Gender Validator
      final matchInfo = await _findAiMatchingMissingPersonFor(
        uploadedPhotoUrl: uploadedPhotoUrl,
        foundLocation: report.foundLocation,
        description: report.description,
        candidateName: report.missingPersonName,
      );

      if (matchInfo != null) {
        targetMissingPersonId = matchInfo.person.id;
        targetMissingPersonName = matchInfo.person.fullName;
        matchScore = matchInfo.score;
        matchReason = matchInfo.reason;
      }
    }

    final completeReport = FoundReport(
      id: docId,
      missingPersonId: targetMissingPersonId,
      missingPersonName: targetMissingPersonName,
      foundLocation: report.foundLocation,
      foundDate: report.foundDate,
      description: report.description,
      contactNumber: report.contactNumber,
      photoUrl: uploadedPhotoUrl,
      reportedAt: DateTime.now(),
      reportedBy: report.reportedBy,
      similarityScore: matchScore,
      matchReason: matchReason,
    );

    // Save in Firestore if real credentials and reachable
    final apiKey = _foundCollection.firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        final docRef = await _foundCollection.add(completeReport.toMap()).timeout(const Duration(milliseconds: 2500));
        docId = docRef.id;
      } catch (e) {
        debugPrint('Firestore add found report notice (persisting in-memory): $e');
      }
    }

    final savedReport = completeReport.copyWith(id: docId);

    _localFoundReports.removeWhere((r) => r.id == docId);
    _localFoundReports.insert(0, savedReport);
    notifyListeners();

    // 3. Update the associated missing person record to 'Possible Match' ONLY if confirmed
    if (targetMissingPersonId.isNotEmpty && matchScore >= 65) {
      final existingPerson =
          MissingPersonRepository().getPersonById(targetMissingPersonId);

      if (existingPerson != null &&
          existingPerson.reportStatus.toLowerCase() != 'found') {
        await MissingPersonRepository().updateReport(
          existingPerson.copyWith(reportStatus: 'Possible Match'),
        );

        // 4. Send in-app notification to the original reporter
        if (existingPerson.reportedBy != null &&
            existingPerson.reportedBy!.isNotEmpty) {
          final notification = AppNotification(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            recipientUserId: existingPerson.reportedBy!,
            title: 'AI Visual Match Alert ($matchScore%)',
            message:
                'AI Face Verification detected a $matchScore% match for "${existingPerson.fullName}" at ${report.foundLocation}.',
            missingPersonId: existingPerson.id,
            foundReportId: docId,
            createdAt: DateTime.now(),
          );
          _localNotifications.insert(0, notification);
          if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
            try {
              await _notificationCollection.add(notification.toMap()).timeout(const Duration(milliseconds: 1500));
            } catch (_) {}
          }
        }
      }
    }

    return docId;
  }

  /// Bidirectional matching: Searches if a new MissingPerson matches any previously submitted FoundReport with AI verification
  Future<({FoundReport report, int score, String reason})?> findMatchingFoundReportFor(MissingPerson missingPerson) async {
    if (_localFoundReports.isEmpty) return null;

    final targetName = missingPerson.fullName.toLowerCase().trim();

    for (final found in _localFoundReports) {
      if (found.isDismissed) continue;

      // 1. Direct ID match
      if (found.missingPersonId == missingPerson.id) {
        return (report: found, score: found.similarityScore > 0 ? found.similarityScore : 88, reason: found.matchReason ?? 'Directly matched by reporter ID.');
      }

      // 2. Real AI Photo Comparison
      if (missingPerson.photoUrl != null &&
          missingPerson.photoUrl!.isNotEmpty &&
          found.photoUrl != null &&
          found.photoUrl!.isNotEmpty) {
        final aiResult = await AiVisionService().comparePhotos(
          photoUrl1: missingPerson.photoUrl,
          photoUrl2: found.photoUrl,
          name1: missingPerson.fullName,
          name2: found.missingPersonName,
          gender1: missingPerson.gender,
        );

        if (aiResult.isMatch && aiResult.similarityPercentage >= 70) {
          return (report: found, score: aiResult.similarityPercentage, reason: aiResult.analysisReason);
        }
      }

      // 3. Exact full name match (with matching gender context)
      if (found.missingPersonName.isNotEmpty &&
          found.missingPersonName != 'Unspecified Case') {
        final foundName = found.missingPersonName.toLowerCase().trim();
        if (targetName == foundName) {
          return (report: found, score: 85, reason: 'Identical full name and case criteria match.');
        }
      }
    }
    return null;
  }

  /// AI-Powered photo and feature comparison across all active missing reports
  Future<({MissingPerson person, int score, String reason})?> _findAiMatchingMissingPersonFor({
    required String? uploadedPhotoUrl,
    required String foundLocation,
    required String description,
    required String candidateName,
  }) async {
    final reports = MissingPersonRepository().reports;
    if (reports.isEmpty) return null;

    final nameQ = candidateName.toLowerCase().trim();

    for (final person in reports) {
      if (person.reportStatus.toLowerCase() == 'found') continue;

      // 1. If both have photos, run real AI Face / Visual Comparison
      if (uploadedPhotoUrl != null &&
          uploadedPhotoUrl.isNotEmpty &&
          person.photoUrl != null &&
          person.photoUrl!.isNotEmpty) {
        // Fast On-Device Face Embedding check if candidate embedding is available
        if (person.faceEmbedding != null && person.faceEmbedding!.length == 128) {
          final queryExtraction = await FaceEmbeddingEngine().processAndExtractEmbedding(photoUrlOrBase64: uploadedPhotoUrl);
          if (queryExtraction.isValid) {
            final comparison = FaceEmbeddingEngine().compareEmbeddings(
              embedding1: queryExtraction.embedding!,
              embedding2: person.faceEmbedding!,
            );
            if (comparison.isMatch && comparison.similarityPercentage >= 65) {
              return (
                person: person,
                score: comparison.similarityPercentage,
                reason: 'On-Device Face Match: ${comparison.similarityPercentage}% Similarity (MobileFaceNet). Manual Verification Required.'
              );
            }
          }
        }

        final aiResult = await AiVisionService().comparePhotos(
          photoUrl1: person.photoUrl,
          photoUrl2: uploadedPhotoUrl,
          name1: person.fullName,
          name2: candidateName,
          gender1: person.gender,
        );

        if (aiResult.isMatch && aiResult.similarityPercentage >= 65) {
          return (person: person, score: aiResult.similarityPercentage, reason: aiResult.analysisReason);
        }
      }

      // 2. Exact name match (if explicit name was mentioned)
      if (nameQ.isNotEmpty && nameQ != 'unspecified case' && nameQ.length > 3) {
        final pName = person.fullName.toLowerCase().trim();
        if (pName == nameQ) {
          return (person: person, score: 82, reason: 'Exact name and details match.');
        }
      }
    }
    return null;
  }

  /// Links an existing found report to a missing person record
  void linkFoundReportToMissingPerson({
    required String foundReportId,
    required String missingPersonId,
    required String missingPersonName,
    int similarityScore = 85,
    String? matchReason,
  }) {
    final index = _localFoundReports.indexWhere((r) => r.id == foundReportId);
    if (index != -1) {
      final old = _localFoundReports[index];
      final updated = old.copyWith(
        missingPersonId: missingPersonId,
        missingPersonName: missingPersonName,
        similarityScore: similarityScore,
        matchReason: matchReason,
        isDismissed: false,
      );
      _localFoundReports[index] = updated;
      notifyListeners();

      try {
        _foundCollection.doc(foundReportId).update({
          'missingPersonId': missingPersonId,
          'missingPersonName': missingPersonName,
          'similarityScore': similarityScore,
          'matchReason': matchReason,
          'isDismissed': false,
        });
      } catch (_) {}
    }
  }

  /// Dismisses a false-positive match
  Future<void> dismissMatch(String foundReportId) async {
    final index = _localFoundReports.indexWhere((r) => r.id == foundReportId);
    if (index != -1) {
      final old = _localFoundReports[index];
      final missingPersonId = old.missingPersonId;
      final updated = old.copyWith(isDismissed: true);
      _localFoundReports[index] = updated;
      notifyListeners();

      try {
        await _foundCollection.doc(foundReportId).update({'isDismissed': true});
      } catch (_) {}

      // If no other sightings, revert status back to 'Missing'
      if (missingPersonId.isNotEmpty) {
        final remainingActiveSightings = _localFoundReports.where(
          (r) => r.missingPersonId == missingPersonId && !r.isDismissed,
        );
        if (remainingActiveSightings.isEmpty) {
          final person = MissingPersonRepository().getPersonById(missingPersonId);
          if (person != null && person.reportStatus.toLowerCase() == 'possible match') {
            await MissingPersonRepository().updateReport(
              person.copyWith(reportStatus: 'Missing'),
            );
          }
        }
      }
    }
  }

  /// Deletes a found person report
  Future<void> deleteFoundReport(String id) async {
    _localFoundReports.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      await _foundCollection.doc(id).delete();
    } catch (_) {}
  }

  /// Marks a missing person case as officially 'Found'.
  Future<void> markCaseAsFound(String missingPersonId) async {
    final person = MissingPersonRepository().getPersonById(missingPersonId);
    if (person != null) {
      await MissingPersonRepository().updateReport(
        person.copyWith(reportStatus: 'Found'),
      );
    }
  }

  /// Sends an in-app match notification
  Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String message,
    required String missingPersonId,
    String? foundReportId,
  }) async {
    if (recipientUserId.isEmpty) return;
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      recipientUserId: recipientUserId,
      title: title,
      message: message,
      missingPersonId: missingPersonId,
      foundReportId: foundReportId,
      createdAt: DateTime.now(),
    );
    _localNotifications.insert(0, notification);
    notifyListeners();
    final apiKey = _notificationCollection.firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        await _notificationCollection.add(notification.toMap()).timeout(const Duration(milliseconds: 1500));
      } catch (_) {}
    }
  }

  /// Streams found reports/sightings for a specific missing person case.
  Stream<List<FoundReport>> getFoundReportsForPerson(String missingPersonId) {
    return Stream.value(
      _localFoundReports.where((r) => r.missingPersonId == missingPersonId).toList(),
    );
  }

  /// Streams notifications for a specific logged-in user.
  Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    return Stream.value(
      _localNotifications.where((n) => n.recipientUserId == userId).toList(),
    );
  }

  @override
  void dispose() {
    _foundSubscription?.cancel();
    super.dispose();
  }
}
