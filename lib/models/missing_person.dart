import 'package:cloud_firestore/cloud_firestore.dart';

enum PersonStatus {
  missing,
  possibleMatch,
  found,
}

extension PersonStatusExtension on PersonStatus {
  String get displayName {
    switch (this) {
      case PersonStatus.missing:
        return 'Missing';
      case PersonStatus.possibleMatch:
        return 'Possible Match';
      case PersonStatus.found:
        return 'Found';
    }
  }
}

class MissingPerson {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final DateTime missingDate;
  final String lastSeenLocation;
  final String description;
  final String contactNumber;
  final String? photoUrl;
  final DateTime reportDate;
  final String reportStatus;
  final String verificationStatus; // 'Pending', 'Approved', 'Rejected', 'Verified'
  final String? reportedBy;
  final String? rejectionReason;
  final String? verifiedBy;
  final bool isUrgent;
  final List<double>? faceEmbedding; // 128-D Normalized Biometric Face Vector

  const MissingPerson({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.missingDate,
    required this.lastSeenLocation,
    required this.description,
    required this.contactNumber,
    this.photoUrl,
    required this.reportDate,
    this.reportStatus = 'Missing',
    this.verificationStatus = 'Approved', // Defaults to Approved for accessibility
    this.reportedBy,
    this.rejectionReason,
    this.verifiedBy,
    this.isUrgent = false,
    this.faceEmbedding,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isApproved =>
      verificationStatus.toLowerCase() == 'approved' || isVerified;
  bool get isPending => verificationStatus.toLowerCase() == 'pending';
  bool get isRejected => verificationStatus.toLowerCase() == 'rejected';

  // Backward compatibility getters
  DateTime get createdAt => reportDate;
  String get name => fullName;
  DateTime get lastSeenDate => missingDate;
  String get lastSeenCity => lastSeenLocation;
  String get contactPhone => contactNumber;
  String get contactName => fullName;
  String get policeDepartment => 'Emergency Contact Desk';
  String get avatarUrl => photoUrl ?? '';
  String get circumstances => description;
  String get clothing => 'Standard clothing';
  String get height => 'N/A';
  String get weight => 'N/A';
  String get eyeColor => 'N/A';
  String get hairColor => 'N/A';
  String get medicalConditions => 'None reported';
  String? get reward => null;
  double? get rewardAmount => null;
  bool get isBookmarked => false;
  int get sightingsCount => 0;
  List<dynamic> get sightings => const [];

  List<String> get photoUrls =>
      photoUrl != null && photoUrl!.trim().isNotEmpty ? [photoUrl!.trim()] : [];

  PersonStatus get status {
    switch (reportStatus.toLowerCase()) {
      case 'found':
        return PersonStatus.found;
      case 'possible match':
      case 'sighted':
        return PersonStatus.possibleMatch;
      case 'missing':
      default:
        return PersonStatus.missing;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'missingDate': Timestamp.fromDate(missingDate),
      'lastSeenLocation': lastSeenLocation,
      'description': description,
      'contactNumber': contactNumber,
      'photoUrl': photoUrl,
      'reportDate': Timestamp.fromDate(reportDate),
      'reportStatus': reportStatus,
      'verificationStatus': verificationStatus,
      'reportedBy': reportedBy,
      'rejectionReason': rejectionReason,
      'verifiedBy': verifiedBy,
      'isUrgent': isUrgent,
      'faceEmbedding': faceEmbedding,
    };
  }

  factory MissingPerson.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    List<double>? parseEmbedding(dynamic value) {
      if (value is List) {
        try {
          return value.map((e) => (e as num).toDouble()).toList();
        } catch (_) {}
      }
      return null;
    }

    return MissingPerson(
      id: id,
      fullName: map['fullName'] ?? map['name'] ?? '',
      age: map['age'] is int
          ? map['age']
          : (int.tryParse(map['age']?.toString() ?? '0') ?? 0),
      gender: map['gender'] ?? 'Male',
      missingDate: parseDate(map['missingDate'] ?? map['lastSeenDate']),
      lastSeenLocation: map['lastSeenLocation'] ?? map['lastSeenCity'] ?? '',
      description: map['description'] ?? '',
      contactNumber: map['contactNumber'] ?? map['contactPhone'] ?? '',
      photoUrl: map['photoUrl'] ??
          (map['photoUrls'] is List && (map['photoUrls'] as List).isNotEmpty
              ? map['photoUrls'][0]
              : null),
      reportDate: parseDate(map['reportDate'] ?? map['createdAt']),
      reportStatus: map['reportStatus'] ?? 'Missing',
      verificationStatus: map['verificationStatus'] ?? 'Approved',
      reportedBy: map['reportedBy'],
      rejectionReason: map['rejectionReason'],
      verifiedBy: map['verifiedBy'],
      isUrgent: map['isUrgent'] ?? false,
      faceEmbedding: parseEmbedding(map['faceEmbedding']),
    );
  }

  MissingPerson copyWith({
    String? id,
    String? fullName,
    int? age,
    String? gender,
    DateTime? missingDate,
    String? lastSeenLocation,
    String? description,
    String? contactNumber,
    String? photoUrl,
    DateTime? reportDate,
    String? reportStatus,
    String? verificationStatus,
    String? reportedBy,
    String? rejectionReason,
    String? verifiedBy,
    bool? isUrgent,
    List<double>? faceEmbedding,
  }) {
    return MissingPerson(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      missingDate: missingDate ?? this.missingDate,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      description: description ?? this.description,
      contactNumber: contactNumber ?? this.contactNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      reportDate: reportDate ?? this.reportDate,
      reportStatus: reportStatus ?? this.reportStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reportedBy: reportedBy ?? this.reportedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      isUrgent: isUrgent ?? this.isUrgent,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
    );
  }
}
