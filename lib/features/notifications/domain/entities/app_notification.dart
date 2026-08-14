import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? route;
  final DateTime createdAt;
  final List<String> readBy;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readBy,
    this.route,
  });

  bool isReadBy(final String? userId) =>
      userId != null && readBy.contains(userId);

  @override
  List<Object?> get props => [id, title, body, type, route, createdAt, readBy];
}
