import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../../core/util/calendar_picker.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/sahne/sketch.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../tickets/presentation/pages/ticket_details_modal.dart';
import '../../../../tickets/presentation/providers/my_ticket_provider.dart';

/// Ana sayfanın en üstündeki "yaklaşan bilet" kartı — uçak/biniş kartı
/// düzeninde: üstte rozet + tarih, ortada saat → canlı geri sayım → koltuk,
/// altta bilet no ve gerçek eylemler (Bileti aç, Yol tarifi, Takvime ekle).
///
/// Hepsi kullanıcının GERÇEK bileti ve seansından; geri sayım saniyede bir
/// akar, perdeye yaklaştıkça ortadaki perde simgesi çizgi boyunca ilerler.
class BoardingPassCard extends StatefulWidget {
  final DetailedTicket ticket;
  final DateTime date;

  const BoardingPassCard({super.key, required this.ticket, required this.date});

  @override
  State<BoardingPassCard> createState() => _BoardingPassCardState();
}

class _BoardingPassCardState extends State<BoardingPassCard>
    with WidgetsBindingObserver {
  // Zamanlayıcı YOK: metin çizim anında hesaplanır; uygulama arka plandan
  // dönünce bir kez tazelenir (pil/performans için).
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Günün bölümü: sabah / öğle / öğleden sonra / akşam / gece.
  String _part(final DateTime d) {
    final int h = d.hour;
    if (h >= 5 && h < 11) return 'sabah';
    if (h >= 11 && h < 14) return 'öğle';
    if (h >= 14 && h < 18) return 'öğleden sonra';
    if (h >= 18 && h < 23) return 'akşam';
    return 'gece';
  }

  /// "3 gün kaldı", "yarın akşam", "bu akşam", "az kaldı"…
  String _phrase(final Duration left) {
    if (left.isNegative) return 'Perde açıldı';
    final DateTime today = skDay(_now);
    final int days = skDay(widget.date).difference(today).inDays;
    if (days <= 0) {
      if (left.inMinutes < 180) return 'Az kaldı';
      return 'Bu ${_part(widget.date)}';
    }
    if (days == 1) return 'Yarın ${_part(widget.date)}';
    if (days < 14) return '$days gün kaldı';
    if (days < 60) return '${(days / 7).round()} hafta kaldı';
    return '${(days / 30).round()} ay kaldı';
  }

  String _hint(final Duration left) {
    if (left.isNegative) return 'şimdi sahnede';
    final int days =
        skDay(widget.date).difference(skDay(_now)).inDays;
    if (days <= 0) return 'bugün';
    if (days == 1) return 'perdeye';
    return 'perdeye';
  }

  void _open() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketDetailsModal(ticket: widget.ticket),
    );
  }

  Future<void> _directions() async {
    final Stage? s = widget.ticket.stage;
    if (s == null) return;
    HapticFeedback.selectionClick();
    final bool hasGeo = !(s.locationLat == 0 && s.locationLng == 0);
    final Uri uri = hasGeo
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${s.locationLat},${s.locationLng}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${s.name} ${s.address}')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _calendar() async {
    await showAddToCalendarMenu(
      context,
      CalendarEventData.forShow(
        showName: widget.ticket.show?.name ?? 'Tiyatro',
        start: widget.date,
        duration: widget.ticket.show?.duration ?? '',
        location: [
          widget.ticket.stage?.name ?? '',
          widget.ticket.stage?.address ?? '',
        ].where((x) => x.trim().isNotEmpty).join(', '),
      ),
      native: !kIsWeb,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final show = widget.ticket.show!;
    final String venue = (widget.ticket.stage?.name ?? '').trim();
    final Duration left = widget.date.difference(_now);
    // 7 günlük pencerede ilerleme (yaklaştıkça perde simgesi sağa kayar).
    final double progress =
        (1 - left.inSeconds / const Duration(days: 7).inSeconds)
            .clamp(0.0, 1.0);
    final List<String> seats = widget.ticket.ticket.buySeats
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final String seatText = seats.isEmpty
        ? '—'
        : (seats.length == 1
            ? seats.first
            : '${seats.first} +${seats.length - 1}');
    final String id = widget.ticket.ticket.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final String code =
        (id.length > 6 ? id.substring(0, 6) : id).toUpperCase();

    final Color topBg = cs.primaryContainer;
    final Color botBg = cs.surfaceContainerLow;

    return Semantics(
      label:
          'Yaklaşan biletin: ${show.name}, ${skDayPhrase(widget.date)} ${skClock(widget.date)}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: skSoftShadow(context),
        ),
        child: Column(
          children: [
            // ── Üst bölüm ──
            ClipPath(
              clipper: _NotchClipper(top: true),
              child: PressScale(
                onTap: _open,
                scale: 0.99,
                semanticLabel: 'Bileti aç',
                child: Container(
                  color: topBg,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Yaklaşan',
                                style: Sk.ui(context,
                                    size: 12.5,
                                    color: cs.onPrimary,
                                    weight: FontWeight.w800)),
                          ),
                          const Spacer(),
                          Text(
                            '${widget.date.day} ${kMonthsTr[widget.date.month - 1]} ${widget.date.year}',
                            style: Sk.ui(context,
                                size: 13,
                                color: cs.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                                weight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skClock(widget.date),
                                  style: Sk.display(context,
                                      size: 34,
                                      height: 1.0,
                                      color: cs.onPrimaryContainer)),
                              const SizedBox(height: 4),
                              Text(kDaysTr[widget.date.weekday - 1],
                                  style: Sk.ui(context,
                                      size: 12.5,
                                      color: cs.onPrimaryContainer
                                          .withValues(alpha: 0.75),
                                      weight: FontWeight.w700)),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(_hint(left),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: Sketch.hand(context,
                                            size: 18,
                                            color: cs.onPrimaryContainer
                                                .withValues(alpha: 0.8))),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    height: 28,
                                    child: CustomPaint(
                                      painter: _RoutePainter(
                                        progress: progress,
                                        line: cs.onPrimaryContainer
                                            .withValues(alpha: 0.45),
                                        dot: cs.primary,
                                      ),
                                      child: Align(
                                        alignment: Alignment(
                                            -1 + 2 * progress, 0),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                              Icons.theater_comedy_rounded,
                                              size: 15,
                                              color: cs.onPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(_phrase(left),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: Sk.ui(context,
                                            size: 13.5,
                                            color: cs.onPrimaryContainer,
                                            weight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(seatText,
                                  style: Sk.display(context,
                                      size: 30,
                                      height: 1.0,
                                      color: cs.onPrimaryContainer)),
                              const SizedBox(height: 4),
                              Text('koltuk',
                                  style: Sk.ui(context,
                                      size: 12.5,
                                      color: cs.onPrimaryContainer
                                          .withValues(alpha: 0.75),
                                      weight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 21,
                              height: 1.1,
                              color: cs.onPrimaryContainer)),
                      if (venue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            venue,
                            if (show.category.trim().isNotEmpty)
                              show.category.trim(),
                          ].join('  •  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                              weight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // ── Alt bölüm ──
            ClipPath(
              clipper: _NotchClipper(top: false),
              child: CustomPaint(
                foregroundPainter: _DashPainter(
                    cs.onSurfaceVariant.withValues(alpha: 0.45)),
                child: Container(
                  color: botBg,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Bilet no',
                              style: Sk.ui(context,
                                  size: 12.5,
                                  color: cs.onSurfaceVariant,
                                  weight: FontWeight.w700)),
                          const Spacer(),
                          Text(code.isEmpty ? '—' : code,
                              style: Sk.ui(context,
                                  size: 14,
                                  weight: FontWeight.w900,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _open,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                              child: Text('Bileti aç',
                                  maxLines: 1,
                                  style: Sk.ui(context,
                                      size: 13,
                                      color: cs.onPrimary,
                                      weight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Mini(
                              icon: Icons.directions_rounded,
                              label: 'Yol tarifi',
                              onTap: widget.ticket.stage == null
                                  ? null
                                  : _directions),
                          const SizedBox(width: 8),
                          _Mini(
                              icon: Icons.event_available_rounded,
                              label: 'Takvime ekle',
                              onTap: _calendar),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Mini({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 48,
            height: 44,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon,
                size: 22,
                color: onTap == null
                    ? cs.onSecondaryContainer.withValues(alpha: 0.4)
                    : cs.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}

/// Üst bölümün alt kenarına / alt bölümün üst kenarına yarım daire oyuklar.
class _NotchClipper extends CustomClipper<Path> {
  final bool top;
  const _NotchClipper({required this.top});

  @override
  Path getClip(final Size size) {
    const double r = 28;
    const double n = 12;
    final Path base = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: top ? const Radius.circular(r) : Radius.zero,
        topRight: top ? const Radius.circular(r) : Radius.zero,
        bottomLeft: top ? Radius.zero : const Radius.circular(r),
        bottomRight: top ? Radius.zero : const Radius.circular(r),
      ));
    final double y = top ? size.height : 0;
    final Path holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: n))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: n));
    return Path.combine(PathOperation.difference, base, holes);
  }

  @override
  bool shouldReclip(covariant final _NotchClipper old) => old.top != top;
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = 22; x < size.width - 22; x += 9) {
      canvas.drawLine(Offset(x, 0.8), Offset(x + 4.5, 0.8), p);
    }
  }

  @override
  bool shouldRepaint(covariant final _DashPainter old) => old.color != color;
}

class _RoutePainter extends CustomPainter {
  final double progress;
  final Color line;
  final Color dot;
  const _RoutePainter(
      {required this.progress, required this.line, required this.dot});

  @override
  void paint(final Canvas canvas, final Size size) {
    final double y = size.height / 2;
    final Paint dash = Paint()
      ..color = line
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
    }
    // Kat edilen kısım dolu çizgi
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      Paint()
        ..color = dot
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant final _RoutePainter old) =>
      old.progress != progress || old.line != line || old.dot != dot;
}
