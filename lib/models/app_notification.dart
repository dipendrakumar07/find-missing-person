import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String recipientUserId;
  final String title;
  final String message;
  final String missingPersonId;
  final String? foundReportId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.message,
    required this.missingPersonId,
    this.foundReportId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientUserId': recipientUserId,
      'title': title,
      'message': message,
      'missingPersonId': missingPersonId,
      'foundReportId': foundReportId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
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

    return AppNotification(
      id: id,
      recipientUserId: map['recipientUserId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      missingPersonId: map['missingPersonId'] ?? '',
      foundReportId: map['foundReportId'],
      createdAt: parseDate(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }
}
