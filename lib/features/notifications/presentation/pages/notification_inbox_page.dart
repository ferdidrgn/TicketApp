import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

/// 🔔 BİLDİRİM GELEN KUTUSU
///
/// Kullanıcının bilet/rezervasyon bildirimlerini gösterir.
/// - En yeni en üstte
/// - Okunmamışlar görsel olarak vurgulanır
/// - Dokunma => okundu işaretlenir (silme / kaydırarak kapatma YOK — okundu
///   bilgisi kalıcı olarak tutulur, döküman asla silinmez)
/// - Etkinlik tarihi geçmiş bildirimler otomatik gizlenir (bkz.
///   visibleNotificationsForUserProvider)
class NotificationInboxPage extends ConsumerWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final notificationsAsync =
        ref.watch(visibleNotificationsForUserProvider(userId));

    return BasePageWrapper(
      showBackButton: true,
      title: 'Bildirimler',
      subtitle: 'Bilet ve etkinlik güncellemelerin',
      rightIcon: Icons.notifications_active_rounded,
      isLoading: notificationsAsync.isLoading && !notificationsAsync.hasValue,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.05),
      ),
      child: notificationsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (final err, final _) => _ErrorState(message: err.toString()),
        data: (final notifications) {
          if (notifications.isEmpty) return const _EmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (final _, final index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _markRead(ref, notification),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markRead(
      final WidgetRef ref, final AppNotification notification) async {
    if (notification.isRead) return;
    HapticFeedback.selectionClick();
    try {
      await ref
          .read(markNotificationReadUseCaseProvider)
          .call(notification.id)
          .getOrThrow();
    } catch (e) {
      debugPrint('Bildirim okundu olarak işaretlenemedi: $e');
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final unread = !notification.isRead;

    final dateInfo = notification.eventDate.isNotEmpty
        ? DateFormatter.parseFormattedDateTime(notification.eventDate)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: unread ? colors.primary.withOpacity(0.06) : colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: unread
                ? colors.primary.withOpacity(0.25)
                : colors.outlineVariant.withOpacity(0.3),
            width: unread ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(unread ? 0.10 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (unread ? colors.primary : colors.outline)
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                color: unread ? colors.primary : colors.outline,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight:
                                unread ? FontWeight.w900 : FontWeight.w600,
                            color: unread
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 8, top: 6),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  if (dateInfo != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 14, color: colors.outline),
                        const SizedBox(width: 6),
                        Text(
                          '${dateInfo['date']} • ${dateInfo['time']}',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.outline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 60, color: context.colors.outline),
            const SizedBox(height: 16),
            Text(
              "Henüz bildirimin yok",
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "Bilet aldığında burada göreceksin.",
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: context.colors.outline),
              const SizedBox(height: 16),
              Text('Bildirimler yüklenemedi: $message',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
}
