import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../show_team_credit.dart';
import 'show_detail_actions.dart';
import 'show_detail_data.dart';
import 'show_detail_layouts.dart';

/// Android oyun detayı — Keşfet dili.
///
/// Afiş kahraman (Hero); ad/sanat afişte. Altında yumuşak Material yüzey
/// (süre / yaş / tür, en yakın seans). TEK birincil aksiyon: yapışkan
/// "Bilet al". Koçan, damga ve bilet-üstüne-binen kimlik yok. Seans
/// listesi satın alma adımı olduğu için programdaki koçanlar durur.
class ShowDetailMobileLayout extends StatelessWidget {
  final ShowDetailViewArgs args;
  final ValueListenable<bool> scrolled;

  const ShowDetailMobileLayout({
    super.key,
    required this.args,
    required this.scrolled,
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
            hasPoster ? (width * 1.15).clamp(300.0, 460.0) : safe.top + 72;
        final bool compact = width < 600;

        return Stack(
          children: [
            CustomScrollView(
              controller: args.controller,
              slivers: [
                SliverToBoxAdapter(
                  child: _PosterHero(
                    data: data,
                    height: posterHeight,
                    showImage: hasPoster,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: _ShowFactsCard(
                          data: data,
                          headline: args.headline,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.huge, AppSpacing.xl, 0),
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
                      height: barHeight + safe.bottom + AppSpacing.lg),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: scrolled,
                builder: (final context, final isScrolled, final _) => Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md,
                      safe.top + AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      ShowBackButton(onImage: hasPoster && !isScrolled),
                      const Spacer(),
                      ShowFavoriteButton(
                          showId: data.show.id,
                          onImage: hasPoster && !isScrolled),
                      const SizedBox(width: AppSpacing.sm),
                      ShowShareButton(
                          show: data.show, onImage: hasPoster && !isScrolled),
                    ],
                  ),
                ),
              ),
            ),
            if (args.chatBubble != null)
              Positioned(
                left: AppSpacing.xl,
                bottom: barHeight + safe.bottom + AppSpacing.lg,
                child: args.chatBubble!,
              ),
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
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

class _PosterHero extends StatelessWidget {
  final ShowDetailData data;
  final double height;
  final bool showImage;

  const _PosterHero({
    required this.data,
    required this.height,
    required this.showImage,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    Widget image = OptimizedCachedImage(
      imageUrl: data.show.imageUrl,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
    image = Hero(tag: 'show_${data.show.id}', child: image);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
        child: Stack(
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
          ],
        ),
      ),
    );
  }
}

/// Afişin altındaki yumuşak bilgi yüzeyi. Oyun adı afişte olduğu için
/// burada küçük; gerçek süre / yaş / tür / seans. Buton yığını yok.
class _ShowFactsCard extends StatelessWidget {
  final ShowDetailData data;
  final Animation<double> headline;

  const _ShowFactsCard({required this.data, required this.headline});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final show = data.show;
    final chips = <String>[
      if (show.duration.trim().isNotEmpty) show.duration.trim(),
      if (show.ageLimit.trim().isNotEmpty) show.ageLimit.trim(),
      if (show.category.trim().isNotEmpty) show.category.trim(),
    ];
    final ShowSession? next = data.nextSession;
    final double? lowest = data.lowestPrice;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: AuthWipeReveal(
                reveal: headline,
                child: Text(
                  show.name,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: ShowTeamCredit(teamId: show.teamId),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final chip in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        chip,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!data.isExternal) ...[
              const SizedBox(height: AppSpacing.lg),
              _FactRow(
                label: next == null ? 'Seans' : 'En yakın seans',
                value: next?.shortLabel ?? 'Satışta seans yok',
              ),
              if (lowest != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _FactRow(
                  label: data.sessions
                              .map((final s) => s.price)
                              .whereType<double>()
                              .toSet()
                              .length >
                          1
                      ? 'En uygun'
                      : 'Fiyat',
                  value: formatTicketPrice(lowest),
                ),
              ],
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Biletler başka bir platformda satılıyor.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({required this.label, required this.value});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

    final String? priceLabel = (!data.isExternal && lowest != null)
        ? formatTicketPrice(lowest)
        : null;
    final String? priceHint = priceLabel == null
        ? null
        : (data.sessions.map((final s) => s.price).whereType<double>().toSet().length >
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
