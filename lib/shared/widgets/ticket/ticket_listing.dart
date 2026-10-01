import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/shows/domain/entities/show.dart';
import '../background/shimmer_components.dart';
import '../optimized_cached_image.dart';
import 'ticket_kit.dart';

/// "Bilet dili"nin LİSTE hâli — arama, keşif ve yakınımdakiler gibi hızlı
/// taranan ekranlar için yatay, kompakt bilet satırları.
///
/// - [ShowTicketRow]: bir oyun = gövdesinde afiş + ad olan, sağında barkodlu
///   koçanı olan küçük bir bilet (mobil arama sonuçları).
/// - [SessionTicketRow]: bir seans = solunda TARİH koçanı, gövdesinde oyun
///   adı + SAAT / FİYAT alanları olan bilet (yakınımdakiler, yaklaşan
///   seanslar).
/// - [TicketNotice]: boş/hata durumu — "iptal edilmiş" tek parça bilet,
///   ne olduğunu söyler ve TEK bir sonraki adım sunar.
///
/// Kağıt/mürekkep `TicketInk`'ten, vurgu temadan gelir (5 tema korunur).

const List<String> _kMonthsShort = [
  'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', //
  'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
];

const List<String> _kWeekdaysShort = [
  'PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ', //
];

/// "EKİ" gibi büyük harf kısa ay adı (bilet alanı için).
String ticketMonthShort(final DateTime d) => _kMonthsShort[d.month - 1];

/// "CMT" gibi büyük harf kısa gün adı (bilet alanı için).
String ticketWeekdayShort(final DateTime d) => _kWeekdaysShort[d.weekday - 1];

/// `Event.price` gibi serbest metin fiyatı bilete basılacak biçime çevirir
/// ("250" → "₺250", "249.9" → "₺249,90"). Sayı değilse ya da 0 ise `null`
/// döner — uydurma bir fiyat yazılmaz, alan hiç gösterilmez.
String? ticketPrice(final String raw) {
  final double? value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  if (value == value.roundToDouble()) return '₺${value.round()}';
  return '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

// ─────────────────────────────────────────────────────────────────────────
// Ortak: iki parçalı yatay bilet (gövde + koçan) ve etkileşim kabuğu
// ─────────────────────────────────────────────────────────────────────────

/// Yatay iki parçalı bilet: [leading] parça solda, [trailing] sağda, arada
/// delik çizgisi. [stubOnLeft] true ise koçan (dar parça) soldadır.
class _HorizontalTicket extends StatelessWidget {
  final double height;
  final double stubWidth;
  final bool stubOnLeft;
  final Widget stub;
  final Widget body;
  final List<BoxShadow> shadows;

  const _HorizontalTicket({
    required this.height,
    required this.stubWidth,
    required this.stubOnLeft,
    required this.stub,
    required this.body,
    required this.shadows,
  });

  @override
  Widget build(final BuildContext context) {
    const double notch = 8;
    final Widget stubPiece = SizedBox(
      width: stubWidth,
      child: TicketPiece(
        perforated: stubOnLeft ? TicketEdge.right : TicketEdge.left,
        notch: notch,
        corner: AppRadius.sm,
        shadows: shadows,
        child: stub,
      ),
    );
    final Widget bodyPiece = Expanded(
      child: TicketPiece(
        perforated: stubOnLeft ? TicketEdge.left : TicketEdge.right,
        notch: notch,
        corner: AppRadius.sm,
        shadows: shadows,
        child: body,
      ),
    );

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stubOnLeft
                ? [stubPiece, bodyPiece]
                : [bodyPiece, stubPiece],
          ),
          Positioned(
            top: 0,
            bottom: 0,
            width: 2,
            left: stubOnLeft ? stubWidth - 1 : null,
            right: stubOnLeft ? null : stubWidth - 1,
            child: const TicketPerforation(axis: Axis.vertical),
          ),
        ],
      ),
    );
  }
}

/// Hover/klavye odağında hafif kalkan, odakta temanın vurgusuyla görünür bir
/// çerçeve çizen dokunma kabuğu. Sıçrama (splash) yok — bilet kağıdı
/// "basılır", mürekkep dağılmaz.
class _TicketTapShell extends StatefulWidget {
  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget Function(bool active) builder;

  const _TicketTapShell({
    required this.semanticsLabel,
    required this.onTap,
    required this.builder,
  });

  @override
  State<_TicketTapShell> createState() => _TicketTapShellState();
}

class _TicketTapShellState extends State<_TicketTapShell> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final Color focusRing = Theme.of(context).colorScheme.primary;
    final bool active = _hovered || _focused;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
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
          borderRadius: BorderRadius.circular(AppRadius.sm + 3),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm + 3),
              border: Border.all(
                color: _focused ? focusRing : Colors.transparent,
                width: 2,
              ),
            ),
            child: AnimatedSlide(
              offset: active ? const Offset(0, -0.02) : Offset.zero,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: widget.builder(active),
            ),
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _ticketShadows(final bool active) => active
    ? AppShadows.level3(TicketInk.ink)
    : AppShadows.level1(TicketInk.ink);

// ─────────────────────────────────────────────────────────────────────────
// Oyun satırı
// ─────────────────────────────────────────────────────────────────────────

/// Kompakt oyun bileti — mobil arama/keşif listeleri için. Gövdede gerçek
/// afiş + oyun adı + tür/süre, sağdaki koçanda oyuna özgü barkod. Bilet
/// satışı başka platformdaysa bu, gövdede vurgu renginde yazılır.
class ShowTicketRow extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const ShowTicketRow({super.key, required this.show, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final String category = show.category.trim();
    final String duration = show.duration.trim();
    final String meta = [
      if (category.isNotEmpty) category,
      if (duration.isNotEmpty) duration,
    ].join(', ');

    return _TicketTapShell(
      semanticsLabel: [
        show.name,
        if (meta.isNotEmpty) meta,
        if (show.hasExternalTicketing) 'biletler başka platformda',
      ].join(', '),
      onTap: onTap,
      builder: (final active) => _HorizontalTicket(
        height: 96,
        stubWidth: 48,
        stubOnLeft: false,
        shadows: _ticketShadows(active),
        stub: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2, vertical: AppSpacing.md),
          child: TicketBarcode(
            seed: show.id,
            height: 20,
            direction: Axis.vertical,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs / 2),
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: ColoredBox(
                    color: TicketInk.inkSoft(0.08),
                    child: OptimizedCachedImage(
                      imageUrl: show.imageUrl,
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: TicketInk.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TicketInk.inkSoft(0.62),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (show.hasExternalTicketing) ...[
                      const SizedBox(height: 3),
                      Text(
                        'BİLETLER BAŞKA PLATFORMDA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TicketInk.label(
                                color: TicketInk.accentOf(context))
                            .copyWith(fontSize: 9, letterSpacing: 1.4),
                      ),
                    ],
                  ],
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
// Seans satırı
// ─────────────────────────────────────────────────────────────────────────

/// Bir seansın bileti: solda TARİH koçanı (gün adı, gün, ay), gövdede oyun
/// adı ve SAAT / FİYAT alanları. Tüm değerler gerçek etkinlik verisinden
/// gelir; fiyat okunamıyorsa (bkz. [ticketPrice]) alan hiç basılmaz.
class SessionTicketRow extends StatelessWidget {
  final String title;
  final DateTime dateTime;
  final String? price;

  /// Opsiyonel ek bilet alanı (ör. `SAHNE` → sahne adı). Seanslar zaten
  /// sahneye göre gruplandıysa boş bırakılır.
  final String? extraLabel;
  final String? extraValue;
  final VoidCallback onTap;

  const SessionTicketRow({
    super.key,
    required this.title,
    required this.dateTime,
    required this.onTap,
    this.price,
    this.extraLabel,
    this.extraValue,
  });

  @override
  Widget build(final BuildContext context) {
    final String time = ticketTime(dateTime);
    final bool hasExtra = extraLabel != null &&
        extraValue != null &&
        extraValue!.trim().isNotEmpty;

    return _TicketTapShell(
      semanticsLabel: [
        title,
        '${dateTime.day} ${ticketMonthShort(dateTime)} ${ticketWeekdayShort(dateTime)}, saat $time',
        if (price != null) 'fiyat $price',
        if (hasExtra) '$extraLabel ${extraValue!}',
      ].join(', '),
      onTap: onTap,
      builder: (final active) => _HorizontalTicket(
        height: 88,
        stubWidth: 72,
        stubOnLeft: true,
        shadows: _ticketShadows(active),
        stub: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ticketWeekdayShort(dateTime),
                style: TicketInk.label().copyWith(fontSize: 9)),
            Text(
              dateTime.day.toString(),
              style: GoogleFonts.playfairDisplay(
                color: TicketInk.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              ticketMonthShort(dateTime),
              style: TicketInk.label(color: TicketInk.accentOf(context))
                  .copyWith(fontSize: 10),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: TicketInk.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        TicketField(label: 'SAAT', value: time),
                        if (price != null) ...[
                          const SizedBox(width: AppSpacing.lg),
                          TicketField(label: 'FİYAT', value: price!),
                        ],
                        if (hasExtra) ...[
                          const SizedBox(width: AppSpacing.lg),
                          Flexible(
                            child: TicketField(
                                label: extraLabel!, value: extraValue!.trim()),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: TicketInk.inkSoft(0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Boş / hata bildirimi
// ─────────────────────────────────────────────────────────────────────────

/// Boş sonuç ya da hata: tek parça, koçanı kopmuş bir bilet. Ne olduğunu
/// söyler ([title] + [message]) ve TEK bir sonraki adım sunar ([actionLabel]).
class TicketNotice extends StatelessWidget {
  final String label;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const TicketNotice({
    super.key,
    required this.label,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
        container: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TicketPiece(
            perforated: TicketEdge.bottom,
            notch: 10,
            shadows: AppShadows.level2(TicketInk.ink),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
                  AppSpacing.xl, AppSpacing.xl + AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TicketInk.label()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title, style: TicketInk.headline(22)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    style: TextStyle(
                      color: TicketInk.inkSoft(0.72),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TicketStampButton(
                      label: actionLabel!,
                      onTap: onAction,
                      leading: actionIcon == null ? null : Icon(actionIcon),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// İskeletler
// ─────────────────────────────────────────────────────────────────────────

/// Bilet satırı yüksekliğinde iskelet (yükleniyor).
class TicketRowSkeleton extends StatelessWidget {
  final double height;
  const TicketRowSkeleton({super.key, this.height = 96});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: ShimmerLoading(
          width: double.infinity,
          height: height,
          borderRadius: AppRadius.sm,
        ),
      );
}

/// Izgara hücresini dolduran iskelet (oyun kartı yerine).
class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: ShimmerLoading(
          width: double.infinity,
          height: double.infinity,
          borderRadius: AppRadius.sm,
        ),
      );
}
