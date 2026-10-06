import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Arama / keşif için yüzen damga balonları ve sahne çukuru zemini.
/// Perde/spot yok; renkler yalnızca temadan.

class TheatreBubbleAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const TheatreBubbleAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

OverlayEntry? _bubbleEntry;

bool get theatreBubblesOpen => _bubbleEntry != null;

void hideTheatreBubbles() {
  _bubbleEntry?.remove();
  _bubbleEntry = null;
}

/// [origin] widget'ının etrafında yüzen damga butonları. Azaltılmış
/// harekette overlay açılmaz — [onSkip] (genelde asıl arama) çalışır.
void showTheatreBubbles({
  required final BuildContext origin,
  required final List<TheatreBubbleAction> actions,
  final VoidCallback? onSkip,
}) {
  if (actions.isEmpty) {
    onSkip?.call();
    return;
  }
  if (theatreBubblesOpen) {
    hideTheatreBubbles();
    onSkip?.call();
    return;
  }
  if (MediaQuery.maybeOf(origin)?.disableAnimations ?? false) {
    onSkip?.call();
    return;
  }

  final OverlayState? overlay = Overlay.maybeOf(origin, rootOverlay: true);
  final RenderObject? box = origin.findRenderObject();
  if (overlay == null || box is! RenderBox || !box.hasSize) {
    onSkip?.call();
    return;
  }

  final Offset center = box.localToGlobal(box.size.center(Offset.zero));
  HapticFeedback.mediumImpact();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (final context) => _BubbleOverlay(
      origin: center,
      actions: actions,
      onDismiss: hideTheatreBubbles,
    ),
  );
  _bubbleEntry = entry;
  overlay.insert(entry);
}

class _BubbleOverlay extends StatefulWidget {
  final Offset origin;
  final List<TheatreBubbleAction> actions;
  final VoidCallback onDismiss;

  const _BubbleOverlay({
    required this.origin,
    required this.actions,
    required this.onDismiss,
  });

  @override
  State<_BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<_BubbleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool fanDown = widget.origin.dy < 150;
    final int n = widget.actions.length;
    const double radius = 118;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _c, curve: const Interval(0, 0.4)),
                child: ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .scrim
                      .withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          for (int i = 0; i < n; i++)
            _placedBubble(
              screen: screen,
              index: i,
              count: n,
              fanDown: fanDown,
              radius: radius,
            ),
        ],
      ),
    );
  }

  Widget _placedBubble({
    required final Size screen,
    required final int index,
    required final int count,
    required final bool fanDown,
    required final double radius,
  }) {
    final double t = count == 1 ? 0.5 : index / (count - 1);
    final double start = fanDown ? (math.pi * 0.18) : (-math.pi + math.pi * 0.18);
    final double sweep = math.pi * 0.64;
    final double a = start + t * sweep;
    final Offset pos = Offset(
      (widget.origin.dx + math.cos(a) * radius)
          .clamp(40.0, screen.width - 40),
      (widget.origin.dy + math.sin(a) * radius * (fanDown ? 1 : 1))
          .clamp(56.0, screen.height - 72),
    );
    final double delay = index * 0.07;
    final Animation<double> pop = CurvedAnimation(
      parent: _c,
      curve: Interval(delay, math.min(1, delay + 0.55),
          curve: AppMotion.overshoot),
    );
    final TheatreBubbleAction action = widget.actions[index];

    return Positioned(
      left: pos.dx - 36,
      top: pos.dy - 40,
      child: FadeTransition(
        opacity: pop,
        child: ScaleTransition(
          scale: pop,
          child: _StampBubble(
            action: action,
            onPicked: () {
              widget.onDismiss();
              action.onTap();
            },
          ),
        ),
      ),
    );
  }
}

class _StampBubble extends StatefulWidget {
  final TheatreBubbleAction action;
  final VoidCallback onPicked;

  const _StampBubble({required this.action, required this.onPicked});

  @override
  State<_StampBubble> createState() => _StampBubbleState();
}

class _StampBubbleState extends State<_StampBubble> {
  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.action.label,
      child: GestureDetector(
        onTapDown: (final _) => setState(() => _pressed = true),
        onTapUp: (final _) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onPicked();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AppMotion.fast,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.level3(cs.shadow),
                  ),
                  child: Icon(widget.action.icon,
                      color: cs.onPrimary, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: cs.surface.withValues(alpha: 0.9),
                        blurRadius: 8,
                      ),
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

/// Odaklanınca zıplayan dairesel damga satırı (arama türleri).
class TheatreStampRow extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const TheatreStampRow({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(final BuildContext context) {
    assert(labels.length == icons.length);
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (final context, final i) => _FacetStamp(
          label: labels[i],
          icon: icons[i],
          selected: i == selectedIndex,
          delay: i * 40,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(i);
          },
        ),
      ),
    );
  }
}

class _FacetStamp extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int delay;
  final VoidCallback onTap;

  const _FacetStamp({
    required this.label,
    required this.icon,
    required this.selected,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_FacetStamp> createState() => _FacetStampState();
}

class _FacetStampState extends State<_FacetStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: AppMotion.normal);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) async {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _in.value = 1;
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: widget.delay));
      if (mounted) _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool on = widget.selected;
    return FadeTransition(
      opacity: _in,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _in, curve: AppMotion.overshoot)),
        child: Semantics(
          button: true,
          selected: on,
          label: widget.label,
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: on ? cs.primary : cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: on ? cs.primary : cs.outlineVariant,
                      ),
                      boxShadow: on ? AppShadows.level2(cs.shadow) : null,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: on ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: on ? cs.primary : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üstte çok soluk eşmerkezli yaylar — sahne çukuru hissi, perde değil.
class StageAtmosphere extends StatelessWidget {
  const StageAtmosphere({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: CustomPaint(
        painter: _PitPainter(
          wash: cs.primary.withValues(alpha: 0.07),
          line: cs.tertiary.withValues(alpha: 0.12),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PitPainter extends CustomPainter {
  final Color wash;
  final Color line;

  const _PitPainter({required this.wash, required this.line});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset c = Offset(size.width / 2, size.height * 0.12);
    final Paint fill = Paint()..color = wash;
    final Paint stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 5; i++) {
      final double r = size.width * (0.18 + i * 0.14);
      canvas.drawCircle(c, r, fill);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        math.pi * 0.08,
        math.pi * 0.84,
        false,
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final _PitPainter old) =>
      old.wash != wash || old.line != line;
}
