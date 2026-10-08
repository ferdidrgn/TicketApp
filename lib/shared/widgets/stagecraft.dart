import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'optimized_cached_image.dart';
import 'ticket/ticket_kit.dart';

/// Keşif yüzeylerinin ortak sahne zanaatı: basılı afiş plağı, mürekkep
/// çizgisi, kâğıt tanesi, tek birincil plaka butonu.
///
/// Bilet koçanı yoktur (04.10: ana sayfa/arama fotoğraf odaklı). Perde,
/// spot ve D-köşe yoktur. Renkler temadan gelir; afiş üstü okunaklılık
/// için karartma sabittir.

/// Fotoğraf üstünde okunaklılık — tema rengi değil, basılı afiş mürekkebi.
const Color kPosterScrim = Color(0xD9000000);
const Color kPosterInk = Color(0xFFF6F1E4);

class PaperGrain extends StatelessWidget {
  final Widget child;
  final double strength;

  const PaperGrain({
    super.key,
    required this.child,
    this.strength = 0.045,
  });

  @override
  Widget build(final BuildContext context) {
    final Color tint = Theme.of(context).colorScheme.onSurface;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GrainPainter(tint: tint, strength: strength),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  final Color tint;
  final double strength;
  const _GrainPainter({required this.tint, required this.strength});

  @override
  void paint(final Canvas canvas, final Size size) {
    if (size.isEmpty) return;
    final math.Random rng = math.Random(17);
    final Paint speckle = Paint()
      ..color = tint.withValues(alpha: strength)
      ..strokeWidth = 1;
    final int count =
        (size.width * size.height / 280).clamp(40, 220).toInt();
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextBool() ? 0.6 : 0.4,
        speckle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final _GrainPainter old) =>
      old.tint != tint || old.strength != strength;
}

class CinematicScrim extends StatelessWidget {
  const CinematicScrim({super.key});

  @override
  Widget build(final BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.28, 0.72, 1],
            colors: [
              Color(0x00000000),
              Color(0x66000000),
              kPosterScrim,
            ],
          ),
        ),
      );
}

/// Afişin yavaş zoom'u — sayfa başına bir kez. Azaltılmış harekette durur.
class KenBurns extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const KenBurns({super.key, required this.child, this.enabled = true});

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    if (!widget.enabled || reduce) {
      _c.value = 0;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (final context, final child) => Transform.scale(
        scale: 1.0 + (_c.value * 0.08),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class PosterPlate extends StatelessWidget {
  final Widget child;
  final double radius;
  final List<BoxShadow>? shadows;
  final Color? tint;

  const PosterPlate({
    super.key,
    required this.child,
    this.radius = AppRadius.lg,
    this.shadows,
    this.tint,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? AppShadows.level4(tint ?? cs.shadow),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class CachedPoster extends StatelessWidget {
  final String url;
  final String? semanticLabel;

  const CachedPoster({super.key, required this.url, this.semanticLabel});

  @override
  Widget build(final BuildContext context) {
    final Widget image = OptimizedCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
    if (semanticLabel == null) return image;
    return Semantics(image: true, label: semanticLabel, child: image);
  }
}

/// Bölüm başlığı: Playfair + mürekkep çizgisi. Eyebrow yok.
class StageMasthead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Animation<double>? reveal;
  final EdgeInsetsGeometry padding;

  const StageMasthead({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.reveal,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.xl, 0, AppSpacing.sm, AppSpacing.md),
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double size = MediaQuery.sizeOf(context).width < 768 ? 24.0 : 30.0;
    Widget titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.playfairDisplay(
          color: cs.onSurface,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1.08,
        ),
      ),
    );
    if (reveal != null) {
      titleWidget = AuthWipeReveal(reveal: reveal!, child: titleWidget);
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: titleWidget),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TitleInkMark(color: cs.primary, width: 40),
        ],
      ),
    );
  }
}

class PlateButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool expanded;

  const PlateButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.expanded = true,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget child = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: cs.onPrimary,
            ),
          )
        : Text(label);
    final ButtonStyle style = FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: 52,
        child: FilledButton(
          onPressed: busy || onPressed == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                },
          style: style,
          child: child,
        ),
      ),
    );
  }
}

/// Giriş: aşağıdan 24px + fade. Sayfa başına tek kez.
class StageSettle extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double lift;

  const StageSettle({
    super.key,
    required this.animation,
    required this.child,
    this.lift = 24,
  });

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (final context, final c) => Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * lift),
            child: c,
          ),
        ),
        child: child,
      );
}

String stageMonthShort(final int month) => const [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ][month - 1];

String stageSessionLabel(final DateTime date) =>
    '${date.day} ${stageMonthShort(date.month)}, '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';
