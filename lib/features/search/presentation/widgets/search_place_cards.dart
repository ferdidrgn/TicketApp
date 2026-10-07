import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';

/// Arama — mekan: yer fotoğrafı, adres, kapasite. Ekip kartından ayrı dil.
class SearchStageCard extends StatefulWidget {
  final Stage stage;
  final VoidCallback onTap;

  const SearchStageCard({
    super.key,
    required this.stage,
    required this.onTap,
  });

  @override
  State<SearchStageCard> createState() => _SearchStageCardState();
}

class _SearchStageCardState extends State<SearchStageCard> {
  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Stage stage = widget.stage;
    final String address = stage.address.trim();
    final String capacity = stage.capacity.trim();
    return Semantics(
      button: true,
      label: [
        'Sahne',
        stage.name,
        if (address.isNotEmpty) address,
        if (capacity.isNotEmpty) '$capacity kişilik',
      ].join(', '),
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Material(
          color: cs.surfaceContainerLow,
          elevation: 0,
          shadowColor: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              TiyatrolHeroFlight.prepare(
                  TiyatrolHeroTags.stage(widget.stage.id, 'search'));
              widget.onTap();
            },
            onHighlightChanged: (final v) => setState(() => _pressed = v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 148,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                        ),
                        child: TiyatrolHero(
                          tag: TiyatrolHeroTags.stage(stage.id, 'search'),
                          child: stage.imageUrl.trim().isEmpty
                              ? Icon(Icons.location_city_rounded,
                                  size: 40, color: cs.onSecondaryContainer)
                              : OptimizedCachedImage(
                                  imageUrl: stage.imageUrl,
                                  fit: BoxFit.cover,
                                  borderRadius: 0,
                                ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xB3000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: _KindChip(
                          label: 'Sahne',
                          background: cs.secondaryContainer,
                          foreground: cs.onSecondaryContainer,
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Text(
                          stage.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          address.isEmpty ? 'Adres yok' : address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (capacity.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$capacity kişi',
                          style: TextStyle(
                            color: cs.onSurface,
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

/// Arama — ekip: topluluk sayısı önde, afiş dikey. Mekan kartından ayrı dil.
class SearchTeamCard extends StatefulWidget {
  final Team team;
  final VoidCallback onTap;

  const SearchTeamCard({
    super.key,
    required this.team,
    required this.onTap,
  });

  @override
  State<SearchTeamCard> createState() => _SearchTeamCardState();
}

class _SearchTeamCardState extends State<SearchTeamCard> {
  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Team team = widget.team;
    final int shows = team.showsId.length;
    return Semantics(
      button: true,
      label: shows == 0
          ? 'Topluluk, ${team.name}'
          : 'Topluluk, ${team.name}, $shows oyun',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Material(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              TiyatrolHeroFlight.prepare(
                  TiyatrolHeroTags.team(widget.team.id, 'search'));
              widget.onTap();
            },
            onHighlightChanged: (final v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: AppShadows.level1(cs.shadow),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 72,
                        height: 96,
                        child: TiyatrolHero(
                          tag: TiyatrolHeroTags.team(team.id, 'search'),
                          child: team.imageUrl.trim().isEmpty
                              ? ColoredBox(
                                  color: cs.surface,
                                  child: Icon(Icons.groups_rounded,
                                      color: cs.onTertiaryContainer),
                                )
                              : OptimizedCachedImage(
                                  imageUrl: team.imageUrl,
                                  fit: BoxFit.cover,
                                  borderRadius: 0,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KindChip(
                          label: 'Topluluk',
                          background: cs.surface,
                          foreground: cs.onSurface,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          team.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: cs.onTertiaryContainer,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    children: [
                      Text(
                        '$shows',
                        style: GoogleFonts.playfairDisplay(
                          color: cs.onTertiaryContainer,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        'oyun',
                        style: TextStyle(
                          color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _KindChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
