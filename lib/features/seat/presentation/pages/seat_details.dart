import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/ticket/seat_plan.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

/// KOLTUK SEÇİMİ — "bilet dili"nin en gerçek hâli: salon, basılı bir
/// oturma planıdır; seçim özeti biletin koçanıdır.
///
/// - Mobil (<768): plan kağıdı üstte (iki parmakla yakınlaştırılır), altta
///   delik çizgisiyle bağlı yapışkan koçan: seçilen koltuklar + toplam +
///   "Ödemeye geç".
/// - Tablet (768–1023): aynı dikey bilet, ortalanmış ve daha geniş koltuklar.
/// - Masaüstü (≥1024): yatay bilet — solda plan (gövde), sağda koçan
///   (oyun, tarih, sahne, koltuklar, toplam). Ödemeye geçerken koçan
///   delikten yırtılır; ödeme vazgeçilirse geri yapışır.
///
/// Koltuk/rezervasyon/satın alma mantığı önceki sürümle BİREBİR aynıdır.
class SeatSelectionPage extends ConsumerStatefulWidget {
  final String showId;
  final String eventId;
  final String customerId;

  const SeatSelectionPage({
    super.key,
    required this.showId,
    required this.eventId,
    required this.customerId,
  });

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage>
    with TickerProviderStateMixin {
  final Set<String> _processingSeats = {};

  // 🎉 Satın alma başarıyla tamamlandığında kısa bir kutlama patlaması için.
  late final ConfettiController _confettiController;

  /// Masaüstünde "Ödemeye geç" → koçan delikten kopar.
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  bool _reduceMotion = false;
  bool _purchaseInFlight = false;

  /// Liste parametreli provider ailelerine (`showsByIdsProvider`,
  /// `stagesByIdsProvider`) her build'de AYNI liste örneği verilir; aksi
  /// hâlde her build yeni bir provider (ve yeni bir Firestore isteği) açar.
  final Map<String, List<String>> _idLists = {};
  List<String> _ids(final String id) => _idLists.putIfAbsent(id, () => [id]);

  // 🛡️ MİSAFİR KONTROLÜ
  bool get _isGuest =>
      widget.customerId == 'guest' || widget.customerId.isEmpty;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    // 🔥 EKSİK OLAN KOLTUK SERBEST BIRAKMA:
    // Kullanıcı ödemeyi tamamlamadan bu ekrandan çıkarsa (geri tuşu, uygulamayı
    // kapatma, başka bir sekmeye geçme vb.), önceden 'reserved' koltuklar
    // SONSUZA KADAR kilitli kalıyordu — hiçbir yerde bu ekrandan çıkışta
    // otomatik bir "serbest bırak" çağrısı yoktu ve backend'de de süre
    // dolumu (TTL) mekanizması bulunmuyor. Bu, gerçek koltukların satışa
    // kapanmasına yol açan ciddi bir envanter kilitlenmesi hatasıydı.
    // Not: Bu sadece normal (dispose çağrılan) çıkışları kapsar; uygulama
    // çökmesi veya sekmenin aniden kapatılması gibi durumlar için hâlâ
    // sunucu tarafında bir TTL/temizlik mekanizması (örn. reservedAt alanına
    // bakan zamanlanmış bir Cloud Function) eklenmesi gerekiyor.
    if (!_isGuest) {
      try {
        final seats = ref.read(eventSeatsProvider(widget.eventId)).value ?? {};
        for (final entry in seats.entries) {
          if (entry.value['status'] == 'reserved' &&
              entry.value['customerId'] == widget.customerId) {
            ref
                .read(toggleSeatSelectionProvider(
              eventId: widget.eventId,
              seatId: entry.key,
              customerId: widget.customerId,
              isAdding: false,
            ).future)
                .catchError((final _) {});
          }
        }
      } catch (_) {
        // Dispose sırasında provider erişimi güvenli değilse sessizce geç;
        // koltuk her hâlükârda ana asenkron akış tamamlanınca serbest kalır.
      }
    }
    _confettiController.dispose();
    _tear.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────
  // Yardımcılar (sadece gösterim)
  // ───────────────────────────────────────────────────────────────────────

  List<String> _mySelectedSeats(final Map<String, Map<String, dynamic>> seats) =>
      seats.entries
          .where((final e) =>
              e.value['customerId'] == widget.customerId &&
              e.value['status'] == 'reserved')
          .map((final e) => e.key)
          .toList();

  static String _friendlyError(final Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  static T? _first<T>(final List<T>? list) =>
      (list == null || list.isEmpty) ? null : list.first;

  void _retry() {
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventSeatsProvider(widget.eventId));
  }

  // ───────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(final BuildContext context) {
    final seatsAsync = ref.watch(eventSeatsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final timerStream = ref.watch(reservationTimerProvider);

    // Gösterim için oyun ve sahne adı (Event.showId doluysa tek doğruluk
    // kaynağı odur; boşsa URL'deki showId).
    final Event? event = eventAsync.value;
    final String showId = (event != null && event.showId.isNotEmpty)
        ? event.showId
        : widget.showId;
    final Show? show = showId.isEmpty
        ? null
        : _first(ref.watch(showsByIdsProvider(_ids(showId))).value);
    final Stage? stage = (event == null || event.stageId.isEmpty)
        ? null
        : _first(ref.watch(stagesByIdsProvider(_ids(event.stageId))).value);

    final bool desktop = ResponsiveUtils.isDesktop(context);
    final bool tablet = ResponsiveUtils.isTablet(context);
    final int seconds = timerStream.value ?? 600;
    final Map<String, Map<String, dynamic>> seats = seatsAsync.value ?? {};
    final List<String> mine = _mySelectedSeats(seats);
    final double unitPrice =
        event == null ? 0 : (double.tryParse(event.price) ?? 0.0);

    final _Schedule? schedule =
        event == null ? null : _Schedule.parse(event.date);

    final Widget topBar = _SeatTopBar(
      title: desktop ? 'Koltuğunu seç' : (show?.name ?? 'Koltuğunu seç'),
      subtitle: desktop
          ? null
          : [
              if (schedule != null) '${schedule.dayMonth}, ${schedule.time}',
              if (stage != null && stage.name.trim().isNotEmpty)
                stage.name.trim(),
            ].join('  ·  '),
      seconds: seconds,
      large: desktop,
    );

    // Plan: yükleniyor / hata / veri.
    final Widget plan = eventAsync.when(
      loading: () => const _PlanSkeleton(),
      error: (final e, final _) => _PlanError(
        title: 'Seans bilgisi yüklenemedi.',
        detail: 'Bağlantını kontrol edip yeniden dene. '
            'Sorun sürerse oyun sayfasından seansı tekrar seç.',
        onRetry: _retry,
      ),
      data: (final ev) => seatsAsync.when(
        loading: () => const _PlanSkeleton(),
        error: (final e, final _) => _PlanError(
          title: 'Koltuk durumu alınamadı.',
          detail: 'Canlı koltuk bilgisine ulaşılamadı. '
              'Bağlantını kontrol edip yeniden dene.',
          onRetry: _retry,
        ),
        data: (final live) => _buildHall(ev, live, desktop: desktop),
      ),
    );

    final VoidCallback? primaryAction = _isGuest
        ? () => NavigationHandler.goToLogin(context)
        : (mine.isEmpty
            ? null
            : () => _openPayment(context, mine, animateTear: desktop));

    final Widget body = desktop
        ? _DesktopLayout(
            topBar: topBar,
            plan: plan,
            tear: _tearCurve,
            stub: _DesktopStub(
              show: show,
              stage: stage,
              schedule: schedule,
              seats: mine,
              unitPrice: unitPrice,
              isGuest: _isGuest,
              seed: widget.eventId,
              onPrimary: primaryAction,
            ),
          )
        : _MobileLayout(
            topBar: topBar,
            plan: plan,
            maxWidth: tablet ? 760 : double.infinity,
            horizontalPadding: tablet ? AppSpacing.xxl : AppSpacing.md,
            stub: _MobileStub(
              seats: mine,
              unitPrice: unitPrice,
              isGuest: _isGuest,
              onPrimary: primaryAction,
            ),
          );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: TicketStage(
        themed: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(child: body),
            // 🎉 SATIN ALMA BAŞARILI KUTLAMASI
            _buildConfetti(),
          ],
        ),
      ),
    );
  }

  Widget _buildHall(final Event event,
      final Map<String, Map<String, dynamic>> live,
      {required final bool desktop}) {
    final rows = groupSeatsByRow(event.seats.keys);
    if (rows.isEmpty) {
      return const _PlanError(
        title: 'Bu seansın koltuk planı henüz yayınlanmadı.',
        detail: 'Biletler satışa açıldığında koltuklar burada görünecek.',
        onRetry: null,
      );
    }

    final String me = _isGuest ? '' : widget.customerId;
    final Set<SeatVisual> present = {};

    SeatVisual visualOf(final String id) {
      final dynamic statusData = live[id] ?? event.seats[id] ?? const {};
      return seatVisualOf(
        status: statusData['status']?.toString() ?? 'available',
        ownerId: statusData['customerId']?.toString(),
        customerId: me,
      );
    }

    for (final row in rows.values) {
      for (final id in row) {
        present.add(visualOf(id));
      }
    }

    final legend = SeatLegend(visible: [
      SeatVisual.available,
      SeatVisual.selected,
      SeatVisual.held,
      SeatVisual.sold,
      if (present.contains(SeatVisual.blocked)) SeatVisual.blocked,
      if (present.contains(SeatVisual.owned)) SeatVisual.owned,
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SeatHallPlan(
            rows: rows,
            minSeat: desktop ? 30 : 40,
            maxSeat: desktop ? 44 : 48,
            seatBuilder: (final context, final seatId, final size) {
              final dynamic statusData =
                  live[seatId] ?? event.seats[seatId] ?? const {};
              final String status =
                  statusData['status']?.toString() ?? 'available';
              final String? ownerId = statusData['customerId']?.toString();
              final SeatVisual visual = visualOf(seatId);
              final bool processing = _processingSeats.contains(seatId);
              // Sadece müsait ya da kendi seçtiğin koltuk dokunulabilir.
              // (Önceden başkasının tuttuğu koltuğa dokunmak, sunucuda
              // sessizce hiçbir şey yapmayan bir "serbest bırak" isteği
              // gönderiyordu.)
              final bool tappable = !processing &&
                  (visual == SeatVisual.available ||
                      visual == SeatVisual.selected);
              return TicketSeat(
                seatId: seatId,
                visual: visual,
                size: size,
                busy: processing,
                onTap: tappable
                    ? () => _handleSeatTap(
                        seatId, status, ownerId == widget.customerId)
                    : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: legend,
        ),
      ],
    );
  }

  // 🔹 KOLTUK SEÇME MANTIĞI (GÜVENLİK EKLENDİ)
  Future<void> _handleSeatTap(
      final String seatId, final String status, final bool isMine) async {
    // 1. GÜVENLİK KONTROLÜ: Misafir ise işlem yapma, Login'e yönlendir
    if (_isGuest) {
      _showLoginDialog();
      return;
    }

    if (_processingSeats.contains(seatId)) return;

    HapticFeedback.selectionClick();
    setState(() => _processingSeats.add(seatId));
    try {
      await ref.read(toggleSeatSelectionProvider(
        eventId: widget.eventId,
        seatId: seatId,
        customerId: widget.customerId,
        isAdding: status == 'available',
      ).future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$seatId seçilemedi: ${_friendlyError(e)}'),
        ));
      }
    } finally {
      if (mounted) setState(() => _processingSeats.remove(seatId));
    }
  }

  /// "Ödemeye geç": (masaüstünde) koçanı yırt → ödeme yöntemi → vazgeçildiyse
  /// koçanı geri yapıştır.
  Future<void> _openPayment(final BuildContext context,
      final List<String> seats, {required final bool animateTear}) async {
    final bool tear = animateTear && !_reduceMotion;
    if (tear) await _tear.forward(from: 0);
    if (!mounted) return;
    await _showPaymentModal(context, seats);
    if (tear && mounted && !_purchaseInFlight) _tear.reverse();
  }

  // 🔹 MİSAFİR UYARI DİYALOGU
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (final ctx) => _PaperDialog(
        kind: 'GİRİŞ GEREKLİ',
        title: 'Koltuk seçmek için giriş yap',
        body: 'Koltuğunu ayırabilmen ve biletini alabilmen için '
            'hesabınla giriş yapman gerekiyor.',
        primaryLabel: 'Giriş yap',
        onPrimary: () {
          Navigator.pop(ctx);
          NavigationHandler.goToLogin(context);
        },
        secondaryLabel: 'Vazgeç',
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _showPaymentModal(
      final BuildContext context, final List<String> selectedSeats) async {
    final event = await ref.read(eventDetailProvider(widget.eventId).future);
    final unitPrice = double.tryParse(event.price) ?? 0.0;
    final totalPrice = selectedSeats.length * unitPrice;
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (final ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: TicketPiece(
            perforated: TicketEdge.top,
            shadows: AppShadows.level4(TicketInk.ink),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                  AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TicketHeaderStrip(kind: 'ÖDEME'),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: TicketField(
                          label: selectedSeats.length > 1
                              ? 'KOLTUKLAR'
                              : 'KOLTUK',
                          value: selectedSeats.join(', '),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      TicketField(
                        label: 'TOPLAM',
                        value: ticketPriceTl(totalPrice),
                        align: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(
                    header: true,
                    child: Text('ÖDEME YÖNTEMİ', style: TicketInk.label()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _paymentOption(
                      icon: Icons.credit_card_rounded,
                      title: "Kredi / Banka Kartı",
                      subtitle: "Anında onay",
                      onTap: () => _processPurchase(ctx, selectedSeats, "card",
                          totalPrice, event.stageId, event.showId)),
                  const SizedBox(height: AppSpacing.sm),
                  _paymentOption(
                      icon: Icons.account_balance_rounded,
                      title: "Havale / EFT",
                      subtitle: "IBAN ile ödeme",
                      onTap: () => _processPurchase(ctx, selectedSeats, "iban",
                          totalPrice, event.stageId, event.showId)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(
          {required final IconData icon,
          required final String title,
          required final String subtitle,
          required final VoidCallback onTap}) =>
      _PaymentOptionRow(
          icon: icon, title: title, subtitle: subtitle, onTap: onTap);

  Future<void> _processPurchase(
      final BuildContext ctx,
      final List<String> seats,
      final String method,
      final double total,
      final String stageId,
      final String showId) async {
    _purchaseInFlight = true;
    Navigator.pop(ctx);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) => const _IssuingDialog());

    try {
      await ref.read(purchaseActionProvider(
        eventId: widget.eventId,
        showId: showId,
        stageId: stageId,
        seatIds: seats,
        customerId: widget.customerId,
        paymentMethod: method,
        totalPrice: total,
      ).future);

      if (mounted) {
        Navigator.pop(context);
        // 🎉 Satın alma burada, mevcut kodun başarıyı onayladığı TEK anda
        // kutlanıyor — hata yolunda asla tetiklenmez.
        if (!_reduceMotion) _confettiController.play();
        HapticFeedback.mediumImpact();
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (final context) => _TicketIssuedDialog(
                  seats: seats,
                  total: total,
                  onMyTickets: () => NavigationHandler.goToMyTickets(
                      context, widget.customerId),
                  onHome: () => NavigationHandler.goToHome(context),
                ));
      }
    } catch (e) {
      _purchaseInFlight = false;
      if (mounted) {
        Navigator.pop(context);
        if (!_reduceMotion) _tear.reverse();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'Bilet alınamadı: ${_friendlyError(e)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ));
      }
    }
  }

  // 🎉 Konfeti, sahnenin üst ortasından aşağı doğru kısa bir patlama —
  // temanın vurgu rengi + bilet kağıdı.
  Widget _buildConfetti() => Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // aşağı doğru
            maxBlastForce: 10,
            minBlastForce: 4,
            emissionFrequency: 0.08,
            numberOfParticles: 16,
            gravity: 0.3,
            shouldLoop: false,
            colors: [
              TicketInk.accentOf(context),
              TicketInk.stageAccentOf(context),
              TicketInk.paper,
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Seans bilgisi (gerçek Event.date'ten)
// ─────────────────────────────────────────────────────────────────────────

class _Schedule {
  final String dayMonth;
  final String date;
  final String time;
  const _Schedule(this.dayMonth, this.date, this.time);

  static _Schedule? parse(final String raw) {
    final DateTime? d = DateFormatter.parseDateString(raw);
    if (d == null) return null;
    final info = DateFormatter.formatForEventCard(raw);
    return _Schedule('${info['day']} ${info['monthName']}', ticketDate(d),
        ticketTime(d));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yerleşimler
// ─────────────────────────────────────────────────────────────────────────

/// Mobil + tablet: dikey bilet. Gövde = plan, koçan = seçim çubuğu.
class _MobileLayout extends StatelessWidget {
  final Widget topBar;
  final Widget plan;
  final Widget stub;
  final double maxWidth;
  final double horizontalPadding;

  const _MobileLayout({
    required this.topBar,
    required this.plan,
    required this.stub,
    required this.maxWidth,
    required this.horizontalPadding,
  });

  @override
  Widget build(final BuildContext context) {
    final List<BoxShadow> shadows =
        AppShadows.level2(Theme.of(context).colorScheme.shadow);
    return Column(
      children: [
        topBar,
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0,
                    horizontalPadding, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TicketPiece(
                        perforated: TicketEdge.bottom,
                        shadows: shadows,
                        child: plan,
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.passthrough,
                      children: [
                        TicketPiece(
                          perforated: TicketEdge.top,
                          shadows: shadows,
                          child: stub,
                        ),
                        const Positioned(
                          top: -1,
                          left: 0,
                          right: 0,
                          height: 2,
                          child: TicketPerforation(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Masaüstü: yatay bilet. Solda plan (gövde), sağda koçan.
class _DesktopLayout extends StatelessWidget {
  final Widget topBar;
  final Widget plan;
  final Widget stub;
  final Animation<double> tear;

  const _DesktopLayout({
    required this.topBar,
    required this.plan,
    required this.stub,
    required this.tear,
  });

  static const double _stubWidth = 360;

  @override
  Widget build(final BuildContext context) {
    final List<BoxShadow> shadows =
        AppShadows.level3(Theme.of(context).colorScheme.shadow);
    return Column(
      children: [
        topBar,
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl, 0,
                    AppSpacing.xxxl, AppSpacing.xxxl),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: _stubWidth),
                      child: TicketPiece(
                        perforated: TicketEdge.right,
                        shadows: shadows,
                        child: plan,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: _stubWidth,
                      child: AnimatedBuilder(
                        animation: tear,
                        builder: (final context, final child) {
                          final double t = tear.value;
                          if (t == 0) return child!;
                          return Opacity(
                            opacity: (1 - t * 0.9).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(t * 70, t * 36),
                              child: Transform.rotate(
                                angle: 0.12 * t,
                                alignment: Alignment.bottomLeft,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: TicketPiece(
                          perforated: TicketEdge.left,
                          shadows: shadows,
                          child: stub,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 0,
                      bottom: 0,
                      right: _stubWidth - 1,
                      width: 2,
                      child: TicketPerforation(axis: Axis.vertical),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Üst çubuk
// ─────────────────────────────────────────────────────────────────────────

class _SeatTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int seconds;
  final bool large;

  const _SeatTopBar({
    required this.title,
    required this.subtitle,
    required this.seconds,
    required this.large,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          large ? AppSpacing.xl : AppSpacing.xs,
          large ? AppSpacing.lg : AppSpacing.xs,
          large ? AppSpacing.xxxl : AppSpacing.lg,
          large ? AppSpacing.lg : AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: () => NavigationHandler.smartGoBack(context),
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: cs.onSurface,
                      fontSize: large ? 30 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TimerChip(seconds: seconds),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final int seconds;
  const _TimerChip({required this.seconds});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool urgent = seconds < 60;
    final Color fg = urgent ? cs.error : cs.onSurface;
    final String text =
        "${(seconds / 60).floor()}:${(seconds % 60).toString().padLeft(2, '0')}";
    return Semantics(
      label:
          'Koltuk rezervasyonu için kalan süre: ${(seconds / 60).floor()} dakika ${seconds % 60} saniye',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Kalan süre',
        excludeFromSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: urgent ? cs.error : cs.outlineVariant, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: fg),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
// Koçanlar (seçim özeti + tek birincil aksiyon)
// ─────────────────────────────────────────────────────────────────────────

String _primaryLabel(final bool isGuest, final List<String> seats) {
  if (isGuest) return 'Giriş yap';
  return seats.isEmpty ? 'Koltuk seç' : 'Ödemeye geç';
}

/// Birincil damga butonu; seçim yokken soluk ve etkisiz (kit'te devre dışı
/// görünüm olmadığı için burada soluklaştırılıyor).
class _PrimaryStamp extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryStamp({required this.label, required this.onTap});

  @override
  Widget build(final BuildContext context) => AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1,
        duration: AppMotion.fast,
        child: TicketStampButton(
          label: label,
          onTap: onTap,
          leading: const Icon(Icons.confirmation_number_outlined),
        ),
      );
}

class _MobileStub extends StatelessWidget {
  final List<String> seats;
  final double unitPrice;
  final bool isGuest;
  final VoidCallback? onPrimary;

  const _MobileStub({
    required this.seats,
    required this.unitPrice,
    required this.isGuest,
    required this.onPrimary,
  });

  @override
  Widget build(final BuildContext context) {
    final double total = seats.length * unitPrice;
    final String hint = isGuest
        ? 'Koltuk seçmek için önce giriş yapmalısın.'
        : 'Planda bir koltuğa dokun. En fazla 3 koltuk'
            '${unitPrice > 0 ? ', koltuk başı ${ticketPriceTl(unitPrice)}' : ''}.';
    return Semantics(
      container: true,
      label: seats.isEmpty
          ? 'Seçilen koltuk yok'
          : 'Seçilen koltuklar: ${seats.join(", ")}, toplam ${ticketPriceTl(total)}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: seats.isEmpty
                  ? Text(
                      hint,
                      key: const ValueKey('hint'),
                      style: TextStyle(
                        color: TicketInk.inkSoft(0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    )
                  : ExcludeSemantics(
                      key: const ValueKey('fields'),
                      child: Row(
                        children: [
                          Expanded(
                            child: TicketField(
                              label: seats.length > 1 ? 'KOLTUKLAR' : 'KOLTUK',
                              value: seats.join(', '),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          TicketField(
                            label: 'TOPLAM',
                            value: ticketPriceTl(total),
                            align: CrossAxisAlignment.end,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryStamp(
              label: _primaryLabel(isGuest, seats),
              onTap: onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopStub extends StatelessWidget {
  final Show? show;
  final Stage? stage;
  final _Schedule? schedule;
  final List<String> seats;
  final double unitPrice;
  final bool isGuest;
  final String seed;
  final VoidCallback? onPrimary;

  const _DesktopStub({
    required this.show,
    required this.stage,
    required this.schedule,
    required this.seats,
    required this.unitPrice,
    required this.isGuest,
    required this.seed,
    required this.onPrimary,
  });

  @override
  Widget build(final BuildContext context) {
    final double total = seats.length * unitPrice;
    final String stageName = stage?.name.trim() ?? '';
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl + AppSpacing.xs,
                AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TicketHeaderStrip(kind: 'KOLTUK BİLETİ'),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  show?.name ?? 'Oyun',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TicketInk.headline(26),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TicketField(
                          label: 'TARİH', value: schedule?.date ?? '—'),
                    ),
                    Expanded(
                      child: TicketField(
                          label: 'SAAT', value: schedule?.time ?? '—'),
                    ),
                  ],
                ),
                if (stageName.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  TicketField(label: 'SAHNE', value: stageName),
                ],
                const SizedBox(height: AppSpacing.xl),
                Container(height: 1, color: TicketInk.inkSoft(0.18)),
                const SizedBox(height: AppSpacing.lg),
                Text(seats.length > 1 ? 'KOLTUKLARIN' : 'KOLTUĞUN',
                    style: TicketInk.label()),
                const SizedBox(height: AppSpacing.sm),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: seats.isEmpty
                      ? Text(
                          isGuest
                              ? 'Koltuk seçmek için önce giriş yapmalısın.'
                              : 'Plandan koltuğunu seç. En fazla 3 koltuk '
                                  'ayırabilirsin.',
                          key: const ValueKey('empty'),
                          style: TextStyle(
                            color: TicketInk.inkSoft(0.7),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        )
                      : Wrap(
                          key: ValueKey(seats.join()),
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final s in seats) _SeatTag(seatId: s),
                          ],
                        ),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TicketField(
                        label: 'KOLTUK BAŞI',
                        value: unitPrice > 0 ? ticketPriceTl(unitPrice) : '—',
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TOPLAM', style: TicketInk.label()),
                        const SizedBox(height: 3),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            ticketPriceTl(total),
                            style: TicketInk.headline(26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _PrimaryStamp(
                  label: _primaryLabel(isGuest, seats),
                  onTap: onPrimary,
                ),
                const SizedBox(height: AppSpacing.lg),
                TicketBarcode(seed: seed, height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeatTag extends StatelessWidget {
  final String seatId;
  const _SeatTag({required this.seatId});

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadius.xs / 2),
      ),
      child: Text(
        seatId,
        style: TextStyle(
          color: TicketInk.onAccentOf(context),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Durumlar: iskelet + hata
// ─────────────────────────────────────────────────────────────────────────

/// Plan yüklenirken koltuk sıraları şeklinde iskelet (spinner yok).
class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(final BuildContext context) => Semantics(
        label: 'Koltuk planı yükleniyor',
        child: Shimmer.fromColors(
          baseColor: TicketInk.inkSoft(0.08),
          highlightColor: TicketInk.paper,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: LayoutBuilder(
              builder: (final context, final c) {
                const double seat = 30, gap = 8;
                final int cols = ((c.maxWidth + gap) / (seat + gap))
                    .floor()
                    .clamp(4, 14)
                    .toInt();
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                  children: [
                    Container(
                      height: 18,
                      width: c.maxWidth * 0.6,
                      decoration: BoxDecoration(
                        color: TicketInk.ink,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    for (int r = 0; r < 7; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: gap),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < cols; i++)
                              Container(
                                width: seat,
                                height: seat,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: gap / 2),
                                decoration: BoxDecoration(
                                  color: TicketInk.ink,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.xs),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _PlanError extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  const _PlanError({
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.event_seat_outlined,
                    size: 40, color: TicketInk.inkSoft(0.4)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TicketInk.headline(22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TicketInk.inkSoft(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  TicketStampButton(
                    label: 'Tekrar dene',
                    leading: const Icon(Icons.refresh_rounded),
                    onTap: onRetry,
                    primary: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Ödeme ve diyaloglar
// ─────────────────────────────────────────────────────────────────────────

class _PaymentOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          side: BorderSide(color: TicketInk.inkSoft(0.35), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: TicketInk.inkSoft(0.05),
          focusColor: accent.withOpacity(0.16),
          splashColor: accent.withOpacity(0.12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 24),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: TicketInk.value(size: 15)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: TicketInk.inkSoft(0.6),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: TicketInk.inkSoft(0.45)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satın alma sürerken: "biletin kesiliyor" — küçük kağıt kart, tam
/// sayfa spinner değil.
class _IssuingDialog extends StatelessWidget {
  const _IssuingDialog();

  @override
  Widget build(final BuildContext context) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: 300,
              child: TicketPiece(
                perforated: TicketEdge.bottom,
                shadows: AppShadows.level4(TicketInk.ink),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TicketHeaderStrip(kind: 'BİLET'),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        liveRegion: true,
                        label: 'Biletin kesiliyor, lütfen bekle',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TicketInk.accentOf(context),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text('Biletin kesiliyor…',
                                  style: TicketInk.value(size: 15)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Başarı: yeni biletin üstüne "ALINDI" mürekkep damgası basılır.
class _TicketIssuedDialog extends StatefulWidget {
  final List<String> seats;
  final double total;
  final VoidCallback onMyTickets;
  final VoidCallback onHome;

  const _TicketIssuedDialog({
    required this.seats,
    required this.total,
    required this.onMyTickets,
    required this.onHome,
  });

  @override
  State<_TicketIssuedDialog> createState() => _TicketIssuedDialogState();
}

class _TicketIssuedDialogState extends State<_TicketIssuedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stamp =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final Animation<double> _thud =
      CurvedAnimation(parent: _stamp, curve: Curves.easeOutBack);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _stamp.value = 1;
    } else {
      Future.delayed(AppMotion.fast, () {
        if (mounted) _stamp.forward();
      });
    }
  }

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TicketPiece(
                  perforated: TicketEdge.bottom,
                  shadows: AppShadows.level4(TicketInk.ink),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                        AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TicketHeaderStrip(kind: 'GİRİŞ BİLETİ'),
                        const SizedBox(height: AppSpacing.xl),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Semantics(
                              liveRegion: true,
                              header: true,
                              child: Text('Biletin alındı.',
                                  style: TicketInk.headline(30)),
                            ),
                            Positioned(
                              right: 0,
                              top: -AppSpacing.xs,
                              child: ExcludeSemantics(
                                child: TicketInkStamp(
                                    text: 'ALINDI', appear: _thud),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Biletin "Biletlerim" sayfanda. Girişte QR kodunu '
                          'göstermen yeterli.',
                          style: TextStyle(
                            color: TicketInk.inkSoft(0.72),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: TicketField(
                                label: widget.seats.length > 1
                                    ? 'KOLTUKLAR'
                                    : 'KOLTUK',
                                value: widget.seats.join(', '),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            TicketField(
                              label: 'ÖDENEN',
                              value: ticketPriceTl(widget.total),
                              align: CrossAxisAlignment.end,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        TicketStampButton(
                          label: 'Biletlerime git',
                          leading:
                              const Icon(Icons.confirmation_number_outlined),
                          onTap: widget.onMyTickets,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Center(
                          child: TicketTextLink(
                            label: 'Ana sayfaya dön',
                            onTap: widget.onHome,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Kağıt diyalog: başlık + açıklama + tek birincil aksiyon + vazgeç.
class _PaperDialog extends StatelessWidget {
  final String kind;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _PaperDialog({
    required this.kind,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(final BuildContext context) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TicketPiece(
                perforated: TicketEdge.bottom,
                shadows: AppShadows.level4(TicketInk.ink),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                      AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TicketHeaderStrip(kind: kind),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        header: true,
                        child: Text(title, style: TicketInk.headline(26)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        body,
                        style: TextStyle(
                          color: TicketInk.inkSoft(0.72),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TicketStampButton(
                        label: primaryLabel,
                        leading: const Icon(Icons.login_rounded),
                        onTap: onPrimary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: TicketTextLink(
                          label: secondaryLabel,
                          onTap: onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
