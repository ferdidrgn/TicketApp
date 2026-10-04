import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/shows/presentation/providers/show_provider.dart';

/// Ana sayfa ve arama sayfasının ortak arama çubuğu — "ışıyan kenar".
///
/// Çubuğun kenarında temanın renklerinden (vurgu → üçüncül → ikincil)
/// oluşan ince bir ışık halkası yavaşça döner; içerik ferah, kenarlıksız
/// bir yüzeyde durur. Odakta halka hızlanır ve kalınlaşır. Azaltılmış
/// harekette halka sabit durur. Renkler tamamen temadan.
class TicketSearchShell extends StatefulWidget {
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
  State<TicketSearchShell> createState() => _TicketSearchShellState();
}

class _TicketSearchShellState extends State<TicketSearchShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double h = widget.compact ? 50 : 56;
    final double r = h / 2;
    final double ring = widget.focused ? 2.2 : 1.4;

    return AnimatedBuilder(
      animation: _spin,
      builder: (final context, final child) => Container(
        height: h,
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          boxShadow: AppShadows.level2(cs.shadow),
          gradient: SweepGradient(
            transform: GradientRotation(_spin.value * 2 * math.pi),
            colors: [
              cs.primary,
              cs.tertiary.withValues(alpha: widget.focused ? 1 : 0.55),
              cs.outlineVariant.withValues(alpha: 0.35),
              cs.secondary.withValues(alpha: widget.focused ? 1 : 0.55),
              cs.primary,
            ],
          ),
        ),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(r),
        ),
        padding: const EdgeInsets.only(
            left: AppSpacing.lg, right: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: widget.compact ? 21 : 23,
                color: widget.focused ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: widget.child),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}

/// Aramada denenebilecek örnekler: davet eden kısa sorular + sahnedeki
/// GERÇEK oyunların adları ve türleri (Firebase'den).
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
  return <String>[
    'Bu akşam ne izlesek?',
    ...names,
    'Bir oyuncu adı yaz…',
    ...kinds,
    'Hangi sahne yakınımda?',
  ];
});

/// Daktilo ipucu: örnekler harf harf yazılır, kısa bir bekleme, harf harf
/// silinir, sıradakine geçilir; yanında yanıp sönen bir imleç. Azaltılmış
/// harekette ilk örnek sabit durur.
class RotatingSearchHint extends ConsumerStatefulWidget {
  const RotatingSearchHint({super.key});

  @override
  ConsumerState<RotatingSearchHint> createState() =>
      _RotatingSearchHintState();
}

class _RotatingSearchHintState extends ConsumerState<RotatingSearchHint> {
  static const Duration _tick = Duration(milliseconds: 55);
  static const int _holdTicks = 34; // ~1.9 sn tam metin
  Timer? _timer;
  int _example = 0;
  int _chars = 0;
  int _hold = 0;
  bool _deleting = false;
  bool _static = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _static = MediaQuery.of(context).disableAnimations;
    if (_static || _timer != null) return;
    _timer = Timer.periodic(_tick, (final _) => _step());
  }

  void _step() {
    if (!mounted) return;
    final examples = ref.read(searchExamplesProvider);
    final String text = examples[_example % examples.length];
    setState(() {
      if (!_deleting) {
        if (_chars < text.characters.length) {
          _chars++;
        } else if (_hold < _holdTicks) {
          _hold++;
        } else {
          _deleting = true;
        }
      } else {
        if (_chars > 0) {
          _chars = math.max(0, _chars - 2);
        } else {
          _deleting = false;
          _hold = 0;
          _example++;
        }
      }
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
    final examples = ref.watch(searchExamplesProvider);
    final String full = examples[_example % examples.length];
    final String shown =
        _static ? full : full.characters.take(_chars).toString();
    // İmleç: yazarken sabit, beklerken yanıp söner.
    final bool cursorOn = _static ||
        _deleting ||
        _chars < full.characters.length ||
        (_hold ~/ 8).isEven;

    return ExcludeSemantics(
      child: Row(
        children: [
          Flexible(
            child: Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 1),
          Opacity(
            opacity: cursorOn ? 1 : 0,
            child: Container(width: 2, height: 18, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

/// Ana sayfadaki arama "düğmesi": dokununca arama sayfasına gider (gerçek
/// yazma orada). Klavye odağında halka parlar.
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
            onHover: (final v) => setState(() => _focused = v),
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
