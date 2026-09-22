import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/date_formatter.dart';
import '../../data/repositories/notification_repository_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/create_notification_use_case.dart';
import '../../domain/usecases/get_notifications_for_user_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS (Dependency Injection)
// NOT: Bu feature, projedeki diğer bazı feature'ların aksine riverpod_annotation
// (build_runner / .g.dart) KULLANMIYOR — bilinçli bir tercih: bu ortamda Flutter/
// build_runner çalıştırılamıyor, elle .g.dart üretmek riskli olurdu. Düz
// (generator'sız) Provider/StreamProvider kullanımı da tamamen geçerli ve
// aynı davranışı sağlıyor.
// ==============================================================================

final createNotificationUseCaseProvider =
    Provider<CreateNotificationUseCase>((final ref) =>
        CreateNotificationUseCaseImpl(ref.watch(notificationRepositoryProvider)));

final getNotificationsForUserUseCaseProvider =
    Provider<GetNotificationsForUserUseCase>((final ref) =>
        GetNotificationsForUserUseCaseImpl(
            ref.watch(notificationRepositoryProvider)));

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((final ref) =>
        MarkNotificationReadUseCaseImpl(ref.watch(notificationRepositoryProvider)));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

/// 🔔 Kullanıcının TÜM bildirimlerini (geçmiş dahil) canlı akış olarak döner.
/// Ham veri — geçmiş etkinlik filtresi ve sıralama için
/// [visibleNotificationsForUserProvider] kullanılmalı.
final notificationsForUserProvider =
    StreamProvider.family<List<AppNotification>, String>((final ref, final userId) {
  if (userId.isEmpty) return Stream.value(const []);
  return ref.watch(getNotificationsForUserUseCaseProvider).call(userId);
});

/// 🎯 Gösterime hazır bildirim listesi:
/// - Etkinlik tarihi geçmiş olanlar filtrelenir (SİLİNMEZ, sadece gizlenir —
///   Show feature'ındaki "aktiflik canlı tarihten hesaplanır, statik bir bayrak
///   tutulmaz" felsefesiyle aynı yaklaşım, bkz. show_provider.dart).
/// - En yeni bildirim en üstte olacak şekilde sıralanır.
final visibleNotificationsForUserProvider =
    Provider.family<AsyncValue<List<AppNotification>>, String>(
        (final ref, final userId) {
  final async = ref.watch(notificationsForUserProvider(userId));

  return async.whenData((final notifications) {
    final now = DateTime.now();

    final visible = notifications.where((final n) {
      if (n.eventDate.isEmpty) return true;
      final eventDateTime = DateFormatter.parseDateString(n.eventDate);
      // Tarih parse edilemiyorsa güvenli taraf: gizleme.
      if (eventDateTime == null) return true;
      return !eventDateTime.isBefore(now);
    }).toList();

    visible.sort((final a, final b) => b.createdAt.compareTo(a.createdAt));
    return visible;
  });
});

/// 🔴 Okunmamış (ve hâlâ görünür/gelecek) bildirim sayısı — bildirim zili
/// rozetinde (badge) kullanılır.
final unreadNotificationCountProvider =
    Provider.family<int, String>((final ref, final userId) {
  final async = ref.watch(visibleNotificationsForUserProvider(userId));
  return async.maybeWhen(
    data: (final list) => list.where((final n) => !n.isRead).length,
    orElse: () => 0,
  );
});
