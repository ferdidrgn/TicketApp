import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/craft.dart';
import '../../../../shared/widgets/listing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../shows/domain/entities/show.dart';

/// Oyuncu kimlik kartı — listing dili (wipe / Playfair / PaperGrain yok).
class PlayerIdentityCard extends StatelessWidget {
  final String playerId;
  final String fullName;
  final String imageUrl;
  final String? quote;
  final String onStageLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PlayerIdentityCard({
    super.key,
    required this.playerId,
    required this.fullName,
    required this.imageUrl,
    required this.onStageLabel,
    this.quote,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final String q = quote?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TiyatrolHero(
          tag: resolveTiyatrolHeroTag(
              context, TiyatrolHeroTags.player(playerId)),
          child: ListingPhotoFrame(
            imageUrl: imageUrl,
            overlay: onStageLabel.isEmpty ? null : onStageLabel,
            height: 260,
            onTap: onAction,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          fullName.isEmpty ? 'Oyuncu' : fullName,
          style: listingUi(
            color: colors.onSurface,
            size: 30,
            weight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        if (q.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            q,
            style: listingUi(
              color: colors.onSurfaceVariant,
              size: 15,
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          ListingCta(label: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}

/// Sahibinin onayladığı hap portre: 120 genişlik, ClipRRect r=60.
class PlayerPillPortrait extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback? onTap;
  final double width;

  const PlayerPillPortrait({
    super.key,
    required this.url,
    required this.label,
    this.onTap,
    this.width = 120,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget portrait = ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: SizedBox(
        width: width,
        height: width * 1.35,
        child: url.trim().isEmpty
            ? ColoredBox(
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.person_rounded, color: cs.onSurfaceVariant),
              )
            : OptimizedCachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
      ),
    );
    if (onTap == null) return portrait;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(onTap: onTap, child: portrait),
    );
  }
}

class PlayerShowPosters extends StatelessWidget {
  final List<Show> shows;
  final bool compact;
  final bool dimmed;

  const PlayerShowPosters({
    super.key,
    required this.shows,
    this.compact = false,
    this.dimmed = false,
  });

  @override
  Widget build(final BuildContext context) {
    final double cardW = compact ? 132 : 156;
    final double cardH = compact ? 200 : 236;
    return SizedBox(
      height: cardH + 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shows.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (final context, final i) {
          final Show show = shows[i];
          return Opacity(
            opacity: dimmed ? 0.72 : 1,
            child: SizedBox(
              width: cardW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListingPhotoFrame(
                      imageUrl: show.imageUrl,
                      height: cardH - 40,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        NavigationHandler.goToShow(
                            context, show.id, show.name);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    show.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: listingUi(
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Arama / keşfet oyuncu şeridi — 120×r60 kuralı.
class PlayerSearchRailCard extends StatelessWidget {
  final String playerId;
  final String firstName;
  final String lastName;
  final String imageUrl;

  const PlayerSearchRailCard({
    super.key,
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String tag = TiyatrolHeroTags.player(playerId);
    return PressScale(
      label: '$firstName $lastName',
      onTap: () {
        TiyatrolHeroFlight.prepare(tag,
            imageUrl: imageUrl, title: '$firstName $lastName'.trim());
        NavigationHandler.goToPlayer(
          context,
          playerId,
          '$firstName $lastName'.trim(),
          heroTag: tag,
          imageUrl: imageUrl,
          title: '$firstName $lastName'.trim(),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: AppShadows.level2(cs.shadow),
              ),
              child: TiyatrolHero(
                tag: tag,
                child: PlayerPillPortrait(
                  url: imageUrl,
                  label: '$firstName $lastName',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: listingUi(
                color: cs.onSurface,
                size: 13,
                weight: FontWeight.w800,
              ),
            ),
            Text(
              lastName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: listingUi(
                color: cs.onSurfaceVariant,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
