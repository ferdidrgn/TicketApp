import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

abstract class CreateNotificationUseCase {
  Future<Either<Failure, bool>> call(final AppNotification notification);
}

class CreateNotificationUseCaseImpl implements CreateNotificationUseCase {
  final NotificationRepository repository;

  CreateNotificationUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final AppNotification notification) =>
      repository.createNotification(notification);
}
