import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../navigation/widgets/ticket_nav_bar.dart';

/// Uygulama genelinde "başa dön" — HER sayfada, sayfaya ayrıca bir şey
/// eklemeden çalışır.
///
/// Kökte (`MaterialApp.builder`) duran bir `NotificationListener`, en son
/// kaydırılan DİKEY listeyi yakalar; liste yeterince aşağı indiyse sağ
/// altta küçük bir bilet koçanı belirir, dokununca o listeyi en üste
/// taşır. Yatay şeritler (afiş karuselleri) sayılmaz. Sayfa değişince
/// ([routeChanges] tetiklenince) buton gizlenir; yeni sayfada kaydırma
/// başlayınca yeniden değerlendirilir.
///
/// Tasarım: onaylı bilet dilinin küçük bir parçası — temanın vurgu
/// renginde, iki yanında zımba çentikleri olan bir koçan ve yukarı ok.
/// Renkler tamamen temadan (5 tema + özel renk ile değişir).
class StageScrollTop extends StatefulWidget {
  final Widget child;

  /// Rota değişimlerini bildiren dinlenebilir (ör. go_router'ın
  /// `routerDelegate`'i).
  final Listenable? routeChanges;

  const StageScrollTop({super.key, required this.child, this.routeChanges});

  @override
  State<StageScrollTop> createState() => _StageScrollTopState();
}

class _StageScrollTopState extends State<StageScrollTop> {
  ScrollableState? _target;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.routeChanges?.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant final StageScrollTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeChanges != widget.routeChanges) {
      oldWidget.routeChanges?.removeListener(_onRouteChanged);
      widget.routeChanges?.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    widget.routeChanges?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    _target = null;
    _setVisible(false);
  }

  void _setVisible(final bool v) {
    if (_visible != v && mounted) setState(() => _visible = v);
  }

  bool _onScroll(final ScrollNotification n) {
    final m = n.metrics;
    if (m.axis != Axis.vertical || n.context == null) return false;
    final ScrollableState? s = Scrollable.maybeOf(n.context!);
    if (s == null) return false;
    // Kısa listelerde (bir iki ekranlık) buton gereksiz.
    final double threshold = math.max(420, m.viewportDimension * 0.9);
    final bool show =
        m.maxScrollExtent > m.viewportDimension * 0.6 && m.pixels > threshold;
    if (show) {
      _target = s;
      _setVisible(true);
    } else if (identical(s, _target) || _target == null) {
      _setVisible(false);
    }
    return false;
  }

  void _toTop() {
    final ScrollableState? s = _target;
    if (s == null || !s.mounted) {
      _setVisible(false);
      return;
    }
    HapticFeedback.selectionClick();
    final ScrollPosition p = s.position;
    if (MediaQuery.of(context).disableAnimations) {
      p.jumpTo(p.minScrollExtent);
    } else {
      p.animateTo(p.minScrollExtent,
          duration: AppMotion.slow, curve: AppMotion.dramatic);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool narrow = mq.size.width < 768;
    // Telefonda alt menünün (64) ve varsa sayfanın alt aksiyon çubuğunun
    // üstünde durur; geniş ekranda köşeye yakın.
    final double bottom = narrow
        ? kTicketNavBarExtent + AppSpacing.lg + mq.viewPadding.bottom
        : AppSpacing.xxxl;
    final double right = narrow ? AppSpacing.lg : AppSpacing.xxxl;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          right: right,
          bottom: bottom,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, 0.6),
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: AppMotion.fast,
                child: _StubButton(onTap: _toTop),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StubButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StubButton({required this.onTap});

  static const double _w = 44;
  static const double _h = 48;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const shape = _StubShape();
    return Semantics(
      button: true,
      label: 'Sayfanın başına dön',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: AppShadows.level2(cs.shadow),
        ),
        child: Material(
          color: cs.primary,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: _w,
              height: _h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up_rounded,
                      size: 22, color: cs.onPrimary),
                  // Koçanın delik çizgisi.
                  SizedBox(
                    width: 22,
                    height: 2,
                    child: CustomPaint(
                        painter: _DashPainter(
                            cs.onPrimary.withValues(alpha: 0.55))),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'BAŞA',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      height: 1,
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

/// Küçük bilet koçanı: yuvarlak köşeli dikdörtgen, iki yan kenarın
/// ortasında yarım daire zımba çentikleri.
class _StubShape extends ShapeBorder {
  const _StubShape();

  static const double _corner = 8;
  static const double _notch = 5;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  Path _path(final Rect r) {
    final Path body = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(_corner)));
    final double y = r.top + r.height * 0.62;
    final Path holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(r.left, y), radius: _notch))
      ..addOval(Rect.fromCircle(center: Offset(r.right, y), radius: _notch));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  Path getOuterPath(final Rect rect, {final TextDirection? textDirection}) =>
      _path(rect);

  @override
  Path getInnerPath(final Rect rect, {final TextDirection? textDirection}) =>
      _path(rect);

  @override
  void paint(final Canvas canvas, final Rect rect,
      {final TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(final double t) => this;
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 5) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(math.min(x + 2.5, size.width), size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant final _DashPainter old) => old.color != color;
}
