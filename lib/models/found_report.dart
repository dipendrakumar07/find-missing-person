import 'package:cloud_firestore/cloud_firestore.dart';

class FoundReport {
  final String id;
  final String missingPersonId;
  final String missingPersonName;
  final String foundLocation;
  final DateTime foundDate;
  final String description;
  final String contactNumber;
  final String? photoUrl;
  final DateTime reportedAt;
  final String? reportedBy;
  final int similarityScore;
  final String? matchReason;
  final bool isDismissed;

  const FoundReport({
    required this.id,
    required this.missingPersonId,
    required this.missingPersonName,
    required this.foundLocation,
    required this.foundDate,
    required this.description,
    required this.contactNumber,
    this.photoUrl,
    required this.reportedAt,
    this.reportedBy,
    this.similarityScore = 0,
    this.matchReason,
    this.isDismissed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'missingPersonId': missingPersonId,
      'missingPersonName': missingPersonName,
      'foundLocation': foundLocation,
      'foundDate': Timestamp.fromDate(foundDate),
      'description': description,
      'contactNumber': contactNumber,
      'photoUrl': photoUrl,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'reportedBy': reportedBy,
      'similarityScore': similarityScore,
      'matchReason': matchReason,
      'isDismissed': isDismissed,
    };
  }

  factory FoundReport.fromMap(Map<String, dynamic> map, String id) {
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

    return FoundReport(
      id: id,
      missingPersonId: map['missingPersonId'] ?? '',
      missingPersonName: map['missingPersonName'] ?? '',
      foundLocation: map['foundLocation'] ?? '',
      foundDate: parseDate(map['foundDate']),
      description: map['description'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      photoUrl: map['photoUrl'],
      reportedAt: parseDate(map['reportedAt']),
      reportedBy: map['reportedBy'],
      similarityScore: (map['similarityScore'] as num?)?.toInt() ?? 0,
      matchReason: map['matchReason'],
      isDismissed: map['isDismissed'] == true,
    );
  }

  FoundReport copyWith({
    String? id,
    String? missingPersonId,
    String? missingPersonName,
    String? foundLocation,
    DateTime? foundDate,
    String? description,
    String? contactNumber,
    String? photoUrl,
    DateTime? reportedAt,
    String? reportedBy,
    int? similarityScore,
    String? matchReason,
    bool? isDismissed,
  }) {
    return FoundReport(
      id: id ?? this.id,
      missingPersonId: missingPersonId ?? this.missingPersonId,
      missingPersonName: missingPersonName ?? this.missingPersonName,
      foundLocation: foundLocation ?? this.foundLocation,
      foundDate: foundDate ?? this.foundDate,
      description: description ?? this.description,
      contactNumber: contactNumber ?? this.contactNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      reportedAt: reportedAt ?? this.reportedAt,
      reportedBy: reportedBy ?? this.reportedBy,
      similarityScore: similarityScore ?? this.similarityScore,
      matchReason: matchReason ?? this.matchReason,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
