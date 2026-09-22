import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source_provider.dart';
import 'notification_repository_impl.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((final ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});
