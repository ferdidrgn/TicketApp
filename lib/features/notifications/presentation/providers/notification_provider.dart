import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_remote_data_source_and_impl.dart';
import '../../domain/entities/app_notification.dart';

/// 🔥 Elle (codegen'siz) tanımlanmış provider'lar.

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);
  return NotificationRemoteDataSourceImpl(firestore: firestore);
});

/// Kullanıcının görebileceği bildirimleri canlı olarak yayınlar
/// (genel yayınlar + kendisine özel bildirimler), en yeniden en eskiye.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((final ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return dataSource
      .streamNotifications(userId)
      .map((final models) => models.map((final m) => m.toEntity()).toList());
});

/// Okunmamış bildirim sayısı — Ayarlar/Profil sayfalarındaki rozet için.
final unreadNotificationCountProvider = Provider.autoDispose<int>((final ref) {
  final userId = ref.watch(currentUserIdProvider);
  final notifications = ref.watch(notificationsStreamProvider).value ?? const [];
  if (userId == null) return 0;
  return notifications.where((final n) => !n.isReadBy(userId)).length;
});

class NotificationMutation extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAsRead(final String notificationId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(notificationRemoteDataSourceProvider)
        .markAsRead(notificationId, userId);
  }
}

final notificationMutationProvider =
    NotifierProvider<NotificationMutation, void>(NotificationMutation.new);
