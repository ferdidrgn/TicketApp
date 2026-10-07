import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../home/presentation/widgets/common/home_showcase.dart';
import '../../../shows/domain/entities/show.dart';

/// Keşfet dili: 120 genişlikte ClipRRect r=60 hap portre, Playfair ad
/// (sayfanın tek perde açılışı), gerçek "şu an sahnede" alanı, TEK birincil
/// aksiyon. Koçan / damga yok — yuvarlak 76 ve elips 84×128 reddedildi.
class PlayerIdentityCard extends StatefulWidget {
  final String fullName;
  final String imageUrl;
  final String? quote;
  final String onStageLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PlayerIdentityCard({
    super.key,
    required this.fullName,
    required this.imageUrl,
    required this.onStageLabel,
    this.quote,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<PlayerIdentityCard> createState() => _PlayerIdentityCardState();
}

class _PlayerIdentityCardState extends State<PlayerIdentityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 1.0, curve: AppMotion.dramatic));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _entrance.value = 1;
    } else if (!_started) {
      _entrance.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _runAction() {
    final VoidCallback? tap = widget.onAction;
    if (tap == null) {
      return;
    }
    HapticFeedback.selectionClick();
    tap();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String quote = widget.quote?.trim() ?? '';
    final String? actionLabel = widget.actionLabel;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PillPortrait(
                  url: widget.imageUrl,
                  label: '${widget.fullName} portresi',
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: AuthWipeReveal(
                          reveal: _headline,
                          child: Text(
                            widget.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: colors.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                            ),
                          ),
                        ),
                      ),
                      if (quote.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '“$quote”',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: colors.onSurfaceVariant,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Şu an sahnede',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.onStageLabel,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: actionLabel,
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: _runAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sahibinin onayladığı hap portre: 120 genişlik, ClipRRect r=60.
class _PillPortrait extends StatelessWidget {
  final String url;
  final String label;

  static const double _width = 120;
  static const double _height = 168;
  static const double _radius = 60;

  const _PillPortrait({required this.url, required this.label});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final bool hasImage = url.trim().isNotEmpty;
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SizedBox(
          width: _width,
          height: _height,
          child: ColoredBox(
            color: colors.surfaceContainerHighest,
            child: hasImage
                ? OptimizedCachedImage(
                    imageUrl: url,
                    width: _width,
                    height: _height,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  )
                : Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Sahnedeki / geçmiş oyunlar: Keşfet’teki `HomePosterCard` ızgarası
/// (dar ekranda yatay afiş şeridi). Bilet koçanı yok.
class PlayerShowPosters extends StatelessWidget {
  final List<Show> shows;
  final bool compact;
  final bool dimmed;

  const PlayerShowPosters({
    super.key,
    required this.shows,
    required this.compact,
    this.dimmed = false,
  });

  void _open(final BuildContext context, final Show show) {
    HapticFeedback.selectionClick();
    NavigationHandler.goToShow(context, show.id, show.name);
  }

  Widget _card(final BuildContext context, final Show show) {
    final Widget card = HomePosterCard(
      key: ValueKey('player-poster-${show.id}'),
      show: show,
      onTap: () => _open(context, show),
    );
    return dimmed ? Opacity(opacity: 0.85, child: card) : card;
  }

  @override
  Widget build(final BuildContext context) {
    if (compact) {
      return SizedBox(
        height: 292,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shows.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (final context, final i) => SizedBox(
            width: 168,
            child: _card(context, shows[i]),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      itemCount: shows.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (final context, final i) => _card(context, shows[i]),
    );
  }
}
