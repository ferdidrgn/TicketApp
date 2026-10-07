import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import 'show_detail_actions.dart';
import 'show_detail_data.dart';
import 'show_programme.dart';
import 'show_ticket.dart';
import 'sticky_aside.dart';

/// Sayfaların (web + mobil) düzenlere verdiği her şey. Sayfa durumu
/// (kaydırma, animasyonlar, gezinme) sayfada kalır; düzenler sadece
/// kompozisyonu kurar.
class ShowDetailViewArgs {
  final ShowDetailData data;
  final ScrollController controller;
  final GlobalKey sessionsKey;

  /// Giriş koreografisi: bilet gelir → başlık perde gibi açılır → alanlar.
  final Animation<double> ticketIn;
  final Animation<double> headline;
  final Animation<double> details;

  /// Harici bilet sayfasına gidilirken biletin koçanı yırtılır.
  final Animation<double> tear;

  final VoidCallback onBuy;
  final VoidCallback onExternal;
  final bool externalBusy;
  final void Function(ShowSession session) onSelectSession;

  /// Web'de sayfa sonu footer'ı; mobilde null.
  final Widget? footer;

  /// Gösteriye özel SSS sohbet balonu (konumunu düzen belirler).
  final Widget? chatBubble;

  const ShowDetailViewArgs({
    required this.data,
    required this.controller,
    required this.sessionsKey,
    required this.ticketIn,
    required this.headline,
    required this.details,
    required this.tear,
    required this.onBuy,
    required this.onExternal,
    required this.externalBusy,
    required this.onSelectSession,
    this.footer,
    this.chatBubble,
  });

  Widget primaryStamp({final bool compact = false}) => ShowPrimaryStamp(
        data: data,
        onBuy: onBuy,
        onExternal: onExternal,
        busy: externalBusy,
        compact: compact,
      );

  Widget programme({required final bool compact}) => ShowProgramme(
        data: data,
        sessionsKey: sessionsKey,
        onSelectSession: onSelectSession,
        compact: compact,
      );
}

/// Bilet gişe camının altından uzatılıyormuş gibi giriş (login ile aynı).
class _TicketEntrance extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _TicketEntrance({required this.animation, required this.child});

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (final context, final child) => Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 40),
            child: child,
          ),
        ),
        child: child,
      );
}

class _ActionsRow extends StatelessWidget {
  final ShowDetailData data;
  final bool onImage;
  const _ActionsRow({required this.data, this.onImage = false});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          ShowBackButton(onImage: onImage),
          const Spacer(),
          ShowFavoriteButton(showId: data.show.id, onImage: onImage),
          const SizedBox(width: AppSpacing.sm),
          ShowShareButton(show: data.show, onImage: onImage),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════
// MOBİL / DAR WEB: afiş bandı + üstüne binen dikey bilet + program +
// yapışkan alt "bilet çubuğu".
// ═════════════════════════════════════════════════════════════════════════

class ShowDetailStackedLayout extends StatelessWidget {
  final ShowDetailViewArgs args;

  /// Afiş bandı geçildi mi (üst ikonların zemini buna göre değişir).
  final ValueListenable<bool> scrolled;

  /// Afiş için `Hero` (mobil uygulama geçişi).
  final bool heroPoster;

  const ShowDetailStackedLayout({
    super.key,
    required this.args,
    required this.scrolled,
    this.heroPoster = false,
  });

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double width = constraints.maxWidth;
        final bool hasPoster = data.show.imageUrl.trim().isNotEmpty;
        const double overlap = 88;
        final double posterHeight =
            hasPoster ? (width * 1.05).clamp(320.0, 480.0) : 0.0;
        final double ticketTop =
            hasPoster ? posterHeight - overlap : safe.top + 72;
        final double bandHeight = hasPoster ? posterHeight : ticketTop + 48;
        final bool compact = width < 600;

        final Widget ticket = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _TicketEntrance(
              animation: args.ticketIn,
              child: AdmitTicket(
                direction: Axis.vertical,
                tear: args.tear,
                body: ShowTicketBody(
                  data: data,
                  layout: ShowTicketLayout.stacked,
                  headlineReveal: args.headline,
                  detailsFade: args.details,
                ),
                stub: ShowTicketStub(
                    data: data, layout: ShowTicketLayout.stacked),
              ),
            ),
          ),
        );

        final Widget head = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bandHeight,
              child: _PosterBand(
                data: data,
                hero: heroPoster,
                showImage: hasPoster,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, ticketTop, AppSpacing.lg, AppSpacing.lg),
              child: ticket,
            ),
          ],
        );

        return Stack(
          children: [
            CustomScrollView(
              controller: args.controller,
              slivers: [
                SliverToBoxAdapter(child: head),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.massive, AppSpacing.xl, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: args.programme(compact: compact),
                      ),
                    ),
                  ),
                ),
                if (args.footer != null) ...[
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.section)),
                  SliverToBoxAdapter(child: args.footer),
                ] else
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.massive)),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: ShowBottomBar.height + safe.bottom + AppSpacing.lg),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: scrolled,
                builder: (final context, final isScrolled, final _) =>
                    Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md,
                      safe.top + AppSpacing.sm, AppSpacing.md, 0),
                  child: _ActionsRow(
                      data: data, onImage: hasPoster && !isScrolled),
                ),
              ),
            ),
            if (args.chatBubble != null)
              Positioned(
                left: AppSpacing.xl,
                bottom: ShowBottomBar.height + safe.bottom + AppSpacing.lg,
                child: args.chatBubble!,
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShowBottomBar(args: args),
            ),
          ],
        );
      },
    );
  }
}

/// Afiş bandı: gerçek afiş, üstte ikonlar için hafif karartma, altta
/// sayfa zeminine yumuşak geçiş.
class _PosterBand extends StatelessWidget {
  final ShowDetailData data;
  final bool hero;
  final bool showImage;

  const _PosterBand(
      {required this.data, required this.hero, required this.showImage});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    Widget image = OptimizedCachedImage(
      imageUrl: data.show.imageUrl,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
    if (hero) image = Hero(tag: 'show_${data.show.id}', child: image);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.surfaceContainerHighest),
        if (showImage)
          Semantics(
            image: true,
            label: '${data.show.name} afişi',
            child: image,
          ),
        if (showImage)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x73000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 160,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.surface.withOpacity(0), colors.surface],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobilin yapışkan alt çubuğu — elde tutulan bir koçan: fildişi kağıt,
/// üst kenarı delikli. Solda en uygun fiyat (ya da seans sayısı), sağda
/// TEK birincil aksiyon. Başparmak bölgesinde, 56dp buton.
class ShowBottomBar extends StatelessWidget {
  final ShowDetailViewArgs args;
  const ShowBottomBar({super.key, required this.args});

  /// Güvenli alan HARİÇ çubuk yüksekliği.
  static const double height = 84;

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    final double? lowest = data.lowestPrice;

    Widget? info;
    if (!data.isExternal && data.sessions.isNotEmpty) {
      info = lowest != null
          ? TicketField(
              label: data.sessions
                          .map((final s) => s.price)
                          .whereType<double>()
                          .toSet()
                          .length >
                      1
                  ? 'EN UYGUN'
                  : 'FİYAT',
              value: formatTicketPrice(lowest),
            )
          : TicketField(label: 'SATIŞTA', value: '${data.sessions.length} seans');
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TicketPiece(
          perforated: TicketEdge.top,
          notch: 12,
          corner: 0,
          shadows: AppShadows.level3(TicketInk.ink),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 14, AppSpacing.xl, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Row(
                    children: [
                      if (info != null) ...[
                        Flexible(flex: 2, child: info),
                        const SizedBox(width: AppSpacing.lg),
                      ],
                      Expanded(flex: 3, child: args.primaryStamp()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: -1,
          left: 0,
          right: 0,
          height: 2,
          child: TicketPerforation(),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// MASAÜSTÜ (≥1024): iki bölmeli kalıcı ayrım — solda yapışkan bilet +
// birincil aksiyon, sağda kayan program. Footer tam genişlikte.
// ═════════════════════════════════════════════════════════════════════════

class ShowDetailTwoPaneLayout extends StatefulWidget {
  final ShowDetailViewArgs args;
  const ShowDetailTwoPaneLayout({super.key, required this.args});

  @override
  State<ShowDetailTwoPaneLayout> createState() =>
      _ShowDetailTwoPaneLayoutState();
}

class _ShowDetailTwoPaneLayoutState extends State<ShowDetailTwoPaneLayout> {
  final GlobalKey _rowKey = GlobalKey();
  static const double _top = AppSpacing.huge;

  @override
  Widget build(final BuildContext context) {
    final args = widget.args;
    final data = args.data;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double width = constraints.maxWidth;
        final bool roomy = width >= 1280;
        final double sidePadding = roomy ? AppSpacing.massive : AppSpacing.xxxl;
        final double asideWidth = roomy ? 420.0 : 380.0;
        final double gap = roomy ? 72.0 : AppSpacing.massive;
        final double posterHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight * 0.3).clamp(180.0, 300.0)
            : 280.0;

        final Widget aside = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionsRow(data: data),
            const SizedBox(height: AppSpacing.lg),
            _TicketEntrance(
              animation: args.ticketIn,
              child: AdmitTicket(
                direction: Axis.vertical,
                tear: args.tear,
                body: ShowTicketBody(
                  data: data,
                  layout: ShowTicketLayout.aside,
                  headlineReveal: args.headline,
                  detailsFade: args.details,
                  posterHeight: posterHeight,
                ),
                stub: ShowTicketStub(
                  data: data,
                  layout: ShowTicketLayout.aside,
                  action: args.primaryStamp(),
                ),
              ),
            ),
          ],
        );

        return Stack(
          children: [
            CustomScrollView(
              controller: args.controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        sidePadding, _top, sidePadding, AppSpacing.section),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Row(
                          key: _rowKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: asideWidth,
                              child: StickyAside(
                                controller: args.controller,
                                rowKey: _rowKey,
                                contentTop: _top,
                                child: aside,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 720),
                                  child: Padding(
                                    // İkon satırının altından, biletle aynı
                                    // hizadan başlar.
                                    padding:
                                        const EdgeInsets.only(top: 64),
                                    child: args.programme(compact: false),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (args.footer != null)
                  SliverToBoxAdapter(child: args.footer),
              ],
            ),
            if (args.chatBubble != null)
              Positioned(
                right: AppSpacing.xxl,
                bottom: AppSpacing.xxl,
                child: args.chatBubble!,
              ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// WEB TABLET (768–1023): yatay bilet (afiş + ad + alanlar | koçanda
// birincil aksiyon), altında ortalanmış okuma sütununda program.
// ═════════════════════════════════════════════════════════════════════════

class ShowDetailBannerLayout extends StatelessWidget {
  final ShowDetailViewArgs args;
  const ShowDetailBannerLayout({super.key, required this.args});

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    return Stack(
      children: [
        CustomScrollView(
          controller: args.controller,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ActionsRow(data: data),
                        const SizedBox(height: AppSpacing.lg),
                        _TicketEntrance(
                          animation: args.ticketIn,
                          child: AdmitTicket(
                            direction: Axis.horizontal,
                            tear: args.tear,
                            stubExtent: 280,
                            body: ShowTicketBody(
                              data: data,
                              layout: ShowTicketLayout.banner,
                              headlineReveal: args.headline,
                              detailsFade: args.details,
                            ),
                            stub: ShowTicketStub(
                              data: data,
                              layout: ShowTicketLayout.banner,
                              action: args.primaryStamp(compact: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                    AppSpacing.section, AppSpacing.xxl, AppSpacing.section),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: args.programme(compact: false),
                  ),
                ),
              ),
            ),
            if (args.footer != null) SliverToBoxAdapter(child: args.footer),
          ],
        ),
        if (args.chatBubble != null)
          Positioned(
            right: AppSpacing.xxl,
            bottom: AppSpacing.xxl,
            child: args.chatBubble!,
          ),
      ],
    );
  }
}

/// Seçili seans ya da hata için ortak, sade bir hata görünümü (mobil).
class ShowDetailError extends StatelessWidget {
  final VoidCallback onRetry;
  const ShowDetailError({super.key, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.theater_comedy_outlined,
                  size: 48, color: colors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Oyun bilgileri yüklenemedi',
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bağlantını kontrol edip tekrar dene.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
