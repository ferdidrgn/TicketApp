import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/playbill.dart';
import '../../../../../shared/widgets/stagecraft.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../show_team_credit.dart';
import 'show_detail_actions.dart';
import 'show_detail_data.dart';
import 'show_detail_layouts.dart';
import 'show_detail_skeleton.dart';

/// Android oyun detayı — program kapağı.
///
/// Afiş tam kapak (Hero + Ken Burns), ad fotoğrafın üstünde perde gibi
/// açılır. Altında yumuşak bilgi yüzeyi. TEK aksiyon: yapışkan "Bilet al".
/// Koçan yok; seanslar programın I. perdesinde.
class ShowDetailMobileLayout extends StatelessWidget {
  final ShowDetailViewArgs args;
  final ValueListenable<bool> scrolled;
  final bool contentReady;

  const ShowDetailMobileLayout({
    super.key,
    required this.args,
    required this.scrolled,
    this.contentReady = true,
  });

  static const double barHeight = 80;

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final colors = context.colors;
    final bool hasPoster = data.show.imageUrl.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double width = constraints.maxWidth;
        final double posterHeight =
            hasPoster ? (width * 1.15).clamp(320.0, 520.0) : safe.top + 72;
        final bool compact = width < 600;

        return Stack(
          children: [
            CustomScrollView(
              controller: args.controller,
              slivers: [
                SliverToBoxAdapter(
                  child: _Cover(
                    data: data,
                    height: posterHeight,
                    showImage: hasPoster,
                    controller: args.controller,
                    headline: args.headline,
                    details: args.details,
                    onSessions: args.onBuy,
                  ),
                ),
                if (contentReady)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: args.details,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: args.details,
                          curve: AppMotion.spring,
                        )),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, 0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: args.programme(compact: compact),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: ShowProgrammeSkeleton()),
                if (args.footer != null) ...[
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.section)),
                  SliverToBoxAdapter(child: args.footer),
                ] else
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.massive)),
                SliverToBoxAdapter(
                  child:
                      SizedBox(height: barHeight + safe.bottom + AppSpacing.lg),
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
                    AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.spring,
                  color: isScrolled
                      ? colors.surface.withValues(alpha: 0.94)
                      : Colors.transparent,
                  padding: EdgeInsets.fromLTRB(AppSpacing.md,
                      safe.top + AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    children: [
                      ShowBackButton(onImage: !isScrolled),
                      const Spacer(),
                      if (contentReady) ...[
                        ShowFavoriteButton(
                            showId: data.show.id, onImage: !isScrolled),
                        const SizedBox(width: AppSpacing.sm),
                        ShowShareButton(
                            show: data.show, onImage: !isScrolled),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (contentReady && args.chatBubble != null)
              Positioned(
                left: AppSpacing.xl,
                bottom: barHeight + safe.bottom + AppSpacing.lg,
                child: args.chatBubble!,
              ),
            if (contentReady)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: colors.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                          AppSpacing.md, AppSpacing.xl, AppSpacing.md),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: _BuyBar(args: args),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final ShowDetailData data;
  final double height;
  final bool showImage;
  final ScrollController controller;
  final Animation<double> headline;
  final Animation<double> details;
  final VoidCallback onSessions;

  const _Cover({
    required this.data,
    required this.height,
    required this.showImage,
    required this.controller,
    required this.headline,
    required this.details,
    required this.onSessions,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final show = data.show;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    final String duration = show.duration.trim();
    final String age = show.ageLimit.trim();
    final String category = show.category.trim();
    final ShowSession? next = data.nextSession;

    Widget image = OptimizedCachedImage(
      imageUrl: show.imageUrl,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
    image = KenBurns(enabled: showImage, child: image);
    image = TiyatrolHero(
      tag: resolveTiyatrolHeroTag(context, TiyatrolHeroTags.show(show.id)),
      child: image,
    );

    if (showImage && !reduce) {
      image = AnimatedBuilder(
        animation: controller,
        builder: (final context, final child) {
          final double offset =
              controller.hasClients ? controller.offset.clamp(0, height) : 0;
          return Transform.translate(
            offset: Offset(0, offset * 0.28),
            child: child,
          );
        },
        child: image,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              showImage
                  ? Semantics(
                      image: true,
                      label: '${show.name} afişi',
                      child: image,
                    )
                  : ColoredBox(color: colors.surfaceContainerHighest),
              const CinematicScrim(),
              Positioned(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.huge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlaybillCoverTitle(
                      title: show.name,
                      reveal: headline,
                      color: kPosterInk,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TitleInkMark(
                        color: colors.primary, reveal: details, width: 48),
                    const SizedBox(height: AppSpacing.md),
                    FadeTransition(
                      opacity: details,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!data.isExternal && next != null)
                            Semantics(
                              button: true,
                              label: 'En yakın seans, ${next.shortLabel}',
                              excludeSemantics: true,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSessions();
                                },
                                child: Text(
                                  next.shortLabel,
                                  style: GoogleFonts.playfairDisplay(
                                    color: kPosterInk,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0),
            child: FadeTransition(
              opacity: details,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowTeamCredit(teamId: show.teamId),
                  if (duration.isNotEmpty ||
                      age.isNotEmpty ||
                      category.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (duration.isNotEmpty) _CoverChip(label: duration),
                        if (age.isNotEmpty) _CoverChip(label: age),
                        if (category.isNotEmpty)
                          _CoverChip(
                            label: category,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              NavigationHandler.goToDiscoverWithCategory(
                                  context, category);
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _CoverChip({required this.label, this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget child = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSecondaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final BoxDecoration deco = BoxDecoration(
      color: cs.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    if (onTap == null) {
      return DecoratedBox(decoration: deco, child: child);
    }
    return Semantics(
      button: true,
      label: '$label türündeki oyunlar',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: DecoratedBox(decoration: deco, child: child),
        ),
      ),
    );
  }
}

class _BuyBar extends StatelessWidget {
  final ShowDetailViewArgs args;
  const _BuyBar({required this.args});

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    final colors = context.colors;
    final double? lowest = data.lowestPrice;

    final String? priceLabel =
        (!data.isExternal && lowest != null) ? formatTicketPrice(lowest) : null;
    final String? priceHint = priceLabel == null
        ? null
        : (data.sessions
                    .map((final s) => s.price)
                    .whereType<double>()
                    .toSet()
                    .length >
                1
            ? 'En uygun'
            : 'Fiyat');

    return Row(
      children: [
        if (priceLabel != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                priceHint!,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                priceLabel,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        Expanded(child: _PrimaryBuyButton(args: args)),
      ],
    );
  }
}

class _PrimaryBuyButton extends StatelessWidget {
  final ShowDetailViewArgs args;
  const _PrimaryBuyButton({required this.args});

  @override
  Widget build(final BuildContext context) {
    final data = args.data;
    final ButtonStyle style = FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );

    if (data.isExternal) {
      return Semantics(
        button: true,
        label: 'Başka platformda bilet al',
        excludeSemantics: true,
        child: FilledButton(
          onPressed: args.externalBusy
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  args.onExternal();
                },
          style: style,
          child: Text(args.externalBusy ? 'Açılıyor…' : 'Bilet al'),
        ),
      );
    }

    if (data.sessions.isEmpty) {
      return Semantics(
        label: 'Şu an satışta seans yok',
        child: Text(
          'Şu an satışta seans yok',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Bilet al',
      excludeSemantics: true,
      child: FilledButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          args.onBuy();
        },
        style: style,
        child: const Text('Bilet al'),
      ),
    );
  }
}
