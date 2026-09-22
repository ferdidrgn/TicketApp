import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String? userId;
  final String? title;
  final String? body;
  final String? type;
  final String? showId;
  final String? showName;
  final String? eventDate;
  final List<String>? seats;
  final bool? isRead;
  final String? createdAt;

  const NotificationModel({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.type,
    this.showId,
    this.showName,
    this.eventDate,
    this.seats,
    this.isRead,
    this.createdAt,
  });

  /// 🔥 Firestore'dan güvenli okuma
  factory NotificationModel.fromFirestore(final Map<String, dynamic> data) =>
      NotificationModel(
        id: data['_id'] as String?,
        userId: data['userId'] as String?,
        title: data['title'] as String?,
        body: data['body'] as String?,
        type: data['type'] as String?,
        showId: data['showId'] as String?,
        showName: data['showName'] as String?,
        eventDate: data['eventDate'] as String?,
        seats: (data['seats'] as List?)?.map((e) => e.toString()).toList(),
        isRead: data['isRead'] as bool?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'showId': showId,
        'showName': showName,
        'eventDate': eventDate,
        'seats': seats,
        'isRead': isRead,
        '_createdAt': createdAt,
      };
}
