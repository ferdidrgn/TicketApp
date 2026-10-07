import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/events/domain/repositories/event_repository.dart'
    show kAdminBlockCustomerId;
import 'ticket_kit.dart';

/// "BİLET DİLİ" — koltuk planı. Salon, basılı bir oturma planıdır:
/// fildişi kağıt üstünde mürekkep koltuklar, üstte kavisli SAHNE çizgisi.
/// Koltuk silüeti giriş ekranındaki SMS kodu koltuk sırasıyla
/// (`SeatRowCodeInput`) aynıdır: üst köşeler yuvarlak sırt, alt düz oturak.
///
/// Kağıt ve mürekkep sabit (fiziksel nesne); SEÇİLİ koltuk temanın vurgu
/// rengindedir (`TicketInk.accentOf`) — 5 tema ve özel vurgu yansır.
/// Koltuk planı hem kullanıcının koltuk seçimi (`SeatSelectionPage`) hem de
/// yönetici denetim ekranı (`CuratorSeatingAuditPage`) tarafından kullanılır.

// ─────────────────────────────────────────────────────────────────────────
// Koltuk durumu
// ─────────────────────────────────────────────────────────────────────────

/// Bir koltuğun ekranda görünen durumu. Veri modeli sadece
/// 'available' | 'reserved' | 'sold' bilir; buradaki ayrım `customerId`'den
/// türetilir (uydurma durum yok):
/// - [selected]: bu kullanıcının 'reserved' tuttuğu koltuk
/// - [held]: başka birinin 'reserved' tuttuğu koltuk
/// - [owned]: bu kullanıcının zaten satın aldığı ('sold') koltuk
/// - [blocked]: yönetici tarafından kapatılmış koltuk ('sold' +
///   `kAdminBlockCustomerId`)
enum SeatVisual { available, selected, held, sold, blocked, owned }

extension SeatVisualLabel on SeatVisual {
  /// Kısa, kullanıcı dilinde durum adı (lejant + ekran okuyucu).
  String get label => switch (this) {
        SeatVisual.available => 'Müsait',
        SeatVisual.selected => 'Seçtiğin',
        SeatVisual.held => 'Başkası seçiyor',
        SeatVisual.sold => 'Satıldı',
        SeatVisual.blocked => 'Kapalı',
        SeatVisual.owned => 'Biletin var',
      };
}

/// Ham koltuk verisinden ekran durumunu çıkarır. [customerId] boşsa
/// (misafir) hiçbir koltuk "senin" sayılmaz.
SeatVisual seatVisualOf({
  required final String status,
  required final String? ownerId,
  required final String customerId,
}) {
  final bool mine = customerId.isNotEmpty && ownerId == customerId;
  switch (status) {
    case 'sold':
      if (ownerId == kAdminBlockCustomerId) return SeatVisual.blocked;
      return mine ? SeatVisual.owned : SeatVisual.sold;
    case 'reserved':
      return mine ? SeatVisual.selected : SeatVisual.held;
    default:
      return SeatVisual.available;
  }
}

/// "A12" → "A"
String seatRowOf(final String seatId) =>
    seatId.replaceAll(RegExp(r'[0-9]'), '');

/// "A12" → "12"
String seatNumberOf(final String seatId) =>
    seatId.replaceAll(RegExp(r'[^0-9]'), '');

/// Koltuk kimliklerini sıra harfine göre gruplar; sıralar alfabetik,
/// koltuklar numaraya göre dizilir.
Map<String, List<String>> groupSeatsByRow(final Iterable<String> seatIds) {
  final Map<String, List<String>> rows = {};
  for (final id in seatIds) {
    rows.putIfAbsent(seatRowOf(id), () => []).add(id);
  }
  final sortedKeys = rows.keys.toList()..sort();
  return {
    for (final k in sortedKeys)
      k: (rows[k]!
        ..sort((final a, final b) => (int.tryParse(seatNumberOf(a)) ?? 0)
            .compareTo(int.tryParse(seatNumberOf(b)) ?? 0))),
  };
}

/// Türk lirası: 400 → "400 TL", 1250.5 → "1.250,50 TL".
String ticketPriceTl(final double value) {
  final bool whole = value == value.roundToDouble();
  final List<String> parts = value.toStringAsFixed(whole ? 0 : 2).split('.');
  final String digits = parts.first;
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0 && digits[i - 1] != '-') {
      out.write('.');
    }
    out.write(digits[i]);
  }
  return parts.length > 1 ? '$out,${parts[1]} TL' : '$out TL';
}

// ─────────────────────────────────────────────────────────────────────────
// Tek koltuk
// ─────────────────────────────────────────────────────────────────────────

class _SeatPaint {
  final Color fill;
  final Color border;
  final double borderWidth;
  final Color ink;
  const _SeatPaint(this.fill, this.border, this.borderWidth, this.ink);
}

BorderRadius _seatRadius(final double size) => BorderRadius.only(
      topLeft: Radius.circular(size * 0.34),
      topRight: Radius.circular(size * 0.34),
      bottomLeft: const Radius.circular(AppRadius.xs / 2),
      bottomRight: const Radius.circular(AppRadius.xs / 2),
    );

_SeatPaint _paintFor(
    final BuildContext context, final SeatVisual v, final bool lifted) {
  final Color accent = TicketInk.accentOf(context);
  return switch (v) {
    SeatVisual.available => _SeatPaint(
        lifted ? TicketInk.paper : TicketInk.paperShade,
        lifted ? accent : TicketInk.inkSoft(0.42),
        lifted ? 2 : 1.4,
        TicketInk.inkSoft(0.72)),
    SeatVisual.selected => _SeatPaint(
        lifted ? TicketInk.accentDeepOf(context) : accent,
        TicketInk.accentDeepOf(context),
        1.4,
        TicketInk.onAccentOf(context)),
    SeatVisual.held => _SeatPaint(TicketInk.inkSoft(0.13),
        TicketInk.inkSoft(0.22), 1.2, TicketInk.inkSoft(0.38)),
    SeatVisual.sold => _SeatPaint(
        TicketInk.inkSoft(0.58), Colors.transparent, 0, TicketInk.paper),
    SeatVisual.blocked => _SeatPaint(TicketInk.paperShade,
        TicketInk.inkSoft(0.32), 1.2, TicketInk.inkSoft(0.45)),
    SeatVisual.owned =>
      _SeatPaint(TicketInk.ink, accent, 2, TicketInk.paper),
  };
}

/// Plan üzerindeki tek koltuk. [onTap] null ise koltuk etkileşimsizdir
/// (satılmış / başkasında / kapalı). [busy] iken koltukta küçük bir
/// dönen gösterge görünür ve dokunma kapanır.
class TicketSeat extends StatefulWidget {
  final String seatId;
  final SeatVisual visual;
  final double size;
  final bool busy;
  final VoidCallback? onTap;

  /// Ekran okuyucu etiketi; verilmezse "A sırası, 12 numaralı koltuk,
  /// müsait" biçiminde üretilir.
  final String? semanticLabel;

  /// Yönetici ekranında "incelemede" gibi ek vurgu (vurgu rengi çerçeve).
  final bool outlined;

  const TicketSeat({
    super.key,
    required this.seatId,
    required this.visual,
    required this.size,
    this.busy = false,
    this.onTap,
    this.semanticLabel,
    this.outlined = false,
  });

  @override
  State<TicketSeat> createState() => _TicketSeatState();
}

class _TicketSeatState extends State<TicketSeat> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  String get _label {
    final String row = seatRowOf(widget.seatId);
    final String number = seatNumberOf(widget.seatId);
    return '$row sırası, $number numaralı koltuk, '
        '${widget.visual.label.toLowerCase()}';
  }

  @override
  Widget build(final BuildContext context) {
    final bool interactive = widget.onTap != null && !widget.busy;
    final bool lifted = interactive && (_hovered || _focused);
    final _SeatPaint p = _paintFor(context, widget.visual, lifted);
    final Color accent = TicketInk.accentOf(context);
    final double s = widget.size;
    final BorderRadius radius = _seatRadius(s);
    final Duration d = _reduceMotion ? Duration.zero : AppMotion.fast;
    final bool selected = widget.visual == SeatVisual.selected;

    Widget glyph;
    if (widget.busy) {
      glyph = SizedBox(
        width: s * 0.38,
        height: s * 0.38,
        child: CircularProgressIndicator(strokeWidth: 2, color: p.ink),
      );
    } else if (widget.visual == SeatVisual.owned) {
      glyph = Icon(Icons.check_rounded, size: s * 0.5, color: p.ink);
    } else if (widget.visual == SeatVisual.sold ||
        widget.visual == SeatVisual.blocked) {
      glyph = const SizedBox.shrink();
    } else {
      glyph = Text(
        seatNumberOf(widget.seatId),
        maxLines: 1,
        style: TextStyle(
          color: p.ink,
          fontSize: math.max(9, s * 0.3),
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    final Widget seat = AnimatedScale(
      scale: _pressed ? 0.92 : (selected ? 1.08 : 1),
      duration: d,
      curve: AppMotion.standard,
      child: AnimatedContainer(
        duration: d,
        curve: AppMotion.standard,
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: radius,
          border: p.borderWidth == 0
              ? null
              : Border.all(color: p.border, width: p.borderWidth),
          // Seçim: hafif, vurgu tonlu bir ışıma — tek geri bildirim anı.
          boxShadow:
              selected ? AppShadows.level1(accent) : AppShadows.level0,
        ),
        foregroundDecoration: (_focused && interactive) || widget.outlined
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                    color: widget.outlined ? accent : TicketInk.ink,
                    width: 2.2),
              )
            : null,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.visual == SeatVisual.blocked)
                CustomPaint(
                    painter: _HatchPainter(TicketInk.inkSoft(0.35))),
              Center(child: glyph),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: interactive,
      selected: selected,
      label: widget.semanticLabel ?? _label,
      excludeSemantics: true,
      onTap: interactive ? widget.onTap : null,
      child: Tooltip(
        message: '${widget.seatId} · ${widget.visual.label}',
        waitDuration: const Duration(milliseconds: 450),
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: interactive ? widget.onTap : null,
            onHover: (final v) => setState(() => _hovered = v),
            onFocusChange: (final v) => setState(() => _focused = v),
            onHighlightChanged: (final v) => setState(() => _pressed = v),
            canRequestFocus: interactive,
            mouseCursor: interactive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: seat,
          ),
        ),
      ),
    );
  }
}

/// Kapalı koltuk için çapraz tarama.
class _HatchPainter extends CustomPainter {
  final Color color;
  const _HatchPainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3;
    const double step = 6;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _HatchPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// Sahne çizgisi ve lejant
// ─────────────────────────────────────────────────────────────────────────

/// Planın üstündeki kavisli sahne kenarı ve "SAHNE" yazısı.
class SeatStageArc extends StatelessWidget {
  final double width;
  const SeatStageArc({super.key, required this.width});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: 40,
          child: CustomPaint(
            painter: const _StageEdgePainter(),
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: Text('SAHNE', style: TicketInk.label()),
            ),
          ),
        ),
      );
}

class _StageEdgePainter extends CustomPainter {
  const _StageEdgePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width, h = size.height;
    // Sahne ağzı: salona doğru hafifçe kavislenen kenar.
    final Path edge = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w / 2, h * 1.15, w, h * 0.55);
    final Path fill = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.55)
      ..quadraticBezierTo(w / 2, h * 1.15, 0, h * 0.55)
      ..close();
    canvas.drawPath(fill, Paint()..color = TicketInk.inkSoft(0.06));
    canvas.drawPath(
      edge,
      Paint()
        ..color = TicketInk.inkSoft(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

/// Koltuk durumları lejantı (kağıt üstünde). Sadece [visible] listesindeki
/// durumlar gösterilir — veride olmayan bir durum (ör. hiç kapalı koltuk
/// yoksa "Kapalı") lejantı kalabalıklaştırmaz.
class SeatLegend extends StatelessWidget {
  final List<SeatVisual> visible;
  final WrapAlignment alignment;

  const SeatLegend({
    super.key,
    required this.visible,
    this.alignment = WrapAlignment.center,
  });

  @override
  Widget build(final BuildContext context) => Wrap(
        alignment: alignment,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          for (final v in visible)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Swatch(visual: v),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  v.label,
                  style: TextStyle(
                    color: TicketInk.inkSoft(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      );
}

class _Swatch extends StatelessWidget {
  final SeatVisual visual;
  const _Swatch({required this.visual});

  @override
  Widget build(final BuildContext context) {
    const double s = 16;
    final _SeatPaint p = _paintFor(context, visual, false);
    final BorderRadius r = _seatRadius(s);
    return ExcludeSemantics(
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: r,
          border: p.borderWidth == 0
              ? null
              : Border.all(color: p.border, width: math.min(p.borderWidth, 1.4)),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: visual == SeatVisual.blocked
              ? CustomPaint(painter: _HatchPainter(TicketInk.inkSoft(0.35)))
              : (visual == SeatVisual.owned
                  ? Icon(Icons.check_rounded, size: 11, color: p.ink)
                  : null),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Salon planı: yerleşim, sığdırma, yakınlaştırma, klavye
// ─────────────────────────────────────────────────────────────────────────

/// Sıralar hâlinde koltuk planı. Koltuk boyutu mevcut genişliğe göre
/// [minSeat]–[maxSeat] arasında seçilir; salon en küçük boyutta bile
/// sığmıyorsa plan kaydırılabilir/yakınlaştırılabilir olur (iki parmak,
/// fare tekerleği) ve açılışta sahne ortada durur. Web'de koltuklar arasında
/// ok tuşlarıyla gezilir, Enter/Boşluk seçer.
class SeatHallPlan extends StatefulWidget {
  final Map<String, List<String>> rows;
  final Widget Function(BuildContext context, String seatId, double size)
      seatBuilder;
  final double minSeat;
  final double maxSeat;
  final double gap;
  final EdgeInsets padding;

  const SeatHallPlan({
    super.key,
    required this.rows,
    required this.seatBuilder,
    this.minSeat = 40,
    this.maxSeat = 46,
    this.gap = 6,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xl),
  });

  @override
  State<SeatHallPlan> createState() => _SeatHallPlanState();
}

class _SeatHallPlanState extends State<SeatHallPlan> {
  final TransformationController _transform = TransformationController();
  Size? _laidOutFor;

  static const double _labelWidth = 22;
  static const double _stageGap = AppSpacing.lg;

  static const Map<ShortcutActivator, Intent> _arrows = {
    SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
    SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowLeft):
        DirectionalFocusIntent(TraversalDirection.left),
    SingleActivator(LogicalKeyboardKey.arrowRight):
        DirectionalFocusIntent(TraversalDirection.right),
  };

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final int cols = widget.rows.values
        .fold<int>(0, (final m, final r) => math.max(m, r.length));
    final int rowCount = widget.rows.length;

    return LayoutBuilder(
      builder: (final context, final c) {
        final double chromeW =
            widget.padding.horizontal + 2 * (_labelWidth + widget.gap);
        final double fitSeat = cols == 0
            ? widget.maxSeat
            : (c.maxWidth - chromeW) / cols - widget.gap;
        final double seat =
            fitSeat.clamp(widget.minSeat, widget.maxSeat).toDouble();
        final double cell = seat + widget.gap;
        final double rowsW = cols * cell + 2 * (_labelWidth + widget.gap);
        final double hallW = rowsW + widget.padding.horizontal;
        final double hallH = widget.padding.vertical +
            40 +
            _stageGap +
            rowCount * cell * 1.08;

        final double viewW = c.maxWidth;
        final double viewH = c.maxHeight.isFinite ? c.maxHeight : hallH;
        final double contentW = math.max(viewW, hallW);
        final double contentH = math.max(viewH, hallH);

        // Salon ekrandan genişse açılışta sahneyi ortala (bir kez / boyut
        // değiştiğinde).
        final Size now = Size(viewW, viewH);
        if (_laidOutFor != now) {
          _laidOutFor = now;
          final double dx = hallW > viewW ? -(hallW - viewW) / 2 : 0;
          WidgetsBinding.instance.addPostFrameCallback((final _) {
            if (mounted) {
              _transform.value = Matrix4.translationValues(dx, 0, 0);
            }
          });
        }

        final Widget hall = Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeatStageArc(width: rowsW),
              const SizedBox(height: _stageGap),
              for (final entry in widget.rows.entries)
                Padding(
                  padding: EdgeInsets.only(bottom: cell * 0.08),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RowLabel(entry.key, width: _labelWidth),
                      SizedBox(width: widget.gap),
                      for (final id in entry.value)
                        Padding(
                          padding: EdgeInsets.all(widget.gap / 2),
                          child: widget.seatBuilder(context, id, seat),
                        ),
                      SizedBox(width: widget.gap),
                      _RowLabel(entry.key, width: _labelWidth),
                    ],
                  ),
                ),
            ],
          ),
        );

        final double fitScale =
            math.min(1.0, math.min(viewW / contentW, viewH / contentH));

        return Shortcuts(
          shortcuts: _arrows,
          child: FocusTraversalGroup(
            child: InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: math.max(0.4, fitScale),
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(AppSpacing.xxl),
              child: SizedBox(
                width: contentW,
                height: contentH,
                child: Align(alignment: Alignment.topCenter, child: hall),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String text;
  final double width;
  const _RowLabel(this.text, {required this.width});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TicketInk.label(color: TicketInk.inkSoft(0.5))
                .copyWith(fontSize: 11, letterSpacing: 0.5),
          ),
        ),
      );
}
