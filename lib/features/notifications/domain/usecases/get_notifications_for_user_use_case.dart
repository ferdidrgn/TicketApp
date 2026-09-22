import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

abstract class GetNotificationsForUserUseCase {
  Stream<List<AppNotification>> call(final String userId);
}

class GetNotificationsForUserUseCaseImpl
    implements GetNotificationsForUserUseCase {
  final NotificationRepository repository;

  GetNotificationsForUserUseCaseImpl(this.repository);

  @override
  Stream<List<AppNotification>> call(final String userId) =>
      repository.watchNotificationsForUser(userId);
}
