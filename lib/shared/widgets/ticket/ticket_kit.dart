import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// "BİLET DİLİ" — TiyatRol'ün imza görsel dili (sahibinin onayladığı ilk
/// ekran: giriş). Arayüzün önemli nesneleri fiziksel tiyatro biletleridir:
/// fildişi kağıt, delikli koçan, barkod, mürekkep damgası. Bu kit bütün
/// uygulamada (oyun kartı, oyun detayı, biletlerim, koltuk, web + mobil)
/// ortak kullanılır.
///
/// Renk: kağıt ve mürekkep sabittir (fiziksel nesne), VURGU ise temadan
/// gelir (`TicketInk.accentOf(context)`) — 5 tema ve kullanıcının özel
/// vurgu rengi biletlere de yansır.

// ─────────────────────────────────────────────────────────────────────────
// Kağıt ve mürekkep — sadece mevcut WebColors token'ları.
// ─────────────────────────────────────────────────────────────────────────

class TicketInk {
  TicketInk._();

  static const Color paper = WebColors.whiteText;
  static const Color paperShade = WebColors.lightWhite;
  static const Color ink = WebColors.veryDarkBlue;
  static const Color accent = WebColors.primaryGold;
  static const Color accentDeep = WebColors.primaryGoldDark;

  static Color inkSoft([final double opacity = 0.6]) =>
      ink.withOpacity(opacity);

  /// Temanın vurgu rengi, AÇIK kağıda basılacak tonda. Koyu temada
  /// `primary` açık tondadır (kağıtta okunmaz); `inversePrimary` orada
  /// koyu tondur.
  static Color accentOf(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.brightness == Brightness.dark ? cs.inversePrimary : cs.primary;
  }

  static Color accentDeepOf(final BuildContext context) =>
      Color.lerp(accentOf(context), ink, 0.3)!;

  /// Karanlık SAHNE zemininde (kağıt değil) okunacak açık vurgu tonu.
  static Color stageAccentOf(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.brightness == Brightness.dark ? cs.primary : cs.inversePrimary;
  }

  /// Vurgu zemini üstündeki yazı rengi (kağıt ya da mürekkep).
  static Color onAccentOf(final BuildContext context) =>
      ThemeData.estimateBrightnessForColor(accentOf(context)) ==
              Brightness.dark
          ? paper
          : ink;

  static TextStyle label({final Color? color}) => TextStyle(
        color: color ?? inkSoft(0.55),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      );

  static TextStyle value({final double size = 14}) => TextStyle(
        color: ink,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );

  static TextStyle headline(final double size) =>
      GoogleFonts.playfairDisplay(
        color: ink,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.02,
        letterSpacing: -0.5,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Sahne zemini: karanlık + yukarıdan düşen spot + (geniş ekranda) perdeler
// ─────────────────────────────────────────────────────────────────────────

/// Biletlerin üzerinde durduğu zemin.
///
/// Varsayılan: sabit karanlık sahne + spot (giriş gibi "an" ekranları).
/// `themed: true`: temanın kendi zemini (`surface`) + çok hafif vurgu
/// tonlu spot — uygulamanın genel sayfaları için; açık temada açık kalır.
class TicketStage extends StatelessWidget {
  final Widget child;
  final bool showCurtains;
  final bool themed;

  /// Yukarıdan düşen spot ışığı. Sade kalması gereken yardımcı sayfalarda
  /// (arama, ayarlar gibi) kapatılır.
  final bool spotlight;

  const TicketStage({
    super.key,
    required this.child,
    this.showCurtains = false,
    this.themed = false,
    this.spotlight = true,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color light = themed ? cs.primary : WebColors.whiteText;
    final double peak = themed ? 0.07 : 0.16;
    return ColoredBox(
        color: themed ? cs.surface : WebColors.darkBlueBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Spot ışığı: sahnenin üstünden bilete düşen dar bir koni.
            if (spotlight)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.15),
                    radius: 1.25,
                    colors: [
                      light.withOpacity(peak),
                      light.withOpacity(peak / 3),
                      light.withOpacity(0),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            if (showCurtains) ...[
              const _Curtain(alignment: Alignment.centerLeft),
              const _Curtain(alignment: Alignment.centerRight),
            ],
            child,
          ],
        ),
      );
  }
}

class _Curtain extends StatelessWidget {
  final Alignment alignment;
  const _Curtain({required this.alignment});

  @override
  Widget build(final BuildContext context) {
    final bool left = alignment == Alignment.centerLeft;
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: 0.14,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: left ? Alignment.centerLeft : Alignment.centerRight,
                end: left ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  WebColors.primaryGoldDark.withOpacity(0.55),
                  WebColors.primaryGoldDark.withOpacity(0.18),
                  WebColors.primaryGoldDark.withOpacity(0),
                ],
              ),
            ),
            child: CustomPaint(painter: _CurtainFoldPainter(left: left)),
          ),
        ),
      ),
    );
  }
}

/// Perdenin kumaş kıvrımları — birkaç dikey, yumuşak koyu çizgi.
class _CurtainFoldPainter extends CustomPainter {
  final bool left;
  const _CurtainFoldPainter({required this.left});

  @override
  void paint(final Canvas canvas, final Size size) {
    for (int i = 0; i < 4; i++) {
      final double t = (i + 1) / 5;
      final double x = left ? size.width * t * 0.8 : size.width * (1 - t * 0.8);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            WebColors.veryDarkBlue.withOpacity(0.35 * (1 - t)),
            WebColors.veryDarkBlue.withOpacity(0),
          ],
        ).createShader(Offset.zero & size)
        ..strokeWidth = 10 * (1 - t) + 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _CurtainFoldPainter old) =>
      old.left != left;
}

// ─────────────────────────────────────────────────────────────────────────
// Bilet şekli: köşeleri yuvarlak, delikli kenarında yarım daire çentikli
// iki parça (gövde + koçan). İki ayrı parça olduğu için koçan bağımsız
// olarak "yırtılabiliyor".
// ─────────────────────────────────────────────────────────────────────────

/// Bilet parçasının DELİKLİ (koçana bakan, çentikli) kenarı.
enum TicketEdge { top, bottom, left, right }

class _TicketPieceBorder extends ShapeBorder {
  final TicketEdge edge;
  final double corner;
  final double notch;

  const _TicketPieceBorder({
    required this.edge,
    this.corner = AppRadius.md,
    this.notch = 14,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(final Rect rect, {final TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(final Rect rect, {final TextDirection? textDirection}) {
    final double w = rect.width, h = rect.height;
    final double r = math.min(corner, math.min(w, h) / 2);
    final double n = math.min(notch, math.min(w, h) / 3);
    final Radius cr = Radius.circular(r);
    final Radius nr = Radius.circular(n);
    final Path p = Path();

    switch (edge) {
      case TicketEdge.bottom:
        p
          ..moveTo(r, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r), radius: cr)
          ..lineTo(w, h - n)
          ..arcToPoint(Offset(w - n, h), radius: nr, clockwise: false)
          ..lineTo(n, h)
          ..arcToPoint(Offset(0, h - n), radius: nr, clockwise: false)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0), radius: cr);
      case TicketEdge.top:
        p
          ..moveTo(0, n)
          ..arcToPoint(Offset(n, 0), radius: nr, clockwise: false)
          ..lineTo(w - n, 0)
          ..arcToPoint(Offset(w, n), radius: nr, clockwise: false)
          ..lineTo(w, h - r)
          ..arcToPoint(Offset(w - r, h), radius: cr)
          ..lineTo(r, h)
          ..arcToPoint(Offset(0, h - r), radius: cr);
      case TicketEdge.right:
        p
          ..moveTo(r, 0)
          ..lineTo(w - n, 0)
          ..arcToPoint(Offset(w, n), radius: nr, clockwise: false)
          ..lineTo(w, h - n)
          ..arcToPoint(Offset(w - n, h), radius: nr, clockwise: false)
          ..lineTo(r, h)
          ..arcToPoint(Offset(0, h - r), radius: cr)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0), radius: cr);
      case TicketEdge.left:
        p
          ..moveTo(n, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r), radius: cr)
          ..lineTo(w, h - r)
          ..arcToPoint(Offset(w - r, h), radius: cr)
          ..lineTo(n, h)
          ..arcToPoint(Offset(0, h - n), radius: nr, clockwise: false)
          ..lineTo(0, n)
          ..arcToPoint(Offset(n, 0), radius: nr, clockwise: false);
    }
    p.close();
    return p.shift(rect.topLeft);
  }

  @override
  void paint(final Canvas canvas, final Rect rect,
      {final TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(final double t) => _TicketPieceBorder(
      edge: edge, corner: corner * t, notch: notch * t);
}

/// Delik çizgisi — iki çentik arasında kesik kesik bir hat.
class _PerforationPainter extends CustomPainter {
  final Axis axis;
  const _PerforationPainter(this.axis);

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = TicketInk.inkSoft(0.28)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const double dash = 5, gap = 5, inset = 20;
    if (axis == Axis.horizontal) {
      final double y = size.height / 2;
      for (double x = inset; x < size.width - inset; x += dash + gap) {
        canvas.drawLine(Offset(x, y),
            Offset(math.min(x + dash, size.width - inset), y), paint);
      }
    } else {
      final double x = size.width / 2;
      for (double y = inset; y < size.height - inset; y += dash + gap) {
        canvas.drawLine(Offset(x, y),
            Offset(x, math.min(y + dash, size.height - inset)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant final _PerforationPainter old) =>
      old.axis != axis;
}

/// Fiziksel bilet: [body] (gövde) + delik çizgisi + [stub] (koçan).
///
/// [direction] `Axis.vertical` → koçan altta (mobil/tablet), `Axis.horizontal`
/// → koçan sağda (geniş web). [tear] 0→1 ilerledikçe koçan delikten
/// kopup düşer; hata olursa ters oynatılınca geri yapışır.
class AdmitTicket extends StatelessWidget {
  final Axis direction;
  final Widget body;
  final Widget stub;
  final Animation<double> tear;
  final double stubExtent;

  /// Parçaların gölgesi. Varsayılan (null) tek başına duran "an" biletleri
  /// için ağır gölge; listelerde `AppShadows.level2(...)` gibi hafif olanı ver.
  final List<BoxShadow>? shadows;

  /// Yırtılma istenmeyen yerler için sabit (hiç oynamayan) animasyon.
  static const Animation<double> noTear = AlwaysStoppedAnimation<double>(0);

  const AdmitTicket({
    super.key,
    required this.direction,
    required this.body,
    required this.stub,
    this.tear = noTear,
    this.stubExtent = 220,
    this.shadows,
  });

  static const double _perforation = 2;

  Widget _piece(final TicketEdge edge, final Widget child) => TicketPiece(
        perforated: edge,
        shadows: shadows ?? AppShadows.level5(WebColors.veryDarkBlue),
        child: child,
      );

  @override
  Widget build(final BuildContext context) {
    final bool vertical = direction == Axis.vertical;

    final Widget tornStub = AnimatedBuilder(
      animation: tear,
      builder: (final context, final child) {
        final double t = tear.value;
        if (t == 0) return child!;
        // Koçan delikten kopar: hafif döner, aşağı/sağa kayar, solar.
        return Opacity(
          opacity: (1 - t * 1.1).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: vertical ? Offset(t * 18, t * 90) : Offset(t * 90, t * 40),
            child: Transform.rotate(
              angle: (vertical ? 0.14 : 0.2) * t,
              alignment: vertical ? Alignment.topLeft : Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
      child: _piece(
        vertical ? TicketEdge.top : TicketEdge.left,
        stub,
      ),
    );

    final Widget bodyPiece = _piece(
      vertical ? TicketEdge.bottom : TicketEdge.right,
      body,
    );

    final Widget perforation = SizedBox(
      width: vertical ? double.infinity : _perforation,
      height: vertical ? _perforation : double.infinity,
      child: CustomPaint(
        painter: _PerforationPainter(
            vertical ? Axis.horizontal : Axis.vertical),
      ),
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          bodyPiece,
          Stack(
            clipBehavior: Clip.none,
            fit: StackFit.passthrough,
            children: [
              tornStub,
              Positioned(top: -_perforation / 2, left: 0, right: 0,
                  child: perforation),
            ],
          ),
        ],
      );
    }
    // Yatay bilet: gövde yüksekliği belirler, koçan o yüksekliğe uyar.
    // (IntrinsicHeight kullanılmıyor — içindeki TextField/Pinput gibi
    // widget'larla intrinsic hesap kırılgan.)
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: EdgeInsets.only(right: stubExtent),
          child: bodyPiece,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: stubExtent,
          child: tornStub,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: stubExtent - _perforation / 2,
          child: perforation,
        ),
      ],
    );
  }
}

/// Tek bir bilet parçası (gövde ya da koçan): fildişi kağıt, yuvarlak
/// köşeler, [perforated] kenarında yarım daire çentikler. İçerik şekle
/// kırpılır. Kart gibi kendi yerleşimini kuran yerler bunu doğrudan
/// kullanır (bkz. `TheatreShowCard`).
class TicketPiece extends StatelessWidget {
  final TicketEdge perforated;
  final Widget child;
  final List<BoxShadow>? shadows;
  final double notch;
  final double corner;

  const TicketPiece({
    super.key,
    required this.perforated,
    required this.child,
    this.shadows,
    this.notch = 14,
    this.corner = AppRadius.md,
  });

  @override
  Widget build(final BuildContext context) {
    final shape =
        _TicketPieceBorder(edge: perforated, notch: notch, corner: corner);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TicketInk.paper, TicketInk.paperShade],
        ),
        shadows: shadows,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: child,
      ),
    );
  }
}

/// Delik çizgisi. [axis] çizginin yönü (yatay çizgi → `Axis.horizontal`).
/// Boyutunu ebeveyninden alır (ör. `SizedBox(height: 2)` içinde).
class TicketPerforation extends StatelessWidget {
  final Axis axis;
  const TicketPerforation({super.key, this.axis = Axis.horizontal});

  @override
  Widget build(final BuildContext context) => SizedBox.expand(
        child: CustomPaint(painter: _PerforationPainter(axis)),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Biletin üstüne basılı parçalar
// ─────────────────────────────────────────────────────────────────────────

/// Biletin üst şeridi: marka + bilet türü + ince çizgi.
class TicketHeaderStrip extends StatelessWidget {
  final String kind;
  const TicketHeaderStrip({super.key, required this.kind});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.theater_comedy_rounded,
                  size: 16, color: TicketInk.accentOf(context)),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'TİYATROL',
                style: GoogleFonts.playfairDisplay(
                  color: TicketInk.accentOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  kind,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TicketInk.label(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1.4, color: TicketInk.inkSoft(0.8)),
          const SizedBox(height: 2),
          Container(height: 0.6, color: TicketInk.inkSoft(0.5)),
        ],
      );
}

/// Bilet alanı: küçük etiket + basılı değer (TARİH / SAAT / KOLTUK gibi).
class TicketField extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const TicketField({
    super.key,
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TicketInk.label()),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TicketInk.value(),
          ),
        ],
      );
}

/// Barkod — verilen metinden türetilen sabit (her çizimde aynı) çizgiler.
class TicketBarcode extends StatelessWidget {
  final String seed;
  final double height;
  final Axis direction;

  const TicketBarcode({
    super.key,
    required this.seed,
    this.height = 44,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          // Uzun kenar mevcut alanı doldurur; CustomPaint'in çocuğu yok,
          // aksi hâlde boyutu sıfıra düşer ve barkod görünmez.
          height: direction == Axis.horizontal ? height : double.infinity,
          width: direction == Axis.vertical ? height : double.infinity,
          child: CustomPaint(painter: _BarcodePainter(seed, direction)),
        ),
      );
}

class _BarcodePainter extends CustomPainter {
  final String seed;
  final Axis direction;
  const _BarcodePainter(this.seed, this.direction);

  @override
  void paint(final Canvas canvas, final Size size) {
    final rnd = math.Random(seed.hashCode);
    final paint = Paint()..color = TicketInk.ink;
    final double length =
        direction == Axis.horizontal ? size.width : size.height;
    final double thickness =
        direction == Axis.horizontal ? size.height : size.width;
    double pos = 0;
    while (pos < length) {
      final double bar = 1.0 + rnd.nextInt(3).toDouble();
      final double gap = 1.0 + rnd.nextInt(3).toDouble();
      if (pos + bar > length) break;
      final Rect r = direction == Axis.horizontal
          ? Rect.fromLTWH(pos, 0, bar, thickness)
          : Rect.fromLTWH(0, pos, thickness, bar);
      canvas.drawRect(r, paint);
      pos += bar + gap;
    }
  }

  @override
  bool shouldRepaint(covariant final _BarcodePainter old) =>
      old.seed != seed || old.direction != direction;
}

/// Mürekkep damgası — kod gönderildiğinde bilete "güm" diye basılır.
class TicketInkStamp extends StatelessWidget {
  final String text;
  final Animation<double> appear;

  const TicketInkStamp({super.key, required this.text, required this.appear});

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: appear,
        builder: (final context, final child) {
          final double t = appear.value;
          if (t == 0) return const SizedBox.shrink();
          return Opacity(
            opacity: (t * 1.4).clamp(0.0, 0.85),
            child: Transform.rotate(
              angle: -0.2,
              child: Transform.scale(scale: 1.6 - 0.6 * t, child: child),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border.all(color: TicketInk.accentOf(context), width: 2),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: TicketInk.accentOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      );
}

/// Bilete basılı aksiyon. `primary` → temanın vurgu renginde damga,
/// değilse mürekkep çerçeveli ikincil satır. `onTap` null ise (ve yükleme
/// yoksa) soluk görünür — pasif olduğu belli olur.
class TicketStampButton extends StatefulWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  final String? loadingLabel;

  const TicketStampButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.primary = true,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  State<TicketStampButton> createState() => _TicketStampButtonState();
}

class _TicketStampButtonState extends State<TicketStampButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final bool enabled = widget.onTap != null && !widget.loading;
    final bool primary = widget.primary;
    final Color accent = TicketInk.accentOf(context);
    final Color fg = primary ? TicketInk.onAccentOf(context) : TicketInk.ink;

    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.leading != null)
          IconTheme.merge(
            data: IconThemeData(color: fg, size: 18),
            child: widget.leading!,
          ),
        if (widget.loading || widget.leading != null)
          const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            widget.loading
                ? (widget.loadingLabel ?? widget.label)
                : widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: primary ? 14 : 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: primary ? 1.6 : 0.6,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: widget.onTap == null && !widget.loading ? 0.45 : 1,
        duration: AppMotion.fast,
        child: MouseRegion(
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Material(
            color: primary
                ? (_hovered ? TicketInk.accentDeepOf(context) : accent)
                : (_hovered ? TicketInk.inkSoft(0.06) : Colors.transparent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              side: primary
                  ? BorderSide.none
                  : BorderSide(color: TicketInk.inkSoft(0.7), width: 1.3),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? widget.onTap : null,
              onHighlightChanged: (final v) => setState(() => _pressed = v),
              splashColor: fg.withOpacity(0.12),
              highlightColor: fg.withOpacity(0.06),
              focusColor: accent.withOpacity(0.18),
              child: SizedBox(
                height: primary ? 56 : 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Mürekkep rengi, altı çizili basit metin bağlantısı (Numarayı düzenle vb.).
class TicketTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool emphasize;

  const TicketTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  @override
  Widget build(final BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor:
              emphasize ? TicketInk.accentOf(context) : TicketInk.ink,
          disabledForegroundColor: TicketInk.inkSoft(0.35),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          minimumSize: const Size(48, 44),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Metin perde açılışı (önceki tasarımdan beğenilen tek parça — korunuyor)
// ─────────────────────────────────────────────────────────────────────────

class AuthWipeReveal extends StatelessWidget {
  final Animation<double> reveal;
  final Alignment alignment;
  final Widget child;

  const AuthWipeReveal({
    super.key,
    required this.reveal,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  // Dıştaki Align genişlik kısıtını gevşetir: tam genişliğe zorlanan bir
  // yerde (ör. stretch Column) içteki `widthFactor` yok sayılıyor ve metin
  // hiç açılmadan görünüyordu. `heightFactor: 1` yüksekliği metne eşitler.
  @override
  Widget build(final BuildContext context) => Align(
        alignment: alignment,
        heightFactor: 1,
        child: AnimatedBuilder(
          animation: reveal,
          builder: (final context, final child) => ClipRect(
            child: Align(
              alignment: alignment,
              widthFactor: reveal.value.clamp(0.0001, 1.0),
              child: child,
            ),
          ),
          child: child,
        ),
      );
}

/// Perde açılışının ardından büyüyen kısa mürekkep çizgisi.
class TitleInkMark extends StatelessWidget {
  final Animation<double>? reveal;
  final Color color;
  final double width;

  const TitleInkMark({
    super.key,
    required this.color,
    this.reveal,
    this.width = 36,
  });

  @override
  Widget build(final BuildContext context) {
    Widget line(final double t) => Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width * t.clamp(0.0, 1.0),
            height: 2,
            child: ColoredBox(color: color),
          ),
        );
    final Animation<double>? reveal = this.reveal;
    if (reveal == null) {
      return line(1);
    }
    return AnimatedBuilder(
      animation: reveal,
      builder: (final context, final _) => line(reveal.value),
    );
  }
}

/// Bugünün tarih/saatini biletin "SEANS" alanı için yazar (gerçek veri).
String ticketDate(final DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String ticketTime(final DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
