import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../show_team_credit.dart';
import 'show_detail_actions.dart';
import 'show_detail_data.dart';
import 'show_detail_layouts.dart';
import 'show_detail_skeleton.dart';

/// Android oyun detayı — listing dili (foto + orblar + cam galeri + Bilet al).
///
/// Ken Burns / wipe / sinematik scrim yok. TEK birincil aksiyon: Bilet al.
class ShowDetailMobileLayout extends StatefulWidget {
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
  State<ShowDetailMobileLayout> createState() => _ShowDetailMobileLayoutState();
}

class _ShowDetailMobileLayoutState extends State<ShowDetailMobileLayout> {
  int _photoIndex = 0;

  List<String> _gallery(final ShowDetailData data) {
    final List<String> urls = <String>[];
    final String poster = data.show.imageUrl.trim();
    if (poster.isNotEmpty) urls.add(poster);
    for (final String id in data.show.photosShowId) {
      final String u = id.trim();
      if (u.isNotEmpty && u.startsWith('http') && !urls.contains(u)) {
        urls.add(u);
      }
    }
    return urls;
  }

  @override
  Widget build(final BuildContext context) {
    final ShowDetailViewArgs args = widget.args;
    final ShowDetailData data = args.data;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final ColorScheme colors = context.colors;
    final List<String> gallery = _gallery(data);
    final bool hasPoster = gallery.isNotEmpty;
    final String coverUrl =
        hasPoster ? gallery[_photoIndex.clamp(0, gallery.length - 1)] : '';

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double width = constraints.maxWidth;
        final bool compact = width < 600;
        final String duration = data.show.duration.trim();
        final String age = data.show.ageLimit.trim();
        final String category = data.show.category.trim();
        final ShowSession? next = data.nextSession;
        final String venue = (next?.stage?.name ??
                (data.venues.isNotEmpty ? data.venues.first.name : ''))
            .trim();
        final String durationDigits = duration.replaceAll(RegExp(r'[^0-9]'), '');
        final String durationValue =
            durationDigits.isEmpty ? (duration.isEmpty ? '—' : duration) : durationDigits;
        final String timeValue = next?.when == null
            ? '—'
            : '${next!.when!.hour.toString().padLeft(2, '0')}:${next.when!.minute.toString().padLeft(2, '0')}';
        final String ageValue = age.isEmpty ? '—' : age;
        final String? priceLabel = (!data.isExternal && data.lowestPrice != null)
            ? formatTicketPrice(data.lowestPrice!)
            : null;

        return Stack(
          children: [
            CustomScrollView(
              controller: args.controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      safe.top + 64,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TiyatrolHero(
                              tag: resolveTiyatrolHeroTag(
                                context,
                                TiyatrolHeroTags.show(data.show.id),
                              ),
                              child: ListingPhotoFrame(
                                imageUrl: coverUrl,
                                overlay: venue.isEmpty ? null : venue,
                                height: (width * 0.72).clamp(220.0, 340.0),
                              ),
                            ),
                            if (gallery.length > 1) ...[
                              const SizedBox(height: AppSpacing.lg),
                              ListingGlassBar(
                                left: 'Önceki',
                                right: 'Sonraki',
                                onLeft: () => setState(() {
                                  _photoIndex =
                                      (_photoIndex - 1 + gallery.length) %
                                          gallery.length;
                                }),
                                onRight: () => setState(() {
                                  _photoIndex =
                                      (_photoIndex + 1) % gallery.length;
                                }),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            ListingLabel(
                              next == null ? 'Oyun' : 'Seans',
                            ),
                            Text(
                              data.show.name,
                              style: listingUi(
                                color: colors.onSurface,
                                size: 30,
                                weight: FontWeight.w800,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              priceLabel ??
                                  (next?.shortLabel ??
                                      (data.isExternal
                                          ? 'Başka platformda'
                                          : 'Programda')),
                              style: listingUi(
                                color: colors.onSurface,
                                size: 20,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              children: [
                                ListingMetricOrb(
                                  value: durationValue,
                                  unit: 'dk',
                                  emphasized: true,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                ListingMetricOrb(
                                  value: timeValue,
                                  unit: 'saat',
                                ),
                                const SizedBox(width: AppSpacing.md),
                                ListingMetricOrb(
                                  value: ageValue,
                                  unit: 'yaş',
                                ),
                              ],
                            ),
                            if (next != null || priceLabel != null) ...[
                              const SizedBox(height: AppSpacing.xl),
                              ListingOverlapCard(
                                title: data.isExternal
                                    ? 'Başka platformda bilet'
                                    : 'Bilet al',
                                subtitle: next?.shortLabel,
                                badge: priceLabel,
                                slots: [
                                  if (category.isNotEmpty)
                                    ListingChip(
                                      label: category,
                                      selected: false,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        NavigationHandler
                                            .goToDiscoverWithCategory(
                                                context, category);
                                      },
                                    ),
                                ],
                                onTap: data.isExternal
                                    ? args.onExternal
                                    : (data.sessions.isEmpty
                                        ? null
                                        : args.onBuy),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            ShowTeamCredit(teamId: data.show.teamId),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.contentReady)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: args.programme(compact: compact),
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
                  child: SizedBox(
                      height: ShowDetailMobileLayout.barHeight +
                          safe.bottom +
                          AppSpacing.lg),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.scrolled,
                builder: (final context, final isScrolled, final _) =>
                    AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.spring,
                  color: isScrolled
                      ? colors.surface.withValues(alpha: 0.94)
                      : colors.surface.withValues(alpha: 0.0),
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      safe.top + AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm),
                  child: Row(
                    children: [
                      ShowBackButton(onImage: false),
                      const Spacer(),
                      if (widget.contentReady) ...[
                        ShowFavoriteButton(
                            showId: data.show.id, onImage: false),
                        const SizedBox(width: AppSpacing.sm),
                        ShowShareButton(show: data.show, onImage: false),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (widget.contentReady && args.chatBubble != null)
              Positioned(
                left: AppSpacing.xl,
                bottom: ShowDetailMobileLayout.barHeight +
                    safe.bottom +
                    AppSpacing.lg,
                child: args.chatBubble!,
              ),
            if (widget.contentReady)
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: safe.bottom + AppSpacing.md,
                child: ListingFloatBar(
                  children: [
                    Expanded(
                      child: _BuyBar(args: args),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BuyBar extends StatelessWidget {
  final ShowDetailViewArgs args;
  const _BuyBar({required this.args});

  @override
  Widget build(final BuildContext context) {
    final ShowDetailData data = args.data;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double? lowest = data.lowestPrice;
    final String? priceLabel =
        (!data.isExternal && lowest != null) ? formatTicketPrice(lowest) : null;

    final ButtonStyle pill = FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );

    if (data.isExternal) {
      return FilledButton(
        onPressed: args.externalBusy
            ? null
            : () {
                HapticFeedback.mediumImpact();
                args.onExternal();
              },
        style: pill,
        child: Text(
          args.externalBusy ? 'Açılıyor…' : 'Bilet al',
          style: listingUi(
            color: colors.onPrimary,
            size: 15,
            weight: FontWeight.w800,
          ),
        ),
      );
    }
    if (data.sessions.isEmpty) {
      return Text(
        'Şu an satışta seans yok',
        textAlign: TextAlign.center,
        style: listingUi(
          color: colors.surface.withValues(alpha: 0.8),
          size: 14,
          weight: FontWeight.w700,
        ),
      );
    }
    return Row(
      children: [
        if (priceLabel != null) ...[
          Text(
            priceLabel,
            style: listingUi(
              color: colors.surface,
              size: 16,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              args.onBuy();
            },
            style: pill,
            child: Text(
              'Bilet al',
              style: listingUi(
                color: colors.onPrimary,
                size: 15,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
