import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/util/platform_checker.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/web_site_header.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/ticket/seat_plan.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../purchase/domain/entities/purchase_entities.dart';
import '../../../purchase/presentation/pages/payment_web_view_page.dart';
import '../../../auth/presentation/widgets/phone_verify_sheet.dart';
import '../../../settings/presentation/widgets/loud_alarm_sheet.dart';
import '../../../purchase/presentation/providers/purchase_provider.dart';
import '../../../purchase/presentation/providers/seat_purchase_controller.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../providers/seats_provider.dart';

/// KOLTUK SEÇİMİ — "bilet dili"nin en gerçek hâli: salon, basılı bir
/// oturma planıdır; seçim özeti biletin koçanıdır.
///
/// - Mobil (<768): plan kağıdı üstte (iki parmakla yakınlaştırılır), altta
///   delik çizgisiyle bağlı yapışkan koçan: seçilen koltuklar + toplam +
///   tek birincil aksiyon.
/// - Tablet (768–1023): aynı dikey bilet, ortalanmış ve daha geniş koltuklar.
/// - Masaüstü (≥1024): yatay bilet — solda plan (gövde), sağda koçan
///   (oyun, tarih, sahne, koltuklar, toplam). Ödemeye geçerken koçan
///   delikten yırtılır; ödeme vazgeçilirse geri yapışır.
///
/// AKIŞ (hepsi sunucuda, bkz. `docs/ODEME-GUVENLIK.md`; istemci Firestore'a
/// koltuk/bilet YAZMAZ):
///   dokun → yerel seçim (en fazla 3) → "Koltukları tut" (`holdSeats`) →
///   geri sayım (`expiresAt`) → ücretli: "Ödemeye geç" (`startPayment` →
///   iyzico sayfası) / ücretsiz: `confirmFree` → sonuç `Order` belgesinden.
/// Durum makinesi: `SeatPurchaseController`.
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // 🎉 Satın alma başarıyla tamamlandığında kısa bir kutlama patlaması için.
  late final ConfettiController _confettiController;

  /// Masaüstünde "Ödemeye geç" → koçan delikten kopar.
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  bool _reduceMotion = false;
  bool _verifyingOpen = false;

  /// Online modda kullanıcının yöntem seçimi (`null` = varsayılan: kart).
  bool? _cardChoice;

  late final _purchaseProvider = seatPurchaseControllerProvider(widget.eventId);

  /// Liste parametreli provider ailelerine (`showsByIdsProvider`,
  /// `stagesByIdsProvider`) her build'de AYNI liste örneği verilir; aksi
  /// hâlde her build yeni bir provider (ve yeni bir Firestore isteği) açar.
  final Map<String, List<String>> _idLists = {};
  List<String> _ids(final String id) => _idLists.putIfAbsent(id, () => [id]);

  // 🛡️ MİSAFİR KONTROLÜ
  bool get _isGuest =>
      widget.customerId == 'guest' || widget.customerId.isEmpty;

  SeatPurchaseController get _ctrl => ref.read(_purchaseProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
    // Uygulama kapanması/çökmesi sonrası: bu etkinlikte yarım kalmış
    // (held/paying, süresi dolmamış) sipariş varsa devam ettir.
    if (!_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) {
          _ctrl.restore(widget.customerId);
          unawaited(ref.read(eventQuotaProvider(widget.eventId).notifier).refresh());
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    // Arka plana alınınca zamanlayıcı durur; geri gelince kalan süre
    // sunucunun `expiresAt` değerinden yeniden hesaplanır.
    _ctrl.onLifecycle(state);
  }

  @override
  void dispose() {
    // Ödemesi başlamamış tutma, controller dispose olurken otomatik
    // bırakılır (SeatPurchaseController._onDispose) — burada elle koltuk
    // yazımı YOK.
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _tear.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────
  // Yardımcılar (sadece gösterim)
  // ───────────────────────────────────────────────────────────────────────

  static T? _first<T>(final List<T>? list) =>
      (list == null || list.isEmpty) ? null : list.first;

  /// Yalnızca GÖSTERİM: "150", "1.250,50" gibi Event.price metnini sayıya
  /// çevirir. Sunucuya ASLA gönderilmez (tutarı sunucu hesaplar).
  static double _displayPrice(final String raw) {
    var s = raw.trim().replaceAll(RegExp(r'[^0-9.,]'), '');
    if (s.isEmpty) return 0;
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0;
  }

  void _retry() {
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventSeatsProvider(widget.eventId));
  }

  void _showNotice(final PurchaseNotice n) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    // Hesap silinmek üzereyse mesajın yanında tek dokunuşla vazgeçme eylemi.
    final deletionPending = ref
        .read(seatPurchaseControllerProvider(widget.eventId))
        .deletionPending;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: n.isError ? cs.error : null,
        duration: deletionPending ? const Duration(seconds: 10) : const Duration(seconds: 4),
        action: deletionPending
            ? SnackBarAction(
                label: 'Silmeyi iptal et',
                textColor: n.isError ? cs.onError : null,
                onPressed: () => _ctrl.cancelAccountDeletion(),
              )
            : null,
        content: Text(
          n.text,
          style: n.isError ? TextStyle(color: cs.onError) : null,
        ),
      ));
  }

  /// Controller durum geçişlerine tepki: bildirimler, "doğrulanıyor"
  /// penceresi, başarı kutlaması.
  void _onPurchaseChange(
      final SeatPurchaseState? prev, final SeatPurchaseState next) {
    if (next.notice != null && next.notice?.id != prev?.notice?.id) {
      _showNotice(next.notice!);
    }

    // Doğrulanmış telefon kapısı: koltuk tutma / onay öncesi.
    if (next.phoneRequired && !(prev?.phoneRequired ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) _openPhoneGate();
      });
    }

    // Masaüstü koçan yırtılması ödeme bitince geri yapışır.
    if (_tear.value > 0 &&
        next.phase != PurchasePhase.startingPayment &&
        next.phase != PurchasePhase.completed) {
      if (!_reduceMotion) _tear.reverse();
    }

    if (next.phase == PurchasePhase.verifying && !_verifyingOpen) {
      _verifyingOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (final _) => _VerifyingDialog(
          onClose: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ).whenComplete(() => _verifyingOpen = false);
    } else if (next.phase != PurchasePhase.verifying && _verifyingOpen) {
      _verifyingOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (next.phase == PurchasePhase.completed &&
        prev?.phase != PurchasePhase.completed) {
      _celebrate(next);
    }
  }

  bool _phoneGateOpen = false;

  /// "Telefonunu doğrula": SMS ile telefon mevcut hesaba bağlanır, sonra
  /// kalınan işlem (koltuk tutma / onay) kendiliğinden sürer.
  Future<void> _openPhoneGate() async {
    if (_phoneGateOpen) return;
    _phoneGateOpen = true;
    final result = await showPhoneVerifySheet(context);
    _phoneGateOpen = false;
    if (!mounted) return;
    switch (result) {
      case PhoneVerifyResult.verified:
        unawaited(ref.read(eventQuotaProvider(widget.eventId).notifier).refresh());
        await _ctrl.phoneVerified();
      case PhoneVerifyResult.switchedAccount:
        // Hesap değişti: bu ekran eski kullanıcıya göre kurulmuştu.
        _ctrl.phoneGateDismissed();
        NavigationHandler.goToHome(context);
      case PhoneVerifyResult.cancelled:
        _ctrl.phoneGateDismissed();
    }
  }

  bool _leftAfterPurchase = false;

  /// Onaydan sonra koltuk seçim sayfasından ÇIKAR. `go` (pop değil): yığın
  /// Biletlerim'e/ana sayfaya DEĞİŞTİRİLİR, böylece geri tuşu bu (artık
  /// anlamsız) koltuk sayfasına dönmez. Bir kez çalışır; hata satın almayı bozmaz.
  void _leaveAfterPurchase({required final bool home}) {
    if (_leftAfterPurchase) return;
    _leftAfterPurchase = true;
    try {
      if (!mounted) return;
      if (home) {
        NavigationHandler.goToHome(context);
      } else {
        NavigationHandler.goToMyTickets(context, widget.customerId);
      }
    } catch (e) {
      debugPrint('Satın alma sonrası yönlendirme hatası: ${e.runtimeType}');
    }
  }

  void _celebrate(final SeatPurchaseState s) {
    // Biletler sunucuda kesildi; listeyi tazele.
    // Yan işlemler (liste tazeleme, konfeti, titreşim) başarılı satın alma
    // sonucunu ASLA bozmaz: hata yutulur, diyalog yine açılır.
    try {
      if (!_isGuest) ref.invalidate(myTicketsProvider(widget.customerId));
      if (!_reduceMotion) _confettiController.play();
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Satın alma sonrası yan işlem hatası: ${e.runtimeType}');
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (final dialogContext) => _TicketIssuedDialog(
        seats: s.completedSeats,
        total: s.completedTotal,
        free: s.completedFree,
        reservation: s.completedReservation,
        onMyTickets: () {
          _leaveAfterPurchase(home: false);
          Navigator.of(dialogContext, rootNavigator: true).maybePop();
        },
        onHome: () {
          _leaveAfterPurchase(home: true);
          Navigator.of(dialogContext, rootNavigator: true).maybePop();
        },
      ),
    ).whenComplete(() {
      // Diyalog başka yolla kapansa da bu sayfada KALINMAZ.
      _leaveAfterPurchase(home: false);
      // İlk bilet sonrası bir kez: "sessizde de sesli hatırlat" izni sorulur
      // (varsayılan kapalı; telefonun sessiz ayarı değiştirilmez).
      if (!_isGuest) unawaited(LoudAlarmSheet.maybePromptAfterPurchase());
    });
  }

  // ───────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(final BuildContext context) {
    ref.listen<SeatPurchaseState>(_purchaseProvider, _onPurchaseChange);
    final purchase = ref.watch(_purchaseProvider);
    final seatsAsync = ref.watch(eventSeatsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

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
    final List<String> mine = purchase.mySeats;
    final double unitPrice = purchase.hold != null && purchase.hold!.seats.isNotEmpty
        ? purchase.hold!.seats.first.price
        : (event == null ? 0 : _displayPrice(event.price));
    final bool free =
        purchase.hold?.free ?? (event != null && unitPrice == 0);
    final double total =
        purchase.hold?.total ?? mine.length * unitPrice;
    final SalesConfig sales = ref.watch(salesConfigProvider);
    final EventQuota? quota =
        _isGuest ? null : ref.watch(eventQuotaProvider(widget.eventId));
    final bool payByCard =
        sales.mode == SalesMode.online && (_cardChoice ?? true);
    final bool salesClosed = !free && sales.mode == SalesMode.kapali;

    // Daha önce satın alınmış (bu kullanıcının biletinde olan) koltuklar.
    final Set<String> owned = _isGuest
        ? const {}
        : {
            for (final t in ref
                    .watch(myTicketsProvider(widget.customerId))
                    .value ??
                const <DetailedTicket>[])
              if (t.ticket.eventId == widget.eventId) ...t.ticket.buySeats,
          };

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
      expiresAt: purchase.phase == PurchasePhase.held ||
              purchase.phase == PurchasePhase.startingPayment
          ? purchase.hold?.expiresAt
          : null,
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
        data: (final live) => _buildHall(
          ev,
          live,
          purchase,
          owned,
          desktop: desktop,
          stageNote: _stageSeatNote(stage),
        ),
      ),
    );

    final VoidCallback? primaryAction = _primaryAction(purchase,
        salesClosed: salesClosed, payByCard: payByCard);
    final _StubModel stubModel = _StubModel(
      phase: purchase.phase,
      seats: mine,
      unitPrice: unitPrice,
      total: total,
      free: free,
      isGuest: _isGuest,
      sales: sales,
      payByCard: payByCard,
      salesClosed: salesClosed,
      quota: quota,
      onMethod: sales.mode == SalesMode.online
          ? (final card) => setState(() => _cardChoice = card)
          : null,
      onPrimary: primaryAction,
      onSecondary: purchase.phase == PurchasePhase.held
          ? () => _ctrl.releaseHold()
          : null,
    );

    final Widget body = desktop
        ? _DesktopLayout(
            topBar: topBar,
            plan: plan,
            tear: _tearCurve,
            stub: _DesktopStub(
              show: show,
              stage: stage,
              schedule: schedule,
              model: stubModel,
              seed: widget.eventId,
            ),
          )
        : _MobileLayout(
            topBar: topBar,
            plan: plan,
            maxWidth: tablet ? 760 : double.infinity,
            horizontalPadding: tablet ? AppSpacing.xxl : AppSpacing.md,
            stub: _MobileStub(model: stubModel),
          );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: TicketStage(
        themed: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Web (≥768): siteyle aynı kalıp — site başlığı + ekmek kırıntısı ve
            // adım göstergesi, altında koltuk planı ve koçan.
            if (PlatformChecker.isWeb && (desktop || tablet))
              Column(children: [
                const WebSiteHeader(),
                _CheckoutSteps(
                    show: show,
                    step: purchase.phase == PurchasePhase.selecting ||
                            purchase.phase == PurchasePhase.holding
                        ? 1
                        : 2),
                Expanded(child: body),
              ])
            else
              SafeArea(child: body),
            // 🎉 SATIN ALMA BAŞARILI KUTLAMASI
            _buildConfetti(),
          ],
        ),
      ),
    );
  }

  /// Faz → tek birincil aksiyon.
  VoidCallback? _primaryAction(final SeatPurchaseState s,
      {required final bool salesClosed, required final bool payByCard}) {
    if (_isGuest) return () => NavigationHandler.goToLogin(context);
    switch (s.phase) {
      case PurchasePhase.selecting:
        return s.selected.isEmpty || salesClosed
            ? null
            : () {
                HapticFeedback.selectionClick();
                _ctrl.holdSelected();
              };
      case PurchasePhase.held:
        if (s.hold?.free ?? false) return () => _ctrl.confirmFree();
        if (salesClosed) return null;
        if (payByCard) return _beginPayment;
        return () {
          HapticFeedback.selectionClick();
          _ctrl.confirmReservation();
        };
      case PurchasePhase.awaitingPayment:
        return _beginPayment;
      case PurchasePhase.completed:
        return () => _leaveAfterPurchase(home: false);
      case PurchasePhase.holding:
      case PurchasePhase.startingPayment:
      case PurchasePhase.verifying:
        return null;
    }
  }

  /// Sunucu cevaplı ödeme başlatma → iyzico sayfası.
  Future<void> _beginPayment() async {
    final bool tear = ResponsiveUtils.isDesktop(context) && !_reduceMotion;
    if (tear) _tear.forward(from: 0);
    final session = await _ctrl.startPayment();
    if (!mounted) return;
    if (session == null) {
      if (tear) _tear.reverse();
      return;
    }
    await _openPaymentSession(session);
    if (mounted && tear) _tear.reverse();
  }

  Future<void> _openPaymentSession(final PaymentSession session) async {
    if (PlatformChecker.isWeb) {
      // Web: uygulama içi WebView yok; ödeme sayfası yeni sekmede açılır,
      // sonuç yine `Order` belgesinden izlenir.
      final url = session.paymentPageUrl;
      final uri = url == null ? null : Uri.tryParse(url);
      final bool opened = uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        _ctrl.paymentReturned();
      } else {
        _ctrl.paymentDismissed();
        _showNotice(const PurchaseNotice(
            -1, 'Ödeme sayfası açılamadı. Lütfen tekrar dene.'));
      }
      return;
    }
    final result = await Navigator.of(context, rootNavigator: true)
        .push<PaymentReturn?>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (final _) => PaymentWebViewPage(session: session),
    ));
    if (!mounted) return;
    if (result == null) {
      _ctrl.paymentDismissed();
    } else {
      // Karar `durum` parametresine değil Order belgesine göre verilir.
      _ctrl.paymentReturned();
    }
  }

  /// Sahne `description` içindeki koltuk düzeni notu (ÖNEMLİ …).
  static String? _stageSeatNote(final Stage? stage) {
    if (stage == null) {
      return null;
    }
    final String d = stage.description.trim();
    if (d.isEmpty) {
      return null;
    }
    final int i = d.indexOf('ÖNEMLİ');
    if (i >= 0) {
      return d.substring(i).trim();
    }
    // Kısa açıklamaları da göster (uzun metinde sadece ÖNEMLİ bloğu).
    return d.length <= 220 ? d : null;
  }

  Widget _buildHall(
    final Event event,
    final Map<String, Map<String, dynamic>> live,
    final SeatPurchaseState purchase,
    final Set<String> owned, {
    required final bool desktop,
    final String? stageNote,
  }) {
    // Koltuk haritası sunucuda (holdSeats) ilk tutmada üretilir; o zamana
    // dek planı sahne düzeninden (Seats/{stageId}) çiz.
    Iterable<String> seatIds = live.keys;
    if (seatIds.isEmpty) seatIds = event.seats.keys;
    if (seatIds.isEmpty && event.stageId.isNotEmpty) {
      final layout = ref.watch(stageLayoutProvider(event.stageId));
      seatIds = [for (final row in layout.value?.values ?? const <List<String>>[]) ...row];
    }
    final rows = groupSeatsByRow(seatIds);
    if (rows.isEmpty) {
      return const _PlanError(
        title: 'Bu seansın koltuk planı henüz yayınlanmadı.',
        detail: 'Biletler satışa açıldığında koltuklar burada görünecek.',
        onRetry: null,
      );
    }

    final Set<String> mySeats = purchase.mySeats.toSet();
    final Set<SeatVisual> present = {};

    SeatVisual visualOf(final String id) {
      // "Benim koltuğum" = yerel seçimim ya da kendi Order'ımdaki tutma;
      // Event.seats içindeki customerId'ye BAKILMAZ.
      if (mySeats.contains(id)) return SeatVisual.selected;
      final dynamic statusData = live[id] ?? event.seats[id] ?? const {};
      final SeatVisual v = seatVisualOf(
        status: statusData['status']?.toString() ?? 'available',
        ownerId: statusData['customerId']?.toString(),
        customerId: '',
      );
      if (v == SeatVisual.sold && owned.contains(id)) return SeatVisual.owned;
      return v;
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
        if (stageNote != null && stageNote.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? AppSpacing.lg : AppSpacing.md,
              0,
              desktop ? AppSpacing.lg : AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _SeatStageNote(text: stageNote),
          ),
        Expanded(
          child: SeatHallPlan(
            rows: rows,
            minSeat: desktop ? 30 : 40,
            maxSeat: desktop ? 44 : 48,
            seatBuilder: (final context, final seatId, final size) {
              final SeatVisual visual = visualOf(seatId);
              // Yalnızca müsait ya da kendi seçtiğin koltuk dokunulabilir ve
              // yalnızca henüz sunucuda tutulmamışken (seçim aşaması).
              final bool tappable = purchase.canPick &&
                  (visual == SeatVisual.available ||
                      visual == SeatVisual.selected);
              return TicketSeat(
                seatId: seatId,
                visual: visual,
                size: size,
                busy: false,
                onTap: tappable ? () => _handleSeatTap(seatId) : null,
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

  // 🔹 KOLTUK SEÇME: yalnızca YEREL; sunucuya hiçbir şey yazılmaz.
  void _handleSeatTap(final String seatId) {
    // Misafir ise işlem yapma, giriş iste.
    if (_isGuest) {
      _showLoginDialog();
      return;
    }
    HapticFeedback.selectionClick();
    _ctrl.toggleSeat(seatId);
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

/// Sahne açıklamasındaki koltuk düzeni uyarısı (tek/çift numara vb.).
class _SeatStageNote extends StatelessWidget {
  final String text;
  const _SeatStageNote({required this.text});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: text,
      child: Material(
        color: cs.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: cs.onTertiaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: cs.onTertiaryContainer,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

  /// Sunucunun verdiği tutma bitiş anı; null ise sayaç gösterilmez.
  final DateTime? expiresAt;
  final bool large;

  const _SeatTopBar({
    required this.title,
    required this.subtitle,
    required this.expiresAt,
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
          if (expiresAt != null) ...[
            const SizedBox(width: AppSpacing.md),
            _HoldTimer(expiresAt: expiresAt!),
          ],
        ],
      ),
    );
  }
}

/// Geri sayım: HER ZAMAN `expiresAt - şimdi` (duvar saati) — arka plana
/// alma / uyku sayacı bozmaz, geri gelince doğru süreyi gösterir.
class _HoldTimer extends StatefulWidget {
  final DateTime expiresAt;
  const _HoldTimer({required this.expiresAt});

  @override
  State<_HoldTimer> createState() => _HoldTimerState();
}

class _HoldTimerState extends State<_HoldTimer> with WidgetsBindingObserver {
  Timer? _timer;

  int get _seconds {
    final int s = widget.expiresAt.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (final _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => _TimerChip(seconds: _seconds);
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

/// Koçan ekranlarının ortak girdisi (faz + gösterim değerleri).
class _StubModel {
  final PurchasePhase phase;
  final List<String> seats;
  final double unitPrice;
  final double total;
  final bool free;
  final bool isGuest;
  final SalesConfig sales;
  final bool payByCard;
  final bool salesClosed;

  /// Sunucudan gelen etkinlik bilet hakkı (yoksa varsayılan sınır).
  final EventQuota? quota;
  final ValueChanged<bool>? onMethod;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _StubModel({
    required this.phase,
    required this.seats,
    required this.unitPrice,
    required this.total,
    required this.free,
    required this.isGuest,
    required this.sales,
    required this.payByCard,
    required this.salesClosed,
    this.quota,
    required this.onMethod,
    required this.onPrimary,
    required this.onSecondary,
  });

  /// Bu seçimde en fazla kaç koltuk seçilebilir.
  int get maxPick => quota?.remaining ?? kMaxSeatsPerPurchase;

  /// Ödeme yöntemi seçici: ücretli, koltuklar tutulmuş, satış açık.
  bool get showPicker =>
      !isGuest && phase == PurchasePhase.held && !free && !salesClosed;

  bool get busy =>
      phase == PurchasePhase.holding ||
      phase == PurchasePhase.startingPayment ||
      phase == PurchasePhase.verifying;

  String get primaryLabel {
    if (isGuest) return 'Giriş yap';
    return switch (phase) {
      PurchasePhase.selecting => salesClosed
          ? 'Satış kapalı'
          : (seats.isEmpty ? 'Koltuk seç' : 'Koltukları tut'),
      PurchasePhase.holding => 'Koltuklar tutuluyor',
      PurchasePhase.held => free
          ? 'Ücretsiz bileti al'
          : (salesClosed
              ? 'Satış kapalı'
              : (payByCard ? 'Ödemeye geç' : 'Rezervasyonu onayla')),
      PurchasePhase.startingPayment =>
        free || !payByCard ? 'Onaylanıyor' : 'Ödeme açılıyor',
      PurchasePhase.awaitingPayment => 'Ödemeye devam et',
      PurchasePhase.verifying => 'Ödeme doğrulanıyor',
      PurchasePhase.completed => 'Biletlerime git',
    };
  }

  String get totalText => free && seats.isNotEmpty
      ? 'Ücretsiz'
      : ticketPriceTl(total);

  /// Fazına göre koçandaki yönlendirme metni.
  String get hint {
    if (isGuest) return 'Koltuk seçmek için önce giriş yapmalısın.';
    if (salesClosed && phase == PurchasePhase.selecting) {
      return 'Bilet satışı şu an kapalı.';
    }
    return switch (phase) {
      PurchasePhase.selecting => quota?.isFull == true
          ? quota!.summary
          : '${quota != null ? '${quota!.summary} ' : ''}'
              'Planda bir koltuğa dokun. En fazla $maxPick koltuk'
              '${unitPrice > 0 ? ', koltuk başı ${ticketPriceTl(unitPrice)}' : ''}.',
      PurchasePhase.holding => 'Koltukların senin için ayrılıyor…',
      PurchasePhase.held => salesClosed
          ? 'Bilet satışı şu an kapalı.'
          : 'Koltukların senin için ayrıldı. Süre dolmadan tamamla.',
      PurchasePhase.startingPayment => 'Bir saniye…',
      PurchasePhase.awaitingPayment =>
        'Ödeme başladı. Tamamlamadıysan kaldığın yerden devam edebilirsin.',
      PurchasePhase.verifying => 'Ödemen doğrulanıyor…',
      PurchasePhase.completed => 'Biletin hazır.',
    };
  }
}

/// Birincil damga butonu; seçim yokken soluk ve etkisiz (kit'te devre dışı
/// görünüm olmadığı için burada soluklaştırılıyor).
class _PrimaryStamp extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryStamp(
      {required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(final BuildContext context) => AnimatedOpacity(
        opacity: onTap == null && !loading ? 0.4 : 1,
        duration: AppMotion.fast,
        child: TicketStampButton(
          label: label,
          onTap: onTap ?? (loading ? () {} : null),
          loading: loading,
          leading: const Icon(Icons.confirmation_number_outlined),
        ),
      );
}

class _MobileStub extends StatelessWidget {
  final _StubModel model;

  const _MobileStub({required this.model});

  @override
  Widget build(final BuildContext context) {
    final seats = model.seats;
    return Semantics(
      container: true,
      label: seats.isEmpty
          ? 'Seçilen koltuk yok'
          : 'Seçilen koltuklar: ${seats.join(", ")}, toplam ${model.totalText}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55),
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: seats.isEmpty
                  ? Text(
                      model.hint,
                      key: const ValueKey('hint'),
                      style: TextStyle(
                        color: TicketInk.inkSoft(0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    )
                  : Column(
                      key: const ValueKey('fields'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              Expanded(
                                child: TicketField(
                                  label: seats.length > 1
                                      ? 'KOLTUKLAR'
                                      : 'KOLTUK',
                                  value: seats.join(', '),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              TicketField(
                                label: 'TOPLAM',
                                value: model.totalText,
                                align: CrossAxisAlignment.end,
                              ),
                            ],
                          ),
                        ),
                        if (model.phase != PurchasePhase.selecting) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              model.hint,
                              style: TextStyle(
                                color: TicketInk.inkSoft(0.7),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        if (model.showPicker) ...[
                          const SizedBox(height: AppSpacing.md),
                          _PaymentMethodPicker(model: model),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryStamp(
              label: model.primaryLabel,
              onTap: model.onPrimary,
              loading: model.busy,
            ),
            if (model.onSecondary != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: TicketTextLink(
                  label: 'Seçimi değiştir',
                  onTap: model.onSecondary,
                ),
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _DesktopStub extends StatelessWidget {
  final Show? show;
  final Stage? stage;
  final _Schedule? schedule;
  final _StubModel model;
  final String seed;

  const _DesktopStub({
    required this.show,
    required this.stage,
    required this.schedule,
    required this.model,
    required this.seed,
  });

  @override
  Widget build(final BuildContext context) {
    final seats = model.seats;
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
                          model.isGuest
                              ? 'Koltuk seçmek için önce giriş yapmalısın.'
                              : model.quota?.isFull == true
                                  ? model.quota!.summary
                                  : '${model.quota != null ? '${model.quota!.summary} ' : ''}'
                                      'Plandan koltuğunu seç. En fazla '
                                      '${model.maxPick} koltuk ayırabilirsin.',
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
                if (seats.isNotEmpty &&
                    model.phase != PurchasePhase.selecting) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      model.hint,
                      style: TextStyle(
                        color: TicketInk.inkSoft(0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (model.showPicker) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _PaymentMethodPicker(model: model),
                ],
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TicketField(
                        label: 'KOLTUK BAŞI',
                        value: model.free
                            ? 'Ücretsiz'
                            : (model.unitPrice > 0
                                ? ticketPriceTl(model.unitPrice)
                                : '—'),
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
                            model.totalText,
                            style: TicketInk.headline(26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _PrimaryStamp(
                  label: model.primaryLabel,
                  onTap: model.onPrimary,
                  loading: model.busy,
                ),
                if (model.onSecondary != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: TicketTextLink(
                      label: 'Seçimi değiştir',
                      onTap: model.onSecondary,
                    ),
                  ),
                ],
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

/// Ödeme yöntemi seçici: "Sahnede öde (rezervasyon)" ve "Kart ile öde
/// (iyzico)". Satış moduna göre kart etkin ya da "Yakında" ile devre dışı.
class _PaymentMethodPicker extends StatelessWidget {
  final _StubModel model;

  const _PaymentMethodPicker({required this.model});

  @override
  Widget build(final BuildContext context) {
    final bool online = model.sales.mode == SalesMode.online;
    final int limit = model.sales.rezervasyonLimit;
    final int hours = model.sales.iptalSaat;
    return Semantics(
      container: true,
      label: 'Ödeme yöntemi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodTile(
            icon: Icons.storefront_outlined,
            title: 'Sahnede öde (rezervasyon)',
            body: 'Koltuk adına ayrılır, tutar gişede ödenir. Kişi başı '
                'toplam en fazla $limit rezervasyon; etkinliğe $hours saat '
                'kalana kadar iptal edebilirsin.',
            selected: !model.payByCard,
            enabled: true,
            onTap: model.onMethod == null ? null : () => model.onMethod!(false),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MethodTile(
            icon: Icons.credit_card_outlined,
            title: 'Kart ile öde (iyzico)',
            body: online
                ? 'Kartınla şimdi öde.'
                : 'Şu anda ödeme sistemi çalışmıyor.',
            badge: online ? null : 'Yakında',
            selected: online && model.payByCard,
            enabled: online,
            onTap: online && model.onMethod != null
                ? () => model.onMethod!(true)
                : null,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? badge;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    final Color line = selected ? accent : TicketInk.inkSoft(0.25);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title${badge == null ? "" : ", $badge"}. $body',
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: line, width: selected ? 2 : 1),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? accent : TicketInk.inkSoft(0.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, size: 20, color: TicketInk.ink),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title,
                                style: const TextStyle(
                                    color: TicketInk.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: TicketInk.inkSoft(0.5)),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(badge!,
                                  style: TextStyle(
                                      color: TicketInk.inkSoft(0.8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body,
                          style: TextStyle(
                              color: TicketInk.inkSoft(0.7),
                              fontSize: 12,
                              height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

/// Ödeme sayfasından dönüldü; sonuç Order belgesinden (webhook gecikmesi
/// olabilir) doğrulanıyor. Kapatılabilir: doğrulama arka planda sürer.
class _VerifyingDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _VerifyingDialog({required this.onClose});

  @override
  Widget build(final BuildContext context) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: 320,
              child: TicketPiece(
                perforated: TicketEdge.bottom,
                shadows: AppShadows.level4(TicketInk.ink),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TicketHeaderStrip(kind: 'ÖDEME'),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        liveRegion: true,
                        label: 'Ödemen doğrulanıyor, lütfen bekle',
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
                              child: Text('Ödemen doğrulanıyor…',
                                  style: TicketInk.value(size: 15)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Bankadan onay gelince biletin kesilecek. Bu birkaç '
                        'saniye sürebilir; pencereyi kapatsan da doğrulama '
                        'devam eder.',
                        style: TextStyle(
                          color: TicketInk.inkSoft(0.72),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TicketTextLink(
                            label: 'Arka planda bekle', onTap: onClose),
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
  final bool free;
  final bool reservation;
  final VoidCallback onMyTickets;
  final VoidCallback onHome;

  const _TicketIssuedDialog({
    required this.seats,
    required this.total,
    required this.free,
    this.reservation = false,
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
                              child: Text(
                                  widget.reservation
                                      ? 'Rezervasyonun alındı.'
                                      : 'Biletin alındı.',
                                  style: TicketInk.headline(30)),
                            ),
                            Positioned(
                              right: 0,
                              top: -AppSpacing.xs,
                              child: ExcludeSemantics(
                                child: TicketInkStamp(
                                    text: widget.reservation
                                        ? 'AYRILDI'
                                        : 'ALINDI',
                                    appear: _thud),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.reservation
                              ? 'Biletin "Biletlerim" sayfanda. Ödemeyi etkinlik '
                                  'günü sahnede yaparsın; girişte QR kodunu göster.'
                              : 'Biletin "Biletlerim" sayfanda. Girişte QR kodunu '
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
                              label: widget.free
                                  ? 'ÜCRET'
                                  : (widget.reservation
                                      ? 'SAHNEDE ÖDENECEK'
                                      : 'ÖDENEN'),
                              value: widget.free
                                  ? 'Ücretsiz'
                                  : ticketPriceTl(widget.total),
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


/// Web bilet alma kalıbı: ekmek kırıntısı + 3 adım (Seans → Koltuk → Ödeme).
class _CheckoutSteps extends StatelessWidget {
  final Show? show;
  final int step; // 0 Seans, 1 Koltuk, 2 Ödeme
  const _CheckoutSteps({required this.show, required this.step});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget crumb(final String t, final VoidCallback? tap) => MouseRegion(
          cursor:
              tap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: tap,
            child: Text(t,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tap == null ? cs.onSurfaceVariant : cs.primary)),
          ),
        );
    final Widget sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child:
          Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant),
    );
    Widget dot(final int i, final String label) {
      final bool done = i < step;
      final bool now = i == step;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || now ? cs.primary : cs.surfaceContainerHigh,
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
              : Text('${i + 1}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: now ? cs.onPrimary : cs.onSurfaceVariant)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: now ? FontWeight.w800 : FontWeight.w600,
                color: now ? cs.onSurface : cs.onSurfaceVariant)),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(children: [
        crumb('Ana Sayfa', () => NavigationHandler.goToHome(context)),
        sep,
        if (show != null)
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => NavigationHandler.goToShow(
                    context, show!.id, show!.name,
                    imageUrl: show!.imageUrl, title: show!.name),
                child: Text(show!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.primary)),
              ),
            ),
          ),
        if (show != null) sep,
        crumb('Koltuk seç', null),
        const Spacer(),
        dot(0, 'Seans'),
        Container(
            width: 28,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: cs.outlineVariant),
        dot(1, 'Koltuk'),
        Container(
            width: 28,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: cs.outlineVariant),
        dot(2, 'Ödeme'),
      ]),
    );
  }
}
