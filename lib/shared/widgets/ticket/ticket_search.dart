import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/shows/presentation/providers/show_provider.dart';

/// "Gişe arama fişi" — ana sayfa ve arama sayfasının ortak arama kabuğu.
///
/// Solda temanın vurgu renginde yuvarlak bir DAMGA (arama ikonu), yanında
/// bilet koçanı gibi kesikli delik çizgisi, sağda içerik ([child]: ana
/// sayfada dönen örnekler, arama sayfasında gerçek yazı alanı). Odakta
/// kenarlık vurgu rengine döner. Renkler tamamen temadan.
class TicketSearchShell extends StatelessWidget {
  final Widget child;
  final bool focused;
  final bool compact;
  final Widget? trailing;

  const TicketSearchShell({
    super.key,
    required this.child,
    this.focused = false,
    this.compact = false,
    this.trailing,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double h = compact ? 50 : 58;
    final double stamp = h - 16;
    return AnimatedContainer(
      duration: AppMotion.fast,
      height: h,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(
          color: focused ? cs.primary : cs.outlineVariant,
          width: focused ? 1.8 : 1,
        ),
      ),
      padding: const EdgeInsets.only(left: 8, right: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: stamp,
            height: stamp,
            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            child: Icon(Icons.search_rounded,
                size: compact ? 20 : 22, color: cs.onPrimary),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          SizedBox(
            width: 1.4,
            height: h - 22,
            child: CustomPaint(painter: _PerforationPainter(cs.outlineVariant)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  final Color color;
  const _PerforationPainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, (y + 3).clamp(0, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(covariant final _PerforationPainter old) =>
      old.color != color;
}

/// Aramada denenebilecek GERÇEK örnekler: sahnedeki oyunların adları ve
/// türleri (Firebase'den). Veri yoksa genel örnekler.
final searchExamplesProvider = Provider.autoDispose<List<String>>((final ref) {
  final shows = ref.watch(activeShowsProvider(true)).value ?? const [];
  final names = shows
      .map((final s) => s.name.trim())
      .where((final n) => n.isNotEmpty)
      .take(4);
  final kinds = shows
      .map((final s) => s.category.trim())
      .where((final c) => c.isNotEmpty)
      .toSet()
      .take(2);
  final list = <String>[...names, ...kinds];
  return list.isEmpty ? const ['oyun adı', 'oyuncu', 'sahne', 'topluluk'] : list;
});

/// "Ara:" + birkaç saniyede bir yukarı kayarak değişen örnek. Azaltılmış
/// harekette ilk örnekte sabit kalır.
class RotatingSearchHint extends ConsumerStatefulWidget {
  final String prefix;
  const RotatingSearchHint({super.key, this.prefix = 'Ara:'});

  @override
  ConsumerState<RotatingSearchHint> createState() => _RotatingSearchHintState();
}

class _RotatingSearchHintState extends ConsumerState<RotatingSearchHint> {
  static const Duration _every = Duration(milliseconds: 2800);
  Timer? _timer;
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || MediaQuery.of(context).disableAnimations) return;
    _timer = Timer.periodic(_every, (final _) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<String> examples = ref.watch(searchExamplesProvider);
    final String example = examples[_i % examples.length];
    return ExcludeSemantics(
      child: Row(
        children: [
          Text(widget.prefix,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                transitionBuilder: (final child, final anim) {
                  final bool incoming =
                      child.key == ValueKey('$example-$_i');
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, incoming ? 0.9 : -0.9),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                layoutBuilder: (final current, final previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: Text(
                  '"$example"',
                  key: ValueKey('$example-$_i'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ana sayfadaki arama "düğmesi": dokununca arama sayfasına gider (gerçek
/// yazma orada). Klavye odağında vurgu kenarlığı.
class TicketSearchButton extends StatefulWidget {
  final VoidCallback onTap;
  final String semanticLabel;
  final bool compact;

  const TicketSearchButton({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    this.compact = false,
  });

  @override
  State<TicketSearchButton> createState() => _TicketSearchButtonState();
}

class _TicketSearchButtonState extends State<TicketSearchButton> {
  bool _focused = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (final v) => setState(() => _focused = v),
            mouseCursor: SystemMouseCursors.click,
            customBorder: const StadiumBorder(),
            child: TicketSearchShell(
              focused: _focused,
              compact: widget.compact,
              child: const RotatingSearchHint(),
            ),
          ),
        ),
      );
}

