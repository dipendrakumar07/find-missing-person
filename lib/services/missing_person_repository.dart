import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/missing_person.dart';
import 'auth_service.dart';
import 'face_embedding_engine.dart';
import 'found_report_service.dart';

class MissingPersonRepository extends ChangeNotifier {
  static final MissingPersonRepository _instance =
      MissingPersonRepository._internal();

  factory MissingPersonRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('missing_persons');

  StreamSubscription<QuerySnapshot>? _subscription;
  List<MissingPerson> _reports = [];
  bool _isInitialized = false;

  MissingPersonRepository._internal() {
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _subscription = _collection
          .orderBy('reportDate', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _reports = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return MissingPerson.fromMap(data, doc.id);
          }).toList();
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Firestore listen notice: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing Firestore listener: $e');
    }
  }

  List<MissingPerson> get reports => List.unmodifiable(_reports);

  int get count => _reports.length;

  int get pendingCount =>
      _reports.where((r) => r.verificationStatus.toLowerCase() == 'pending').length;

  int get verifiedCount =>
      _reports.where((r) => r.isVerified).length;

  int get approvedCount =>
      _reports.where((r) => r.verificationStatus.toLowerCase() == 'approved').length;

  int get rejectedCount =>
      _reports.where((r) => r.isRejected).length;

  int get foundCount =>
      _reports.where((r) => r.reportStatus.toLowerCase() == 'found').length;

  Stream<List<MissingPerson>> get reportsStream {
    return _collection
        .orderBy('reportDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MissingPerson.fromMap(data, doc.id);
      }).toList();
    }).handleError((e) {
      debugPrint('Stream fallback to local reports: $e');
      return _reports;
    });
  }

  MissingPerson? getPersonById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a missing person report with automated bidirectional matching against existing found reports.
  Future<String> addReport(MissingPerson report) async {
    String docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

    // Extract 128-D face embedding if photo is present and embedding not yet calculated
    List<double>? embedding = report.faceEmbedding;
    if (embedding == null && report.photoUrl != null && report.photoUrl!.isNotEmpty) {
      try {
        final extraction = await FaceEmbeddingEngine().processAndExtractEmbedding(
          photoUrlOrBase64: report.photoUrl,
        );
        if (extraction.isValid) {
          embedding = extraction.embedding;
        }
      } catch (e) {
        debugPrint('Face embedding extraction notice during addReport: $e');
      }
    }

    // 1. Perform automated AI matching against any existing unlinked Found Reports
    final matchResult = await FoundReportService().findMatchingFoundReportFor(report);
    final initialStatus = (matchResult != null && report.reportStatus.toLowerCase() != 'found')
        ? 'Possible Match'
        : report.reportStatus;

    final reportToSave = report.copyWith(
      reportStatus: initialStatus,
      faceEmbedding: embedding,
    );

    // De-duplication check: prevent identical report from being added multiple times within 10 seconds
    final isDuplicate = _reports.any((r) =>
        r.fullName.toLowerCase().trim() == report.fullName.toLowerCase().trim() &&
        r.contactNumber.trim() == report.contactNumber.trim() &&
        r.reportedBy == report.reportedBy &&
        DateTime.now().difference(r.reportDate).inSeconds.abs() < 12);
    if (isDuplicate) {
      debugPrint('Prevented duplicate report submission for: ${report.fullName}');
      final existing = _reports.firstWhere((r) =>
          r.fullName.toLowerCase().trim() == report.fullName.toLowerCase().trim() &&
          r.reportedBy == report.reportedBy);
      return existing.id;
    }

    final apiKey = _firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        final docRef = await _collection.add(reportToSave.toMap()).timeout(const Duration(seconds: 12));
        docId = docRef.id;
      } catch (e) {
        debugPrint('Firestore add notice (persisting in-memory): $e');
      }
    }

    final createdReport = reportToSave.copyWith(id: docId);
    _reports.removeWhere((r) => r.id == docId);
    _reports.insert(0, createdReport);
    notifyListeners();

    // 2. If matched with a previously submitted found report, link them
    if (matchResult != null) {
      FoundReportService().linkFoundReportToMissingPerson(
        foundReportId: matchResult.report.id,
        missingPersonId: docId,
        missingPersonName: report.fullName,
        similarityScore: matchResult.score,
        matchReason: matchResult.reason,
      );

      if (report.reportedBy != null && report.reportedBy!.isNotEmpty) {
        FoundReportService().sendNotification(
          recipientUserId: report.reportedBy!,
          title: 'AI Visual Match Alert (${matchResult.score}%)',
          message:
              'A previously reported sighting at "${matchResult.report.foundLocation}" matched your missing report with ${matchResult.score}% similarity.',
          missingPersonId: docId,
          foundReportId: matchResult.report.id,
        );
      }
    }

    return docId;
  }

  Future<void> updateReport(MissingPerson report) async {
    final apiKey = _firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        await _collection.doc(report.id).set(report.toMap(), SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Firestore update notice: $e');
      }
    }

    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
    } else {
      _reports.insert(0, report);
    }
    notifyListeners();
  }

  /// Update just the photo URL for a missing person report permanently
  Future<void> updatePhoto(String id, String photoUrl) async {
    final apiKey = _firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        await _collection.doc(id).set({'photoUrl': photoUrl}, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Firestore photo update notice: $e');
      }
    }

    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(photoUrl: photoUrl);
      notifyListeners();
    }
  }

  Future<void> updateVerificationStatus(
    String id,
    String verificationStatus, {
    String? rejectionReason,
    String? verifiedBy,
  }) async {
    final updates = <String, dynamic>{
      'verificationStatus': verificationStatus,
    };

    if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;
    if (verifiedBy != null) updates['verifiedBy'] = verifiedBy;

    final apiKey = _firestore.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        await _collection.doc(id).update(updates).timeout(const Duration(milliseconds: 2000));
      } catch (_) {}
    }

    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(
        verificationStatus: verificationStatus,
        rejectionReason: rejectionReason,
        verifiedBy: verifiedBy,
      );
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, PersonStatus status) async {
    final statusStr = status == PersonStatus.found
        ? 'Found'
        : status == PersonStatus.possibleMatch
            ? 'Possible Match'
            : 'Missing';
    final person = getPersonById(id);
    if (person != null) {
      await updateReport(person.copyWith(reportStatus: statusStr));
    }
  }

  void toggleBookmark(String id) {
    notifyListeners();
  }

  Future<void> deleteReport(String id) async {
    final existing = getPersonById(id);
    final currentUserId = AuthService().userId;
    final isOwner = existing != null && (existing.reportedBy == currentUserId || AuthService().isCurrentAdmin);
    if (existing != null && !isOwner) {
      debugPrint('Unauthorized delete attempt blocked for report: $id');
      return;
    }

    try {
      await _collection.doc(id).delete();
    } catch (_) {}
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  List<MissingPerson> search(String query) {
    if (query.trim().isEmpty) return reports;
    final q = query.toLowerCase().trim();
    return _reports.where((person) {
      return person.fullName.toLowerCase().contains(q) ||
          person.lastSeenLocation.toLowerCase().contains(q) ||
          person.contactNumber.contains(q) ||
          person.description.toLowerCase().contains(q);
    }).toList();
  }

  List<MissingPerson> searchAndFilter({
    String? query,
    String? category,
    String? gender,
    PersonStatus? status,
    double? minAge,
    double? maxAge,
  }) {
    var list = _reports;

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      list = list.where((p) {
        return p.fullName.toLowerCase().contains(q) ||
            p.lastSeenLocation.toLowerCase().contains(q) ||
            p.contactNumber.contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    if (category != null && category != 'All') {
      switch (category.toLowerCase()) {
        case 'urgent alert':
          list = list.where((p) => p.isUrgent).toList();
          break;
        case 'children':
          list = list.where((p) => p.age < 18).toList();
          break;
        case 'adults':
          list = list.where((p) => p.age >= 18 && p.age < 60).toList();
          break;
        case 'seniors':
          list = list.where((p) => p.age >= 60).toList();
          break;
        case 'resolved':
          list = list.where((p) => p.reportStatus.toLowerCase() == 'found').toList();
          break;
        case 'verified':
          list = list.where((p) => p.isVerified).toList();
          break;
        case 'bookmarked':
          list = list.where((p) => p.isBookmarked).toList();
          break;
      }
    }

    if (gender != null && gender.isNotEmpty && gender != 'All') {
      list = list.where((p) => p.gender.toLowerCase() == gender.toLowerCase()).toList();
    }

    if (status != null) {
      list = list.where((p) => p.status == status).toList();
    }

    if (minAge != null) {
      list = list.where((p) => p.age >= minAge).toList();
    }

    if (maxAge != null) {
      list = list.where((p) => p.age <= maxAge).toList();
    }

    return list;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
