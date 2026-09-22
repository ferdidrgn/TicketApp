import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

abstract class MarkNotificationReadUseCase {
  Future<Either<Failure, bool>> call(final String notificationId);
}

class MarkNotificationReadUseCaseImpl implements MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String notificationId) =>
      repository.markNotificationRead(notificationId);
}
