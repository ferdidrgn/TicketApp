import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/playbill.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../home/presentation/widgets/common/home_showcase.dart';
import '../../../shows/domain/entities/show.dart';

/// Soyunma odası: hap ayna (120 / r=60), ad perde gibi açılır, replik,
/// şu an sahnede. Koçan yok.
class PlayerIdentityCard extends StatefulWidget {
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
  State<PlayerIdentityCard> createState() => _PlayerIdentityCardState();
}

class _PlayerIdentityCardState extends State<PlayerIdentityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.85, curve: AppMotion.dramatic));
  late final Animation<double> _ink = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.42, 0.82, curve: AppMotion.dramatic));
  late final Animation<double> _rest = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.52, 1.0, curve: AppMotion.standard));
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
    if (tap == null) return;
    HapticFeedback.selectionClick();
    tap();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String quote = widget.quote?.trim() ?? '';
    final String? actionLabel = widget.actionLabel;

    final Widget portrait = TiyatrolHero(
      tag: resolveTiyatrolHeroTag(
          context, TiyatrolHeroTags.player(widget.playerId)),
      child: _PillPortrait(
        url: widget.imageUrl,
        label: '${widget.fullName} portresi',
        onTap: widget.onAction == null ? null : _runAction,
      ),
    );

    return Column(
      children: [
        portrait,
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: AuthWipeReveal(
            reveal: _headline,
            child: Text(
              widget.fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: colors.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: TitleInkMark(color: colors.primary, reveal: _ink)),
        if (quote.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          PlaybillQuote(text: quote, reveal: _rest),
        ],
        if (widget.onStageLabel.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          FadeTransition(
            opacity: _rest,
            child: _OnStageLine(
              label: widget.onStageLabel,
              onTap: widget.onAction == null ? null : _runAction,
            ),
          ),
        ],
        if (actionLabel != null && widget.onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FadeTransition(
            opacity: _rest,
            child: Semantics(
              button: true,
              label: actionLabel,
              excludeSemantics: true,
              child: FilledButton(
                onPressed: _runAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OnStageLine extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OnStageLine({required this.label, this.onTap});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Widget text = Column(
      children: [
        Text(
          'Şu an sahnede',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
    if (onTap == null) return text;
    return Semantics(
      button: true,
      label: 'Şu an sahnede, $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs, horizontal: AppSpacing.md),
          child: text,
        ),
      ),
    );
  }
}

/// Sahibinin onayladığı hap portre: 120 genişlik, ClipRRect r=60.
class _PillPortrait extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback? onTap;

  static const double _width = 120;
  static const double _height = 168;
  static const double _radius = 60;

  const _PillPortrait({
    required this.url,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final bool hasImage = url.trim().isNotEmpty;
    final Widget portrait = ClipRRect(
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
    );
    return Semantics(
      image: true,
      button: onTap != null,
      label: onTap == null ? label : '$label, oyuna git',
      child: onTap == null
          ? portrait
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const StadiumBorder(),
                child: portrait,
              ),
            ),
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
      heroFrom: 'player-show',
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
