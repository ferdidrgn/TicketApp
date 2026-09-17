import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../../core/theme/app_colors.dart';

/// 🎭 SPOTLIGHT REVEAL
///
/// Flutter yeniden yorumu: `landing/style.css` içindeki `.team .player.reveal`
/// / `spotlightHit` efektinin ruhu — bir oyuncu sahneye adım atar gibi, önce
/// karanlık/gri bir silüet halinde belirir, sonra üzerine düşen spot ışığıyla
/// birlikte tam renge ve netliğe kavuşur. Liste indeksine göre kademeli
/// (staggered) gecikmeyle tetiklenir ve yalnızca ekranda görünür olduğunda
/// (VisibilityDetector) bir kez oynatılır.
class SpotlightReveal extends StatefulWidget {
  final Widget child;
  final int index;

  /// true ise görsel gri tondan renge geçer + spot ışığı parlaması eklenir
  /// (fotoğraf/portre kartları için). false ise yalnızca zarif bir
  /// yükselme+belirme (shows/kart listeleri için) uygulanır.
  final bool colorizeFromGray;
  final Duration staggerStep;
  final Duration duration;
  final double travelDistance;

  const SpotlightReveal({
    super.key,
    required this.child,
    required this.index,
    this.colorizeFromGray = false,
    this.staggerStep = const Duration(milliseconds: 110),
    this.duration = const Duration(milliseconds: 850),
    this.travelDistance = 46,
  });

  @override
  State<SpotlightReveal> createState() => _SpotlightRevealState();
}

class _SpotlightRevealState extends State<SpotlightReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;
  late final Animation<double> _colorAmount;
  late final Animation<double> _flash;
  final Key _visibilityKey = UniqueKey();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _colorAmount = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _flash = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
  }

  void _maybeTrigger(final VisibilityInfo info) {
    if (_triggered || info.visibleFraction < 0.12) return;
    _triggered = true;
    final delay = widget.staggerStep * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _maybeTrigger,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) {
            final entrance = _entrance.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: entrance,
              child: Transform.translate(
                offset:
                    Offset(0, (1 - entrance) * widget.travelDistance),
                child: child,
              ),
            );
          },
          child: !widget.colorizeFromGray
              ? widget.child
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _colorAmount,
                      builder: (final context, final child) => ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                            _spotlightMatrix(_colorAmount.value.clamp(0.0, 1.0))),
                        child: child,
                      ),
                      child: widget.child,
                    ),
                    // Spot ışığı parlaması: rengin tam oturduğu ana denk gelen
                    // kısa, radyal bir ışık patlaması.
                    AnimatedBuilder(
                      animation: _flash,
                      builder: (final context, final child) {
                        final t = _flash.value;
                        // 0 -> 1 -> 0 üçgen yoğunluk (tepe ortada)
                        final intensity = (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
                        if (intensity <= 0.01) return const SizedBox.shrink();
                        return Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    WebColors.primaryGoldLight
                                        .withOpacity(0.55 * intensity),
                                    WebColors.primaryGoldLight
                                        .withOpacity(0.12 * intensity),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 0.75],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      );
}

/// Gri tondan (ve karanlıktan) tam renge yumuşak geçiş matrisi.
/// t=0 -> koyu/gri silüet, t=1 -> tam renk & parlaklık.
List<double> _spotlightMatrix(final double t) {
  const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
  final brightness = 0.20 + 0.80 * t;

  double row(final double colorTerm, final double grayTerm) =>
      (colorTerm * t + grayTerm * (1 - t)) * brightness;

  return [
    row(1, lumR), row(0, lumG), row(0, lumB), 0, 0,
    row(0, lumR), row(1, lumG), row(0, lumB), 0, 0,
    row(0, lumR), row(0, lumG), row(1, lumB), 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 🖱️ HOVER SPOTLIGHT CARD
///
/// Masaüstünde imlecin altını takip eden yumuşak bir ışık halesiyle birlikte
/// kartı hafifçe yukarı kaldıran/kartın içeriğini büyüten hover mikro-etkileşimi.
/// `landing/app.js`'teki `applySpotlight` fonksiyonunun (imleç konumunu CSS
/// değişkenlerine yazıp radial-gradient ile aydınlatma) Flutter karşılığıdır.
class HoverSpotlightCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double lift;
  final double scale;
  final VoidCallback? onTap;

  const HoverSpotlightCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.lift = 10,
    this.scale = 1.0,
    this.onTap,
  });

  @override
  State<HoverSpotlightCard> createState() => _HoverSpotlightCardState();
}

class _HoverSpotlightCardState extends State<HoverSpotlightCard> {
  bool _hovering = false;
  Offset? _localPosition;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (final _) => setState(() => _hovering = true),
        onExit: (final _) => setState(() {
          _hovering = false;
          _localPosition = null;
        }),
        onHover: (final event) =>
            setState(() => _localPosition = event.localPosition),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, _hovering ? -widget.lift : 0.0)
              ..scale(_hovering ? widget.scale : 1.0),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold
                      .withOpacity(_hovering ? 0.35 : 0.12),
                  blurRadius: _hovering ? 34 : 18,
                  spreadRadius: _hovering ? 1 : 0,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: LayoutBuilder(
                builder: (final context, final constraints) => Stack(
                  fit: StackFit.passthrough,
                  children: [
                    widget.child,
                    if (_hovering && _localPosition != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  ((_localPosition!.dx /
                                              (constraints.maxWidth == 0
                                                  ? 1
                                                  : constraints.maxWidth)) *
                                          2) -
                                      1,
                                  ((_localPosition!.dy /
                                              (constraints.maxHeight == 0
                                                  ? 1
                                                  : constraints.maxHeight)) *
                                          2) -
                                      1,
                                ),
                                radius: 0.9,
                                colors: [
                                  WebColors.primaryGoldLight.withOpacity(0.22),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
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
