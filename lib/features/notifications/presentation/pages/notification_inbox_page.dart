import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

/// BİLDİRİMLER — gişeden gelen kısa mesajlar.
///
/// Sakin satırlar: bir bildirim bilet değildir; ama bir seansa bağlıysa
/// (gerçek `eventDate`) solunda o seansın küçük TARİH koçanı durur.
/// Okunmamışlar "Yeni" altında kalın başlık + vurgu noktasıyla, okunanlar
/// "Önceki" altında soluk. Dokunma → okundu + varsa gerçek `showId` ile
/// oyuna gider (silme yok). Etkinlik tarihi geçmiş bildirimler
/// provider'da gizlenir (bkz. `visibleNotificationsForUserProvider`).
///
/// - Mobil (<768): `BasePageWrapper` + tam genişlik liste.
/// - Tablet (768–1023): aynı çatı, liste ~680px okuma sütununda ortalı.
/// - Masaüstü (≥1024): kendi `Scaffold`'u (rota bir kabukta değil), geri
///   butonlu perde açılışlı başlık + gerçek okunmamış sayısı, 720px sütun.
class NotificationInboxPage extends ConsumerWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final notificationsAsync =
        ref.watch(visibleNotificationsForUserProvider(userId));
    final List<AppNotification>? list = notificationsAsync.value;
    final int unread =
        list == null ? 0 : list.where((final n) => !n.isRead).length;

    void retry() => ref.invalidate(notificationsForUserProvider(userId));
    void openNotice(final AppNotification n) {
      _markRead(ref, n);
      if (n.showId.trim().isEmpty) return;
      NavigationHandler.goToShow(context, n.showId, n.showName);
    }

    if (context.isDesktop) {
      final cs = context.colors;
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                        AppSpacing.massive, AppSpacing.xxl, AppSpacing.xxxl),
                    sliver: SliverToBoxAdapter(
                      child: PreferencePageHeading(
                        title: 'Bildirimler',
                        lede: _summary(list, unread),
                        onBack: () => NavigationHandler.smartGoBack(context),
                      ),
                    ),
                  ),
                  ..._contentSlivers(
                    context,
                    notificationsAsync,
                    gutter: AppSpacing.xxl,
                    onRetry: retry,
                    onTap: openNotice,
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.section)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bool tablet = context.isTablet;
    final double gutter = tablet ? AppSpacing.xxxl : AppSpacing.lg;
    return BasePageWrapper(
      showBackButton: true,
      title: 'Bildirimler',
      subtitle: _summary(list, unread),
      // İskeleti sayfa kendisi çiziyor; `true` içeriği gizlerdi.
      isLoading: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: tablet ? 680 : double.infinity),
          child: RefreshIndicator(
            onRefresh: () async => retry(),
            color: context.colors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm)),
                ..._contentSlivers(
                  context,
                  notificationsAsync,
                  gutter: gutter,
                  onRetry: retry,
                  onTap: openNotice,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _summary(
      final List<AppNotification>? list, final int unread) {
    if (list == null || list.isEmpty) return null;
    if (unread == 0) return 'Hepsini okudun.';
    return unread == 1 ? '1 okunmamış bildirim' : '$unread okunmamış bildirim';
  }

  List<Widget> _contentSlivers(
    final BuildContext context,
    final AsyncValue<List<AppNotification>> async, {
    required final double gutter,
    required final VoidCallback onRetry,
    required final void Function(AppNotification) onTap,
  }) {
    Widget boxed(final Widget child) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(child: child),
        );

    if (async.isLoading && !async.hasValue) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList.separated(
            itemCount: 4,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (final _, final __) => const ExcludeSemantics(
              child: ShimmerLoading(
                width: double.infinity,
                height: 92,
                borderRadius: AppRadius.sm,
              ),
            ),
          ),
        ),
      ];
    }

    if (async.hasError && !async.hasValue) {
      return [
        boxed(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Align(
            alignment: Alignment.topLeft,
            child: TicketNotice(
              label: 'BAĞLANTI',
              title: 'Bildirimler yüklenemedi',
              message: 'Gelen kutuna şu an ulaşamadık; biletlerin '
                  'etkilenmedi. İnternet bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              actionIcon: Icons.refresh_rounded,
              onAction: onRetry,
            ),
          ),
        )),
      ];
    }

    final List<AppNotification> all = async.value ?? const [];
    if (all.isEmpty) {
      return [
        boxed(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Align(
            alignment: Alignment.topLeft,
            child: TicketNotice(
              label: 'GİŞE',
              title: 'Henüz bildirimin yok',
              message: 'Bir bilet aldığında onayı ve seans bilgisi burada '
                  'görünür.',
              actionLabel: 'Oyunlara göz at',
              actionIcon: Icons.explore_outlined,
              onAction: () => NavigationHandler.goToDiscover(context),
            ),
          ),
        )),
      ];
    }

    final List<AppNotification> fresh =
        all.where((final n) => !n.isRead).toList();
    final List<AppNotification> seen =
        all.where((final n) => n.isRead).toList();
    final bool grouped = fresh.isNotEmpty && seen.isNotEmpty;

    Widget group(final String? title, final List<AppNotification> items,
            {final bool first = false}) =>
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              gutter, first ? 0 : AppSpacing.xxl, gutter, 0),
          sliver: SliverList.list(
            children: [
              if (title != null) _GroupTitle(title),
              _NotificationGroup(items: items, onTap: onTap),
            ],
          ),
        );

    return [
      if (fresh.isNotEmpty) group(grouped ? 'Yeni' : null, fresh, first: true),
      if (seen.isNotEmpty)
        group(grouped ? 'Önceki' : null, seen, first: fresh.isEmpty),
    ];
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

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: GoogleFonts.playfairDisplay(
              color: context.colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

/// Satırlar tek bir çerçeveli yüzeyde, aralarında ince çizgi — her
/// bildirim ayrı gölgeli kart değil.
class _NotificationGroup extends StatelessWidget {
  final List<AppNotification> items;
  final void Function(AppNotification) onTap;

  const _NotificationGroup({required this.items, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            _NotificationRow(
              key: ValueKey('notification-${items[i].id}'),
              notification: items[i],
              onTap: () => onTap(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationRow(
      {super.key, required this.notification, required this.onTap});

  /// "az önce", "3 sa önce", "dün", "12.10.2026".
  static String? _received(final String iso) {
    final DateTime? at = DateTime.tryParse(iso);
    if (at == null) return null;
    final Duration diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return ticketDate(at);
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final bool unread = !notification.isRead;
    final DateTime? session = notification.eventDate.isEmpty
        ? null
        : DateFormatter.parseDateString(notification.eventDate);
    final String? received = _received(notification.createdAt);
    final List<String> seats = notification.seats
        .map((final s) => s.trim())
        .where((final s) => s.isNotEmpty)
        .toList();

    final List<String> meta = [
      if (session != null) 'Seans ${ticketDate(session)}, ${ticketTime(session)}',
      if (seats.isNotEmpty)
        seats.length == 1 ? 'Koltuk ${seats.first}' : 'Koltuklar ${seats.join(', ')}',
    ];

    return Semantics(
      button: unread,
      label: [
        if (unread) 'Okunmamış',
        notification.title,
        notification.body,
        ...meta,
        if (received != null) received,
      ].join('. '),
      excludeSemantics: true,
      child: Material(
        color: unread
            ? Color.alphaBlend(cs.primary.withOpacity(0.06), cs.surface)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor:
              unread ? SystemMouseCursors.click : SystemMouseCursors.basic,
          focusColor: cs.primary.withOpacity(0.14),
          hoverColor: cs.onSurface.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session != null)
                  _SessionStub(date: session, dimmed: !unread)
                else
                  _Glyph(unread: unread),
                const SizedBox(width: AppSpacing.lg),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (received != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              received,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (unread) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: SizedBox(
                                width: 8,
                                height: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notification.body.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          notification.body.trim(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ],
                      for (final line in meta) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(unread ? 0.8 : 0.6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seansa bağlı bildirimde küçük kağıt koçan: gün adı, gün, ay.
class _SessionStub extends StatelessWidget {
  final DateTime date;
  final bool dimmed;

  const _SessionStub({required this.date, required this.dimmed});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: dimmed ? 0.7 : 1,
          duration: AppMotion.fast,
          child: SizedBox(
            width: 52,
            height: 64,
            child: TicketPiece(
              perforated: TicketEdge.right,
              notch: 6,
              corner: AppRadius.xs,
              shadows: AppShadows.level1(TicketInk.ink),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ticketWeekdayShort(date),
                      style: TicketInk.label().copyWith(
                          fontSize: 8.5, letterSpacing: 1.2)),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.playfairDisplay(
                      color: TicketInk.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    ticketMonthShort(date),
                    style: TicketInk.label(color: TicketInk.accentOf(context))
                        .copyWith(fontSize: 9, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Seansı olmayan bildirim: sade, temaya bağlı ikon.
class _Glyph extends StatelessWidget {
  final bool unread;
  const _Glyph({required this.unread});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 52,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: unread ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 24,
            color: unread ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
