import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/seat_plan.dart' show ticketPriceTl;
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../providers/my_ticket_provider.dart';

/// "BİLET DİLİ" — Biletlerim. Satın alınmış her bilet gerçek bir bilettir:
/// solda gövde (afiş, oyun, sahne, saat, koltuk), delik çizgisinin sağında
/// koçan (gün + ay + barkod). Seansı geçmiş biletlerde koçan delikten
/// hafifçe kopmuş durur ve gövdeye "OYNANDI" mürekkep damgası basılıdır —
/// sadece veri (`DetailedTicket.isPast`, gerçek seans tarihinden) bunu
/// söylüyorsa.

// ─────────────────────────────────────────────────────────────────────────
// Veri yardımcıları (sadece gösterim)
// ─────────────────────────────────────────────────────────────────────────

/// Türkçe büyük harf ("i" → "İ", "ı" → "I").
String trUpper(final String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

const List<String> _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Biletin seansı — gerçek `Event.date`'ten. Tarih ayrıştırılamazsa
/// alanlar "—" olur (uydurma tarih yok).
class TicketSchedule {
  final DateTime? at;
  final String day;
  final String month;
  final String weekday;
  final String date;
  final String time;

  const TicketSchedule._(
      this.at, this.day, this.month, this.weekday, this.date, this.time);

  factory TicketSchedule.of(final DetailedTicket t) {
    final String raw = t.event?.date ?? '';
    final DateTime? d = DateFormatter.parseDateString(raw);
    if (d == null) {
      return const TicketSchedule._(null, '—', '', '', '—', '—');
    }
    final info = DateFormatter.formatForEventCard(raw);
    return TicketSchedule._(
      d,
      info['day'] ?? '${d.day}',
      info['monthName'] ?? '',
      _weekdays[d.weekday - 1],
      '${info['day']} ${info['monthName']} ${d.year}',
      ticketTime(d),
    );
  }
}

String ticketShowName(final DetailedTicket t) {
  final name = t.show?.name.trim() ?? '';
  return name.isEmpty ? 'Oyun' : name;
}

String ticketSeatsLabel(final DetailedTicket t) =>
    t.ticket.buySeats.length > 1 ? 'KOLTUKLAR' : 'KOLTUK';

String ticketSeatsValue(final DetailedTicket t) =>
    t.ticket.buySeats.isEmpty ? '—' : t.ticket.buySeats.join(', ');

/// Kayıtlı ödeme yöntemi kodunu okunur hâle getirir ("card", "iban").
String ticketPaymentLabel(final String method) => switch (method) {
      'card' => 'Kart',
      'iban' => 'Havale / EFT',
      '' => '—',
      _ => method,
    };

/// Kayıtlı tutar ("400.00") → "400 TL"; sayı değilse olduğu gibi.
String ticketPaidLabel(final String orderPrice) {
  final double? v = double.tryParse(orderPrice);
  if (v == null) return orderPrice.isEmpty ? '—' : '$orderPrice TL';
  return ticketPriceTl(v);
}

// ─────────────────────────────────────────────────────────────────────────
// Cüzdandaki bilet
// ─────────────────────────────────────────────────────────────────────────

class WalletTicket extends StatefulWidget {
  final DetailedTicket ticket;
  final VoidCallback onTap;

  /// Geniş ekran: daha büyük afiş ve başlık, geniş koçan.
  final bool large;

  const WalletTicket({
    super.key,
    required this.ticket,
    required this.onTap,
    this.large = false,
  });

  @override
  State<WalletTicket> createState() => _WalletTicketState();
}

class _WalletTicketState extends State<WalletTicket> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final t = widget.ticket;
    final bool past = t.isPast;
    final bool large = widget.large;
    final TicketSchedule s = TicketSchedule.of(t);
    final double stubW = large ? 112 : 84;
    final bool active = _hovered || _focused;
    final Color shadowTint = Theme.of(context).colorScheme.shadow;
    final List<BoxShadow> shadows = active
        ? AppShadows.level3(shadowTint)
        : AppShadows.level1(shadowTint);
    final bool reduce = MediaQuery.of(context).disableAnimations;

    final String semantic = [
      past ? 'Geçmiş bilet' : 'Yaklaşan bilet',
      ticketShowName(t),
      if (s.at != null) '${s.day} ${s.month} ${s.weekday}, saat ${s.time}',
      if ((t.stage?.name ?? '').trim().isNotEmpty) t.stage!.name.trim(),
      if (t.ticket.buySeats.isNotEmpty)
        'koltuk ${t.ticket.buySeats.join(', ')}',
    ].join(', ');

    final Widget stub = TicketPiece(
      perforated: TicketEdge.left,
      shadows: shadows,
      child: _Stub(schedule: s, seed: t.ticket.id, past: past, large: large),
    );

    final Widget ticket = Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(right: stubW),
          child: TicketPiece(
            perforated: TicketEdge.right,
            shadows: shadows,
            child: _Body(ticket: t, schedule: s, large: large),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: stubW,
          // Geçmiş seans: koçan delikten kopmuş, hafifçe kaymış.
          child: past
              ? Opacity(
                  opacity: 0.85,
                  child: Transform.translate(
                    offset: const Offset(6, 5),
                    child: Transform.rotate(
                      angle: 0.045,
                      alignment: Alignment.topLeft,
                      child: stub,
                    ),
                  ),
                )
              : stub,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: stubW - 1,
          width: 2,
          child: const TicketPerforation(axis: Axis.vertical),
        ),
        if (past)
          Positioned(
            right: stubW + AppSpacing.lg,
            bottom: AppSpacing.md,
            child: const ExcludeSemantics(
              child: TicketInkStamp(
                text: 'OYNANDI',
                appear: AlwaysStoppedAnimation<double>(1),
              ),
            ),
          ),
        if (_focused)
          Positioned.fill(
            right: stubW,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.2),
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      button: true,
      label: semantic,
      hint: 'Bileti ve QR kodunu aç',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (final v) => setState(() => _hovered = v),
          onFocusChange: (final v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: AnimatedSlide(
            offset: active && !reduce ? const Offset(0, -0.02) : Offset.zero,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: ticket,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DetailedTicket ticket;
  final TicketSchedule schedule;
  final bool large;

  const _Body({
    required this.ticket,
    required this.schedule,
    required this.large,
  });

  static const List<double> _greyscale = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(final BuildContext context) {
    final bool past = ticket.isPast;
    final String image = ticket.show?.imageUrl.trim() ?? '';
    final String stage = ticket.stage?.name.trim() ?? '';
    final double posterW = large ? 88 : 64;
    final double posterH = large ? 120 : 88;

    Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: SizedBox(
        width: posterW,
        height: posterH,
        child: ColoredBox(
          color: TicketInk.inkSoft(0.08),
          child: image.isEmpty
              ? Icon(Icons.theater_comedy_rounded,
                  color: TicketInk.inkSoft(0.3), size: posterW * 0.4)
              : OptimizedCachedImage(
                  imageUrl: image,
                  width: posterW,
                  height: posterH,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                ),
        ),
      ),
    );
    if (past) {
      poster = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscale),
        child: poster,
      );
    }

    return Padding(
      padding: EdgeInsets.all(large ? AppSpacing.xl : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poster,
          SizedBox(width: large ? AppSpacing.xl : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticketShowName(ticket),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: past ? TicketInk.inkSoft(0.7) : TicketInk.ink,
                    fontSize: large ? 22 : 17,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                if (stage.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TicketInk.inkSoft(0.62),
                      fontSize: large ? 14 : 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: large ? AppSpacing.lg : AppSpacing.md),
                Row(
                  children: [
                    if (schedule.weekday.isNotEmpty) ...[
                      TicketField(
                        label: trUpper(schedule.weekday),
                        value: schedule.time,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                    ] else ...[
                      const TicketField(label: 'SAAT', value: '—'),
                      const SizedBox(width: AppSpacing.lg),
                    ],
                    Flexible(
                      child: TicketField(
                        label: ticketSeatsLabel(ticket),
                        value: ticketSeatsValue(ticket),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final TicketSchedule schedule;
  final String seed;
  final bool past;
  final bool large;

  const _Stub({
    required this.schedule,
    required this.seed,
    required this.past,
    required this.large,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schedule.day,
                      style: TicketInk.headline(large ? 38 : 30).copyWith(
                        color: past
                            ? TicketInk.inkSoft(0.55)
                            : TicketInk.accentOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.month.isEmpty
                          ? 'TARİH'
                          : trUpper(schedule.month),
                      style: TicketInk.label(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TicketBarcode(seed: seed, height: large ? 22 : 16),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Durumlar
// ─────────────────────────────────────────────────────────────────────────

/// Bilet şeklinde iskelet — yükleme sırasında spinner yerine.
class WalletTicketSkeleton extends StatelessWidget {
  final bool large;
  const WalletTicketSkeleton({super.key, this.large = false});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double h = large ? 160 : 116;
    Widget block(final double w, final double hh) => Container(
          width: w,
          height: hh,
          decoration: BoxDecoration(
            color: cs.onSurface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        );
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: SizedBox(
        height: h,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    block(large ? 88 : 64, double.infinity),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          block(180, 16),
                          const SizedBox(height: AppSpacing.sm),
                          block(110, 12),
                          const SizedBox(height: AppSpacing.lg),
                          block(140, 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: large ? 109 : 81,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boş ekran bir davettir: tek cümle + tek CTA.
class TicketsEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final bool showCta;

  const TicketsEmptyState({
    super.key,
    this.title = 'Henüz biletin yok',
    this.message =
        'Bir oyun seç, koltuğunu ayır; biletin burada, girişte göstereceğin '
            'QR koduyla seni bekler.',
    this.showCta = true,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Boş bilet: basılmamış bir koçan silüeti.
              ExcludeSemantics(
                child: SizedBox(
                  width: 160,
                  height: 72,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 44),
                        child: TicketPiece(
                          perforated: TicketEdge.right,
                          notch: 9,
                          shadows: AppShadows.level1(cs.shadow),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 44,
                        child: TicketPiece(
                          perforated: TicketEdge.left,
                          notch: 9,
                          shadows: AppShadows.level1(cs.shadow),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        bottom: 0,
                        right: 43,
                        width: 2,
                        child: TicketPerforation(axis: Axis.vertical),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (showCta) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => NavigationHandler.goToDiscover(context),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Oyunları keşfet'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hata: ne oldu + ne yapmalı + tekrar dene.
class TicketsErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const TicketsErrorState({super.key, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: cs.error),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  'Biletlerin yüklenemedi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: cs.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Biletlerin güvende; sadece şu an ulaşamadık. İnternet '
                'bağlantını kontrol edip yeniden dene.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
