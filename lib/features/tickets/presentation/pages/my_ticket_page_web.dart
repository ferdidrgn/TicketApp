import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/calendar_description.dart';
import '../../../../core/util/calendar_picker.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_account_shell.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../providers/my_ticket_provider.dart';
import '../widgets/wallet_ticket.dart'
    show
        TicketSchedule,
        ticketPaidLabel,
        ticketSeatsLabel,
        ticketSeatsValue,
        ticketShowName;

/// BİLETLERİM — WEB. Hesap kabuğu içinde: Yaklaşan / Geçmiş sekmeleri, her
/// bilet gerçek bir giriş bileti (gövde + koçan, QR), bileti açma, takvime
/// ekleme ve yol tarifi; sağda yapışkan "sıradaki seans" özeti. Mobil
/// `MyTicketPage`'den AYRIDIR. Veri: `myTicketsProvider(userId)`.
class MyTicketPageWeb extends ConsumerStatefulWidget {
  final String userId;
  const MyTicketPageWeb({super.key, required this.userId});

  @override
  ConsumerState<MyTicketPageWeb> createState() => _MyTicketPageWebState();
}

class _MyTicketPageWebState extends ConsumerState<MyTicketPageWeb> {
  bool _showPast = false;
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static String _fold(final String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static List<DetailedTicket> _sorted(
      final List<DetailedTicket> list, final bool descending) {
    final List<DetailedTicket> out = List.of(list);
    out.sort((final a, final b) {
      final DateTime? x = TicketSchedule.of(a).at;
      final DateTime? y = TicketSchedule.of(b).at;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return descending ? y.compareTo(x) : x.compareTo(y);
    });
    return out;
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final async = ref.watch(myTicketsProvider(widget.userId));
    final List<DetailedTicket>? all = async.value;
    final List<DetailedTicket> upcoming =
        all == null ? const [] : _sorted(all.upcoming, false);
    final List<DetailedTicket> past =
        all == null ? const [] : _sorted(all.past, true);

    final String q = _fold(_query.text.trim());
    List<DetailedTicket> visible(final List<DetailedTicket> l) => q.isEmpty
        ? l
        : l
            .where((final t) =>
                _fold(t.showTitle).contains(q) ||
                _fold(t.stageTitle).contains(q))
            .toList();

    final Widget body;
    if (async.isLoading && all == null) {
      body = const _Skeleton();
    } else if (all == null) {
      body = WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Biletlerin yüklenemedi',
        message: 'Biletlerine şu an ulaşamadık; satın aldıkların silinmedi. '
            'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(myTicketsProvider(widget.userId)),
      );
    } else if (all.isEmpty) {
      body = WebStatePanel(
        icon: Icons.confirmation_number_outlined,
        title: 'Henüz biletin yok',
        message: 'Bir oyun seç, koltuğunu ayır; biletin burada, girişte '
            'göstereceğin QR koduyla seni bekler.',
        actionLabel: 'Oyunlara göz at',
        onAction: () => NavigationHandler.goToDiscover(context),
      );
    } else {
      final List<DetailedTicket> list = visible(_showPast ? past : upcoming);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              SkChip(
                label: 'Yaklaşan',
                count: upcoming.length,
                selected: !_showPast,
                onTap: () => setState(() => _showPast = false),
              ),
              SkChip(
                label: 'Geçmiş',
                count: past.length,
                selected: _showPast,
                onTap: () => setState(() => _showPast = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (list.isEmpty)
            WebStatePanel(
              icon: q.isNotEmpty
                  ? Icons.search_off_rounded
                  : (_showPast
                      ? Icons.history_rounded
                      : Icons.event_busy_outlined),
              title: q.isNotEmpty
                  ? 'Sonuç yok'
                  : (_showPast
                      ? 'Henüz geçmiş biletin yok'
                      : 'Yaklaşan biletin yok'),
              message: q.isNotEmpty
                  ? 'Bu aramaya uyan bilet bulunamadı.'
                  : (_showPast
                      ? 'İzlediğin oyunların biletleri seanstan sonra burada '
                          'saklanır.'
                      : 'Yeni bir oyun seçtiğinde biletin burada, QR koduyla '
                          'seni bekler.'),
              actionLabel: q.isEmpty && !_showPast ? 'Oyunlara göz at' : null,
              onAction: q.isEmpty && !_showPast
                  ? () => NavigationHandler.goToDiscover(context)
                  : null,
            )
          else
            for (int i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xxl),
              _WebTicket(
                key: ValueKey('web-ticket-${list[i].ticket.id}'),
                ticket: list[i],
                onOpen: () => _open(list[i]),
              ),
            ],
        ],
      );
    }

    final String subtitle = all == null || all.isEmpty
        ? 'Girişte göstereceğin QR kodlu biletlerin burada.'
        : (upcoming.isEmpty
            ? 'Yaklaşan biletin yok; ${past.length} geçmiş bilet.'
            : '${upcoming.length} yaklaşan, ${past.length} geçmiş bilet.');

    return WebAccountShell(
      current: WebAccountSection.tickets,
      title: 'Biletlerim',
      subtitle: subtitle,
      headerTrailing: all == null || all.isEmpty
          ? null
          : SizedBox(
              width: 280,
              child: TextField(
                controller: _query,
                onChanged: (final _) => setState(() {}),
                style: Sk.ui(context, size: 14, weight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Oyun ya da sahne ara',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Aramayı temizle',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(_query.clear),
                        ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
      aside: all == null || all.isEmpty
          ? null
          : _Aside(
              next: upcoming.isEmpty ? null : upcoming.first,
              upcoming: upcoming.length,
              past: past.length,
              all: all,
              onOpen: _open,
            ),
      child: body,
    );
  }

  void _open(final DetailedTicket t) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (final _) => _TicketDialog(ticket: t),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Eylemler (liste, özet ve pencere ortak)
// ─────────────────────────────────────────────────────────────────────────

bool _canAddToCalendar(final DetailedTicket t) =>
    !t.isPast && TicketSchedule.of(t).at != null;

void _addToCalendar(final BuildContext context, final DetailedTicket t) {
  final DateTime? at = TicketSchedule.of(t).at;
  if (at == null) return;
  showAddToCalendarMenu(
    context,
    CalendarEventData.forShow(
      showName: t.showTitle,
      start: at,
      duration: t.show?.duration ?? '',
      location: t.stage?.address ?? t.stageTitle,
      description: calendarDescription(
        showId: t.ticket.showId,
        showName: t.showTitle,
        eventId: t.ticket.eventId,
        venue: t.stageTitle,
        seats: t.ticket.buySeats,
        ticketId: t.ticket.id,
      ),
    ),
    native: !kIsWeb,
  );
}

VoidCallback? _directionsAction(final DetailedTicket t) {
  final String query = [t.stageTitle, t.stage?.address ?? '']
      .where((final s) => s.trim().isNotEmpty)
      .join(', ');
  if (query.isEmpty) return null;
  return () => TiyatrolCommunicationActions.openAddressOnGoogleMaps(query);
}

String? _countdown(final DetailedTicket t) {
  final DateTime? at = TicketSchedule.of(t).at;
  if (at == null || t.isPast) return null;
  final DateTime now = DateTime.now();
  final int days = DateTime(at.year, at.month, at.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  if (days <= 0) return 'Bugün';
  if (days == 1) return 'Yarın';
  return '$days gün kaldı';
}

String _serial(final String id) =>
    id.length > 10 ? id.substring(0, 10).toUpperCase() : id.toUpperCase();

Widget _qr(final String data, final double size) => Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: TicketInk.inkSoft(0.15)),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle:
            const QrEyeStyle(eyeShape: QrEyeShape.square, color: TicketInk.ink),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: TicketInk.ink),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────
// Bilet
// ─────────────────────────────────────────────────────────────────────────

class _WebTicket extends StatelessWidget {
  final DetailedTicket ticket;
  final VoidCallback onOpen;

  const _WebTicket({super.key, required this.ticket, required this.onOpen});

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final box) {
          final bool wide = box.maxWidth >= 600;
          return AdmitTicket(
            direction: wide ? Axis.horizontal : Axis.vertical,
            stubExtent: 188,
            shadows: AppShadows.level2(TicketInk.ink),
            body: _TicketBody(ticket: ticket, onOpen: onOpen, compact: !wide),
            stub: _TicketStub(ticket: ticket, wide: wide, onOpen: onOpen),
          );
        },
      );
}

class _TicketBody extends StatelessWidget {
  final DetailedTicket ticket;
  final VoidCallback onOpen;
  final bool compact;

  const _TicketBody(
      {required this.ticket, required this.onOpen, required this.compact});

  @override
  Widget build(final BuildContext context) {
    final TicketSchedule s = TicketSchedule.of(ticket);
    final bool past = ticket.isPast;
    final String? left = _countdown(ticket);
    final VoidCallback? directions = _directionsAction(ticket);
    final bool hasShow = ticket.show != null;
    final bool hasStage = ticket.stage != null;
    final String image = ticket.posterUrl;

    return Opacity(
      opacity: past ? 0.78 : 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TicketHeaderStrip(
                kind: past ? 'SEANS GEÇTİ' : 'GİRİŞ BİLETİ'),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: SkImage(
                    url: image,
                    width: compact ? 64 : 84,
                    height: compact ? 90 : 116,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticketShowName(ticket),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TicketInk.headline(compact ? 20 : 24)),
                      if (ticket.stageTitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 15, color: TicketInk.inkSoft(0.6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(ticket.stageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: TicketInk.inkSoft(0.75),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                      if (left != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(left,
                            style: TextStyle(
                                color: TicketInk.accentDeepOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.md,
              children: [
                TicketField(label: 'TARİH', value: s.date),
                TicketField(label: 'SAAT', value: s.time),
                TicketField(
                    label: ticketSeatsLabel(ticket),
                    value: ticketSeatsValue(ticket)),
                TicketField(
                    label: 'ÖDENEN',
                    value: ticketPaidLabel(ticket.ticket.orderPrice)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                TicketTextLink(
                    label: 'Bileti aç', emphasize: true, onTap: onOpen),
                if (_canAddToCalendar(ticket))
                  Builder(
                    builder: (final ctx) => TicketTextLink(
                      label: 'Takvime ekle',
                      onTap: () => _addToCalendar(ctx, ticket),
                    ),
                  ),
                if (directions != null)
                  TicketTextLink(label: 'Yol tarifi', onTap: directions),
                if (hasShow)
                  TicketTextLink(
                    label: 'Oyunu gör',
                    onTap: () => NavigationHandler.goToShow(
                        context, ticket.show!.id, ticket.show!.name),
                  ),
                if (hasStage)
                  TicketTextLink(
                    label: 'Mekânı gör',
                    onTap: () => NavigationHandler.goToStage(
                        context, ticket.stage!.id, ticket.stage!.name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStub extends StatelessWidget {
  final DetailedTicket ticket;
  final bool wide;
  final VoidCallback onOpen;

  const _TicketStub(
      {required this.ticket, required this.wide, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final bool past = ticket.isPast;
    final String id = ticket.ticket.id;
    final Widget qr = Semantics(
      button: true,
      image: true,
      label: past
          ? 'Bilet QR kodu. Bu seans geçti.'
          : 'Bilet QR kodu, büyütmek için dokun',
      child: PressScale(
        onTap: onOpen,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: past ? 0.3 : 1, child: _qr(id, wide ? 112 : 120)),
            if (past)
              const ExcludeSemantics(
                child: TicketInkStamp(
                  text: 'OYNANDI',
                  appear: AlwaysStoppedAnimation<double>(1),
                ),
              ),
          ],
        ),
      ),
    );
    final Widget serial = SelectableText(
      'No. ${_serial(id)}',
      style: GoogleFonts.robotoMono(
        color: TicketInk.inkSoft(0.7),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(past ? 'SEANS GEÇTİ' : 'GİRİŞTE GÖSTER',
                style: TicketInk.label()),
            const SizedBox(height: AppSpacing.md),
            qr,
            const SizedBox(height: AppSpacing.md),
            serial,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          qr,
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(past ? 'SEANS GEÇTİ' : 'GİRİŞTE GÖSTER',
                    style: TicketInk.label()),
                const SizedBox(height: AppSpacing.sm),
                serial,
                const SizedBox(height: AppSpacing.md),
                const TicketBarcode(seed: 'stub', height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bileti aç penceresi
// ─────────────────────────────────────────────────────────────────────────

class _TicketDialog extends StatelessWidget {
  final DetailedTicket ticket;
  const _TicketDialog({required this.ticket});

  @override
  Widget build(final BuildContext context) {
    final TicketSchedule s = TicketSchedule.of(ticket);
    final bool past = ticket.isPast;
    final VoidCallback? directions = _directionsAction(ticket);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AdmitTicket(
                direction: Axis.vertical,
                shadows: AppShadows.level2(TicketInk.ink),
                body: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TicketHeaderStrip(
                          kind: past ? 'SEANS GEÇTİ' : 'GİRİŞ BİLETİ'),
                      const SizedBox(height: AppSpacing.lg),
                      Text(ticketShowName(ticket),
                          style: TicketInk.headline(26)),
                      if (ticket.stageTitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(ticket.stageTitle,
                            style: TextStyle(
                                color: TicketInk.inkSoft(0.75),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.xxl,
                        runSpacing: AppSpacing.md,
                        children: [
                          TicketField(label: 'TARİH', value: s.date),
                          TicketField(label: 'SAAT', value: s.time),
                          TicketField(
                              label: ticketSeatsLabel(ticket),
                              value: ticketSeatsValue(ticket)),
                          TicketField(
                              label: 'ÖDENEN',
                              value:
                                  ticketPaidLabel(ticket.ticket.orderPrice)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          if (_canAddToCalendar(ticket))
                            Builder(
                              builder: (final ctx) => TicketTextLink(
                                label: 'Takvime ekle',
                                emphasize: true,
                                onTap: () => _addToCalendar(ctx, ticket),
                              ),
                            ),
                          if (directions != null)
                            TicketTextLink(
                                label: 'Yol tarifi', onTap: directions),
                        ],
                      ),
                    ],
                  ),
                ),
                stub: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(past ? 'SEANS GEÇTİ' : 'GİRİŞTE GÖSTER',
                          style: TicketInk.label()),
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        image: true,
                        label: past
                            ? 'Bilet QR kodu. Bu seans geçti.'
                            : 'Bilet QR kodu, girişte görevliye göster',
                        child: Opacity(
                            opacity: past ? 0.35 : 1,
                            child: _qr(ticket.ticket.id, 196)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SelectableText(
                        'No. ${_serial(ticket.ticket.id)}',
                        style: GoogleFonts.robotoMono(
                          color: TicketInk.inkSoft(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        past
                            ? 'Bu bilet artık bir hatıra.'
                            : 'Görevli bu kodu okutur; ekran parlaklığını açık tut.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: TicketInk.inkSoft(0.65),
                            fontSize: 12,
                            height: 1.4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const TicketBarcode(seed: 'dialog', height: 34),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yapışkan özet
// ─────────────────────────────────────────────────────────────────────────

class _Aside extends StatelessWidget {
  final DetailedTicket? next;
  final int upcoming;
  final int past;
  final List<DetailedTicket> all;
  final ValueChanged<DetailedTicket> onOpen;

  const _Aside({
    required this.next,
    required this.upcoming,
    required this.past,
    required this.all,
    required this.onOpen,
  });

  double get _spent {
    double sum = 0;
    for (final DetailedTicket t in all) {
      sum += double.tryParse(t.ticket.orderPrice) ?? 0;
    }
    return sum;
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DetailedTicket? t = next;
    Widget stat(final String label, final String value) => Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Sk.ui(context,
                        size: 13.5,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600))),
            Text(value, style: Sk.ui(context, size: 14, weight: FontWeight.w800)),
          ],
        );
    return WebPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t == null ? 'ÖZET' : 'SIRADAKİ SEANS',
              style: Sk.ui(context,
                  size: 11,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w800,
                  letterSpacing: 1.8)),
          const SizedBox(height: AppSpacing.md),
          if (t != null) ...[
            Builder(builder: (final context) {
              final TicketSchedule s = TicketSchedule.of(t);
              final String? left = _countdown(t);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(ticketShowName(t),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context, size: 22, height: 1.12)),
                  const SizedBox(height: AppSpacing.xs),
                  if (left != null)
                    Text(left,
                        style: Sk.ui(context,
                            size: 14,
                            color: cs.primary,
                            weight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.md),
                  _line(context, Icons.event_outlined,
                      '${s.date} · ${s.time}'),
                  if (t.stageTitle.isNotEmpty)
                    _line(context, Icons.location_on_outlined, t.stageTitle),
                  _line(context, Icons.event_seat_outlined,
                      '${ticketSeatsLabel(t) == 'KOLTUKLAR' ? 'Koltuklar' : 'Koltuk'}: ${ticketSeatsValue(t)}'),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => onOpen(t),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Bileti aç'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (_canAddToCalendar(t))
                        Expanded(
                          child: Builder(
                            builder: (final ctx) => OutlinedButton(
                              onPressed: () => _addToCalendar(ctx, t),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                              child: const Text('Takvime ekle'),
                            ),
                          ),
                        ),
                      if (_canAddToCalendar(t) && _directionsAction(t) != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (_directionsAction(t) != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _directionsAction(t),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                            child: const Text('Yol tarifi'),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }),
            Divider(height: AppSpacing.xxxl, color: cs.outlineVariant),
          ],
          stat('Yaklaşan', '$upcoming'),
          const SizedBox(height: AppSpacing.sm),
          stat('Geçmiş', '$past'),
          if (_spent > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            stat('Toplam ödenen', ticketPaidLabel(_spent.toStringAsFixed(2))),
          ],
        ],
      ),
    );
  }

  Widget _line(final BuildContext context, final IconData icon, final String text) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: Sk.ui(context,
                    size: 13.5, weight: FontWeight.w600, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: Column(
          children: [
            SkBone(height: 250, radius: AppRadius.md),
            SizedBox(height: AppSpacing.xxl),
            SkBone(height: 250, radius: AppRadius.md),
          ],
        ),
      );
}
