import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_notification.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? route;
  final DateTime createdAt;
  final List<String> readBy;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readBy,
    this.route,
  });

  factory NotificationModel.fromFirestore(final Map<String, dynamic> data) {
    final timestamp = data['_createdAt'];
    return NotificationModel(
      id: data['_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      route: data['route'] as String?,
      readBy:
          (data['readBy'] as List?)?.map((final e) => e.toString()).toList() ??
              const [],
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        route: route,
        createdAt: createdAt,
        readBy: readBy,
      );
}
