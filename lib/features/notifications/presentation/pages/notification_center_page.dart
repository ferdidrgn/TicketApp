import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      title: 'BİLDİRİMLER',
      subtitle: 'Kampanyalar, yeni oyunlar ve biletlerinle ilgili gelişmeler',
      showBackButton: true,
      rightIcon: Icons.notifications_rounded,
      isLoading: notificationsAsync.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        safeAreaTop: true,
      ),
      onRefresh: () => ref.invalidate(notificationsStreamProvider),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
          child: notificationsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (final err, final _) => _ErrorState(
                onRetry: () => ref.invalidate(notificationsStreamProvider)),
            data: (final notifications) => notifications.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (final _, final __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (final context, final index) => FadeInUp(
                      delay: Duration(milliseconds: 40 * index),
                      child:
                          _NotificationTile(notification: notifications[index]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final isUnread = !notification.isReadBy(userId);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _handleTap(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? BentoColors.indigo.withOpacity(0.10) : BentoColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? BentoColors.indigo.withOpacity(0.35)
                : BentoColors.microBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BentoColors.indigo.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(notification.type),
                  color: BentoColors.indigoLight, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFA1A1AA)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: BentoColors.indigo,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(final BuildContext context, final WidgetRef ref) {
    ref.read(notificationMutationProvider.notifier).markAsRead(notification.id);
    final route = notification.route;
    if (route != null && route.isNotEmpty) {
      context.go(route);
    }
  }

  IconData _iconFor(final String type) {
    switch (type) {
      case 'campaign':
        return Icons.local_offer_rounded;
      case 'show':
        return Icons.theater_comedy_rounded;
      case 'ticket':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _relativeTime(final DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BentoEmptyState(
            icon: Icons.notifications_off_rounded,
            title: 'Henüz bildirim yok',
            message: 'Kampanya ve bilet güncellemeleri burada görünecek.',
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BentoErrorState(
              message: 'Bildirimler yüklenemedi.', onRetry: onRetry),
        ),
      );
}
