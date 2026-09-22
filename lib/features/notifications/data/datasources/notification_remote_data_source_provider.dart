import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_provider.dart';
import 'notification_remote_data_source_and_impl.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);
  return NotificationRemoteDataSourceImpl(firestore: firestore);
});
