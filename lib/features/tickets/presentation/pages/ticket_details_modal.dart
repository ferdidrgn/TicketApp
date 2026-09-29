import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/calendar_actions.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../providers/my_ticket_provider.dart';
import '../widgets/wallet_ticket.dart';

/// BİLET ANI — satın alınmış bilet, karanlık sahnede gerçek bir giriş
/// bileti olarak açılır: gövdede afiş, oyun, tarih, saat, sahne, koltuk,
/// tutar; koçanda girişte gösterilecek QR kodu (sahneye gelince yavaşça
/// belirir). Seansı geçmiş biletlerde koçan kopuk, QR soluk ve üstünde
/// "OYNANDI" damgası.
///
/// Mobil/tablet: alttan açılan tam boy sayfa (`TicketDetailsModal`, dikey
/// bilet, koçan altta). Masaüstü: tam ekran sahne (`TicketDetailsDialog`,
/// yatay bilet, koçan sağda).
class TicketDetailsModal extends StatelessWidget {
  final DetailedTicket ticket;

  const TicketDetailsModal({super.key, required this.ticket});

  @override
  Widget build(final BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (final _, final scrollController) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          child: TicketStage(
            child: _TicketMoment(
              ticket: ticket,
              wide: false,
              controller: scrollController,
            ),
          ),
        ),
      );
}

/// Masaüstü: bilet tam ekran karanlık sahnede, ortada yatay.
/// `showDialog(builder: (_) => TicketDetailsDialog(ticket: t))`.
class TicketDetailsDialog extends StatelessWidget {
  final DetailedTicket ticket;

  const TicketDetailsDialog({super.key, required this.ticket});

  @override
  Widget build(final BuildContext context) => Material(
        type: MaterialType.transparency,
        child: TicketStage(
          child: _TicketMoment(ticket: ticket, wide: true, controller: null),
        ),
      );
}

class _TicketMoment extends StatefulWidget {
  final DetailedTicket ticket;
  final bool wide;
  final ScrollController? controller;

  const _TicketMoment({
    required this.ticket,
    required this.wide,
    required this.controller,
  });

  @override
  State<_TicketMoment> createState() => _TicketMomentState();
}

class _TicketMomentState extends State<_TicketMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: AppMotion.standard));
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.85, curve: AppMotion.dramatic));
  late final Animation<double> _qr = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.5, 1.0, curve: AppMotion.standard));

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final t = widget.ticket;
    final bool wide = widget.wide;

    final Widget ticket = AdmitTicket(
      direction: wide ? Axis.horizontal : Axis.vertical,
      // Geçmiş seans: koçan delikten biraz kopmuş.
      tear: AlwaysStoppedAnimation<double>(t.isPast ? 0.06 : 0.0),
      stubExtent: 300,
      body: _MomentBody(ticket: t, wide: wide, headline: _headline),
      stub: _MomentStub(ticket: t, wide: wide, reveal: _qr),
    );

    final Widget animatedTicket = AnimatedBuilder(
      animation: _ticketIn,
      builder: (final context, final child) => Opacity(
        opacity: _ticketIn.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _ticketIn.value) * 48),
          child: child,
        ),
      ),
      child: ticket,
    );

    final Widget close = Semantics(
      label: 'Bileti kapat',
      button: true,
      excludeSemantics: true,
      child: IconButton(
        tooltip: 'Kapat',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded, color: TicketInk.paper),
        style: IconButton.styleFrom(
          backgroundColor: TicketInk.paper.withOpacity(0.08),
          minimumSize: const Size(48, 48),
        ),
      ),
    );

    if (wide) {
      return Stack(
        children: [
          // Sahneye (biletin dışına) tıklamak da kapatır.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.section, vertical: AppSpacing.section),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: animatedTicket,
                ),
              ),
            ),
          ),
          Positioned(top: AppSpacing.xl, right: AppSpacing.xl, child: close),
        ],
      );
    }

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.massive),
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Bileti kapatmak için aşağı sürükleyin',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TicketInk.paper.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
            close,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: animatedTicket,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Gövde
// ─────────────────────────────────────────────────────────────────────────

class _MomentBody extends StatelessWidget {
  final DetailedTicket ticket;
  final bool wide;
  final Animation<double> headline;

  const _MomentBody({
    required this.ticket,
    required this.wide,
    required this.headline,
  });

  @override
  Widget build(final BuildContext context) {
    final t = ticket;
    final TicketSchedule s = TicketSchedule.of(t);
    final String image = t.show?.imageUrl.trim() ?? '';
    final String stageName = t.stage?.name.trim() ?? '';
    final String address = t.stage?.address.trim() ?? '';
    final int count = t.ticket.buySeats.length;

    final Widget title = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headline,
        child: Text(
          ticketShowName(t),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TicketInk.headline(wide ? 40 : 30),
        ),
      ),
    );

    final Widget fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TicketField(
                label: s.weekday.isEmpty ? 'TARİH' : trUpper(s.weekday),
                value: s.date,
              ),
            ),
            Expanded(
              flex: 2,
              child: TicketField(label: 'SAAT', value: s.time),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TicketField(
                    label: 'SAHNE',
                    value: stageName.isEmpty ? '—' : stageName,
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TicketInk.inkSoft(0.6),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: TicketField(
                label: ticketSeatsLabel(t),
                value: ticketSeatsValue(t),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TicketField(
                label: 'ÖDENEN',
                value: ticketPaidLabel(t.ticket.orderPrice),
              ),
            ),
            Expanded(
              flex: 2,
              child: TicketField(
                label: 'ÖDEME',
                value: ticketPaymentLabel(t.ticket.orderMethod),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: wide
          ? const EdgeInsets.fromLTRB(AppSpacing.huge, AppSpacing.huge,
              AppSpacing.huge, AppSpacing.xxl)
          : const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TicketHeaderStrip(
            kind: count > 1 ? 'GİRİŞ BİLETİ · $count KİŞİ' : 'GİRİŞ BİLETİ',
          ),
          if (image.isNotEmpty) ...[
            SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: SizedBox(
                height: wide ? 180 : 150,
                width: double.infinity,
                child: ColoredBox(
                  color: TicketInk.inkSoft(0.08),
                  child: OptimizedCachedImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.xl),
          title,
          SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.xl),
          fields,
          const SizedBox(height: AppSpacing.lg),
          _TicketLinks(ticket: t, schedule: s),
        ],
      ),
    );
  }
}

/// Biletin altındaki sessiz bağlantılar (buton yığını yerine): oyun, mekân,
/// takvim. Sadece verisi olanlar görünür.
class _TicketLinks extends StatelessWidget {
  final DetailedTicket ticket;
  final TicketSchedule schedule;

  const _TicketLinks({required this.ticket, required this.schedule});

  @override
  Widget build(final BuildContext context) {
    final show = ticket.show;
    final stage = ticket.stage;
    final DateTime? eventDate = ticket.event != null
        ? DateFormatter.parseDateString(ticket.event!.date)
        : null;
    // Geçmiş bir etkinliği takvime eklemenin bir anlamı yok — sadece
    // yaklaşan, gerçek bir tarihi olan biletlerde gösterilir.
    final bool canAddToCalendar =
        !ticket.isPast && show != null && eventDate != null;

    if (show == null && stage == null) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (show != null)
          TicketTextLink(
            label: 'Oyunu gör',
            onTap: () {
              Navigator.pop(context);
              NavigationHandler.goToShow(context, show.id, show.name);
            },
          ),
        if (stage != null)
          TicketTextLink(
            label: 'Mekânı gör',
            onTap: () {
              Navigator.pop(context);
              NavigationHandler.goToStage(context, stage.id, stage.name);
            },
          ),
        if (canAddToCalendar)
          TicketTextLink(
            label: 'Takvime ekle',
            emphasize: true,
            onTap: () => TiyatrolCalendarActions.addShowEventToCalendar(
              showName: show!.name,
              eventStart: eventDate!,
              location: stage?.address ?? '',
              showDuration: show.duration,
              description: stage != null && stage.name.isNotEmpty
                  ? '${stage.name} — TiyatRol bileti'
                  : 'TiyatRol bileti',
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Koçan: QR
// ─────────────────────────────────────────────────────────────────────────

class _MomentStub extends StatelessWidget {
  final DetailedTicket ticket;
  final bool wide;
  final Animation<double> reveal;

  const _MomentStub({
    required this.ticket,
    required this.wide,
    required this.reveal,
  });

  @override
  Widget build(final BuildContext context) {
    final bool past = ticket.isPast;
    final String id = ticket.ticket.id;
    final String serial =
        id.length > 10 ? id.substring(0, 10).toUpperCase() : id.toUpperCase();
    final double qrSize = wide ? 196 : 184;

    // QR: siyah modül / beyaz zemin — tarayıcıların güvenilir okuması için
    // temadan bağımsız, en yüksek kontrast. Yük (payload) değişmedi:
    // biletin kimliği.
    final Widget qr = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: TicketInk.inkSoft(0.15)),
      ),
      child: QrImageView(
        data: id,
        version: QrVersions.auto,
        size: qrSize,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square, color: TicketInk.ink),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: TicketInk.ink),
      ),
    );

    final Widget revealedQr = AnimatedBuilder(
      animation: reveal,
      builder: (final context, final child) => Opacity(
        opacity: reveal.value,
        child: Transform.scale(scale: 0.86 + 0.14 * reveal.value, child: child),
      ),
      child: Semantics(
        image: true,
        label: past
            ? 'Bilet QR kodu. Bu seans geçti.'
            : 'Bilet QR kodu, girişte görevliye göster',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: past ? 0.3 : 1, child: qr),
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

    final Widget content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(past ? 'SEANS GEÇTİ' : 'GİRİŞTE GÖSTER',
              style: TicketInk.label()),
          const SizedBox(height: AppSpacing.md),
          revealedQr,
          const SizedBox(height: AppSpacing.md),
          Text(
            past
                ? 'Bu bilet artık bir hatıra.'
                : 'Görevli bu kodu okutur; ekran parlaklığını açık tut.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TicketInk.inkSoft(0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            'No. $serial',
            style: GoogleFonts.robotoMono(
              color: TicketInk.inkSoft(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      // Yatay bilette koçanın yüksekliği gövdeden gelir; kısa gövdede
      // taşmak yerine orantılı küçülür.
      child: wide
          ? Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(width: 260, child: content),
              ),
            )
          : content,
    );
  }
}
