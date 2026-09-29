import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import 'show_detail_data.dart';

/// Tek bir seans = yırtılabilir bir bilet koçanı.
///
/// Gövde: gün / ay / hafta günü + SAAT ve SAHNE alanları. Delik çizgisinin
/// sağındaki koçan: FİYAT + "KOLTUK SEÇ". Dokununca (ya da klavyeyle
/// Enter/Space) koçan delikten kopar ve mevcut koltuk seçimi akışına
/// gidilir. Azaltılmış harekette yırtılma oynatılmaz, doğrudan gidilir.
class ShowSessionTicket extends StatefulWidget {
  final ShowSession session;
  final VoidCallback onSelect;
  final bool compact;

  const ShowSessionTicket({
    super.key,
    required this.session,
    required this.onSelect,
    this.compact = false,
  });

  @override
  State<ShowSessionTicket> createState() => _ShowSessionTicketState();
}

class _ShowSessionTicketState extends State<ShowSessionTicket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  bool _hovered = false;
  bool _focused = false;
  bool _busy = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _tear.dispose();
    super.dispose();
  }

  Future<void> _select() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.selectionClick();
    if (!_reduceMotion) await _tear.forward(from: 0);
    if (!mounted) return;
    widget.onSelect();
    // Sayfa değişmediyse (ör. yönlendirme iptal olduysa) koçan geri yapışır.
    Future.delayed(AppMotion.slow, () {
      if (!mounted) return;
      _tear.value = 0;
      _busy = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final bool compact = widget.compact;
    final double stubWidth = compact ? 100 : 128;
    final bool active = _hovered || _focused;
    final List<BoxShadow> shadows = active
        ? AppShadows.level3(TicketInk.ink)
        : AppShadows.level1(TicketInk.ink);
    const double notch = 10;

    final Widget stub = AnimatedBuilder(
      animation: _tearCurve,
      builder: (final context, final child) {
        final double t = _tearCurve.value;
        if (t == 0) return child!;
        return Opacity(
          opacity: (1 - t * 1.1).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(t * 64, t * 36),
            child: Transform.rotate(
              angle: 0.18 * t,
              alignment: Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
      child: TicketPiece(
        perforated: TicketEdge.left,
        notch: notch,
        corner: AppRadius.sm,
        shadows: shadows,
        child: _SessionStub(session: widget.session, active: active),
      ),
    );

    final Widget ticket = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: EdgeInsets.only(right: stubWidth),
          child: TicketPiece(
            perforated: TicketEdge.right,
            notch: notch,
            corner: AppRadius.sm,
            shadows: shadows,
            child: _SessionBody(session: widget.session, compact: compact),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: stubWidth,
          child: stub,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: stubWidth - 1,
          width: 2,
          child: const TicketPerforation(axis: Axis.vertical),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: widget.session.semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _select,
          onHover: (final v) => setState(() => _hovered = v),
          onFocusChange: (final v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.all(3),
            // Görünür klavye odağı: biletin çevresinde temanın vurgusuyla
            // ince bir halka (fare hover'ında yok, sadece odakta).
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _focused ? context.colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: AnimatedSlide(
              offset: active && !_reduceMotion
                  ? const Offset(0, -0.02)
                  : Offset.zero,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: ticket,
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  final ShowSession session;
  final bool compact;

  const _SessionBody({required this.session, required this.compact});

  @override
  Widget build(final BuildContext context) {
    final DateTime? when = session.when;
    final Color accent = TicketInk.accentOf(context);

    final Widget dateBlock = SizedBox(
      width: compact ? 50 : 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            when == null ? '—' : '${when.day}',
            style: TicketInk.headline(compact ? 28 : 32).copyWith(height: 1),
          ),
          if (when != null) ...[
            const SizedBox(height: 4),
            Text(trMonthsShort[when.month - 1],
                style: TicketInk.label(color: accent)),
            const SizedBox(height: 2),
            Text(trWeekdaysShort[when.weekday - 1], style: TicketInk.label()),
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.md : AppSpacing.lg,
          AppSpacing.md + 2,
          AppSpacing.lg,
          AppSpacing.md + 2),
      child: Row(
        children: [
          dateBlock,
          SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
          Container(width: 1, height: 52, color: TicketInk.inkSoft(0.15)),
          SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (when != null)
                  TicketField(
                    label: 'SAAT',
                    value: '${hhmm(when)}  ${trWeekdays[when.weekday - 1]}',
                  )
                else
                  TicketField(label: 'TARİH', value: session.event.date.trim()),
                if (session.venueName.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TicketField(label: 'SAHNE', value: session.venueName),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionStub extends StatelessWidget {
  final ShowSession session;
  final bool active;

  const _SessionStub({required this.session, required this.active});

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    final String? price = session.priceLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (price != null) ...[
            TicketField(
              label: 'FİYAT',
              value: price,
              align: CrossAxisAlignment.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'KOLTUK SEÇ',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TicketInk.label(color: accent).copyWith(
                    fontSize: 9.5,
                    letterSpacing: 1.4,
                    decoration: active ? TextDecoration.underline : null,
                    decorationColor: accent,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}
