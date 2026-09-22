import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

extension NotificationModelMapper on NotificationModel {
  /// Model -> Entity (Okuma)
  AppNotification toEntity() => AppNotification(
        id: id ?? '',
        userId: userId ?? '',
        title: title ?? '',
        body: body ?? '',
        type: NotificationType.fromString(type),
        showId: showId ?? '',
        showName: showName ?? '',
        eventDate: eventDate ?? '',
        seats: seats?.whereType<String>().toList() ?? [],
        isRead: isRead ?? false,
        createdAt: createdAt ?? '',
      );
}

extension NotificationEntityMapper on AppNotification {
  /// Entity -> Model (Yazma)
  NotificationModel toModel() => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type.name,
        showId: showId,
        showName: showName,
        eventDate: eventDate,
        seats: seats,
        isRead: isRead,
        createdAt: createdAt,
      );
}
