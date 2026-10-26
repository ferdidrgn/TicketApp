import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_entities.dart';
import '../../domain/usecases/confirm_free_use_case_impl.dart';
import '../../domain/usecases/confirm_reservation_use_case_impl.dart';
import '../../domain/usecases/get_open_orders_use_case_impl.dart';
import '../../domain/usecases/hold_seats_use_case_impl.dart';
import '../../domain/usecases/release_hold_use_case_impl.dart';
import '../../domain/usecases/start_payment_use_case_impl.dart';
import '../../domain/usecases/watch_order_use_case_impl.dart';
import 'purchase_provider.dart';

/// iyzico dönüşünün düştüğü site adresi (functions `SITE_URL`; izinli
/// alan adı). Sunucu `returnUrl`'i yalnızca kendi izin listesiyle doğrular
/// ve yönlendirmede KULLANMAZ — burada yalnızca WebView'ın yakalayacağı
/// yol bilgisidir.
const String kPurchaseSiteOrigin = 'https://tiyatrol-web.web.app';
const String kPurchaseResultPath = '/odeme-sonuc';

/// `startPayment` için dönüş adresi. Tutar/fiyat içermez.
String purchaseReturnUrl(final String orderId) =>
    '$kPurchaseSiteOrigin$kPurchaseResultPath?order=${Uri.encodeQueryComponent(orderId)}';

/// Bir etkinlikte seçilebilecek en fazla koltuk (kesin kontrol sunucuda).
const int kMaxSeatsPerPurchase = 3;

/// Ödeme dönüşünden sonra sonucu bekleme süresi (webhook gecikmesi).
const Duration kVerifyWindow = Duration(seconds: 60);

enum PurchasePhase {
  /// Yerel seçim; sunucuda henüz bir şey yok.
  selecting,

  /// `holdSeats` / `releaseHold` sürüyor.
  holding,

  /// Koltuklar süreli tutuluyor (Order `held`).
  held,

  /// `startPayment` / `confirmFree` sürüyor.
  startingPayment,

  /// Ödeme başlatıldı (Order `paying`); sonuç bekleniyor.
  awaitingPayment,

  /// Ödeme sayfasından dönüldü; Order belgesinden doğrulanıyor.
  verifying,

  /// Bilet kesildi.
  completed,
}

class PurchaseNotice {
  final int id;
  final String text;
  final bool isError;

  const PurchaseNotice(this.id, this.text, {this.isError = true});
}

class SeatPurchaseState {
  final Set<String> selected;
  final PurchasePhase phase;
  final SeatHold? hold;
  final PurchaseNotice? notice;

  /// `completed` için: ücretsiz mi, koltuklar, tutar.
  final bool completedFree;

  /// `completed` için: rezervasyon (ücret sahnede ödenecek) mi.
  final bool completedReservation;
  final List<String> completedSeats;
  final double completedTotal;

  const SeatPurchaseState({
    this.selected = const {},
    this.phase = PurchasePhase.selecting,
    this.hold,
    this.notice,
    this.completedFree = false,
    this.completedReservation = false,
    this.completedSeats = const [],
    this.completedTotal = 0,
  });

  /// Sunucuda tutulan koltuklar var mı (ödeme akışı dahil).
  bool get hasHold => hold != null;

  /// Ödeme başlamış / sonuç bekleniyor: koltuklar bırakılamaz.
  bool get paymentStarted =>
      phase == PurchasePhase.awaitingPayment ||
      phase == PurchasePhase.verifying;

  /// Ekranda "senin koltukların" olarak gösterilecekler.
  List<String> get mySeats =>
      hasHold ? hold!.seatIds : selected.toList(growable: false);

  /// Plan üzerinde dokunulabilir mi?
  bool get canPick => phase == PurchasePhase.selecting;

  SeatPurchaseState copyWith({
    final Set<String>? selected,
    final PurchasePhase? phase,
    final SeatHold? hold,
    final bool clearHold = false,
    final PurchaseNotice? notice,
    final bool clearNotice = false,
    final bool? completedFree,
    final bool? completedReservation,
    final List<String>? completedSeats,
    final double? completedTotal,
  }) =>
      SeatPurchaseState(
        selected: selected ?? this.selected,
        phase: phase ?? this.phase,
        hold: clearHold ? null : (hold ?? this.hold),
        notice: clearNotice ? null : (notice ?? this.notice),
        completedFree: completedFree ?? this.completedFree,
        completedReservation:
            completedReservation ?? this.completedReservation,
        completedSeats: completedSeats ?? this.completedSeats,
        completedTotal: completedTotal ?? this.completedTotal,
      );
}

/// Bir etkinliğin koltuk seçimi → tutma → ödeme akışı.
///
/// - Koltuğa dokunmak YEREL seçimdir (sunucuya yazmaz).
/// - "Koltukları tut" tek `holdSeats` çağrısıdır.
/// - Geri sayım sunucunun verdiği `expiresAt`'ten, duvar saatine göre
///   hesaplanır (arka plana alma / uyku zamanlayıcıyı bozmaz).
/// - Ekran kapanınca (provider dispose) ödemesi başlamamış tutma
///   bırakılır; ödeme başlamışsa sunucu süre dolumunu yönetir.
class SeatPurchaseController extends Notifier<SeatPurchaseState> {
  SeatPurchaseController(this.eventId);

  final String eventId;

  late HoldSeatsUseCase _hold;
  late ReleaseHoldUseCase _release;
  late StartPaymentUseCase _startPayment;
  late ConfirmFreeUseCase _confirmFree;
  late ConfirmReservationUseCase _confirmReservation;
  late WatchOrderUseCase _watchOrder;
  late GetOpenOrdersUseCase _getOpenOrders;
  late DateTime Function() _now;

  Timer? _expiryTimer;
  Timer? _verifyTimer;
  StreamSubscription<PurchaseOrder?>? _orderSub;
  String? _trackedOrderId;
  String? _releasableOrderId;
  int _noticeSeq = 0;
  bool _disposed = false;

  @override
  SeatPurchaseState build() {
    _hold = ref.read(holdSeatsUseCaseProvider);
    _release = ref.read(releaseHoldUseCaseProvider);
    _startPayment = ref.read(startPaymentUseCaseProvider);
    _confirmFree = ref.read(confirmFreeUseCaseProvider);
    _confirmReservation = ref.read(confirmReservationUseCaseProvider);
    _watchOrder = ref.read(watchOrderUseCaseProvider);
    _getOpenOrders = ref.read(getOpenOrdersUseCaseProvider);
    _now = ref.read(purchaseClockProvider);
    ref.onDispose(_onDispose);
    return const SeatPurchaseState();
  }

  // ───────────────────────────── yardımcılar

  void _set(final SeatPurchaseState next) {
    if (_disposed) {
      return;
    }
    state = next;
    _releasableOrderId =
        (next.phase == PurchasePhase.held && next.hold != null)
            ? next.hold!.orderId
            : null;
  }

  void _noticeNow(final String text, {final bool isError = true}) {
    if (_disposed) {
      return;
    }
    _set(state.copyWith(notice: PurchaseNotice(++_noticeSeq, text, isError: isError)));
  }

  void clearNotice() {
    if (_disposed || state.notice == null) {
      return;
    }
    _set(state.copyWith(clearNotice: true));
  }

  void _cancelTimers() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
  }

  Future<void> _stopTracking() async {
    final sub = _orderSub;
    _orderSub = null;
    _trackedOrderId = null;
    await sub?.cancel();
  }

  void _onDispose() {
    _disposed = true;
    _cancelTimers();
    _orderSub?.cancel();
    _orderSub = null;
    final orderId = _releasableOrderId;
    if (orderId != null) {
      // Ödemesi başlamamış tutma: ekrandan çıkış = vazgeçme. Sonuç
      // beklenmez; başarısız olursa sunucu süre dolumunda zaten bırakır.
      unawaited(_release(orderId));
    }
  }

  /// Tutma/ödeme biter: yerel seçime dön.
  void _resetToSelecting({
    final String? message,
    final bool isError = true,
    final Set<String>? keepSelection,
  }) {
    _cancelTimers();
    unawaited(_stopTracking());
    _set(SeatPurchaseState(
      selected: keepSelection ?? const {},
      notice: message == null
          ? null
          : PurchaseNotice(++_noticeSeq, message, isError: isError),
    ));
  }

  // ───────────────────────────── yerel seçim

  /// Koltuğu yerel seçime ekler/çıkarır. En fazla [kMaxSeatsPerPurchase]
  /// (UI ipucu; kesin kontrol sunucuda).
  bool toggleSeat(final String seatId) {
    if (!state.canPick) {
      return false;
    }
    final next = {...state.selected};
    if (!next.remove(seatId)) {
      if (next.length >= kMaxSeatsPerPurchase) {
        _noticeNow('En fazla $kMaxSeatsPerPurchase koltuk seçebilirsin.',
            isError: false);
        return false;
      }
      next.add(seatId);
    }
    _set(state.copyWith(selected: next, clearNotice: true));
    return true;
  }

  // ───────────────────────────── tutma

  /// "Koltukları tut": tek `holdSeats` çağrısı.
  Future<bool> holdSelected() async {
    if (state.phase != PurchasePhase.selecting || state.selected.isEmpty) {
      return false;
    }
    final ids = state.selected.toList();
    _set(state.copyWith(phase: PurchasePhase.holding, clearNotice: true));
    final result = await _hold(eventId, ids);
    return result.fold(
      (final f) {
        _set(state.copyWith(
            phase: PurchasePhase.selecting,
            notice: PurchaseNotice(++_noticeSeq, f.message)));
        return false;
      },
      (final hold) {
        if (_disposed) {
          // Sonuç gelmeden ekran kapandı: tutmayı hemen bırak.
          unawaited(_release(hold.orderId));
          return false;
        }
        _adoptHold(hold);
        return true;
      },
    );
  }

  void _adoptHold(final SeatHold hold, {final bool paying = false}) {
    _cancelTimers();
    _set(SeatPurchaseState(
      phase: paying ? PurchasePhase.awaitingPayment : PurchasePhase.held,
      hold: hold,
    ));
    _scheduleExpiry();
    if (paying) {
      _track(hold.orderId);
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final hold = state.hold;
    if (hold == null || _disposed) {
      return;
    }
    final remaining = hold.expiresAt.difference(_now());
    if (remaining <= Duration.zero) {
      unawaited(_onExpired());
      return;
    }
    _expiryTimer = Timer(remaining, () => unawaited(_onExpired()));
  }

  Future<void> _onExpired() async {
    final hold = state.hold;
    if (hold == null || _disposed) {
      return;
    }
    if (state.phase == PurchasePhase.held) {
      // Sunucu `expireHolds` gecikse bile süresi dolmuş tutma başkasınca
      // alınabilir; yine de temiz kalsın diye bırakmayı dene.
      unawaited(_release(hold.orderId));
      _resetToSelecting(
          message: 'Koltuk tutma süren doldu. Koltukları yeniden seçebilirsin.',
          isError: false);
    } else if (state.phase != PurchasePhase.completed) {
      // Ödeme aşamasında: kesin durum Order belgesinden gelir. Süre
      // dolduysa seçime dön ama izlemeyi KORU — callback geç gelip ödeme
      // gerçekleşirse akış tamamlanır.
      _cancelTimers();
      _set(SeatPurchaseState(
        notice: PurchaseNotice(++_noticeSeq,
            'Ödeme süresi doldu. Ödemeyi tamamladıysan biletin kısa süre içinde Biletlerim\'de görünür.',
            isError: false),
      ));
    }
  }

  /// "Seçimi değiştir": ödemesi başlamamış tutmayı bırak ve seçime dön.
  Future<void> releaseHold() async {
    final hold = state.hold;
    if (hold == null || state.phase != PurchasePhase.held) {
      return;
    }
    final seats = hold.seatIds.toSet();
    _set(state.copyWith(phase: PurchasePhase.holding, clearNotice: true));
    final result = await _release(hold.orderId);
    if (_disposed) {
      return;
    }
    result.fold(
      (final f) {
        if (f is PurchaseFailure && f.isStale) {
          _resetToSelecting(message: f.message, isError: false);
        } else {
          _set(state.copyWith(
              phase: PurchasePhase.held,
              notice: PurchaseNotice(++_noticeSeq, f.message)));
        }
      },
      (final _) => _resetToSelecting(keepSelection: seats),
    );
  }

  // ───────────────────────────── ödeme / ücretsiz onay

  /// Ücretli: `startPayment`. Başarılıysa ödeme oturumunu döner; açma
  /// (WebView/tarayıcı) arayüzün işidir.
  Future<PaymentSession?> startPayment() async {
    final hold = state.hold;
    final phase = state.phase;
    if (hold == null || hold.free) {
      return null;
    }
    if (phase != PurchasePhase.held && phase != PurchasePhase.awaitingPayment) {
      return null;
    }
    _set(state.copyWith(
        phase: PurchasePhase.startingPayment, clearNotice: true));
    final result = await _startPayment(hold.orderId, purchaseReturnUrl(hold.orderId));
    if (_disposed) {
      return null;
    }
    return result.fold(
      (final f) {
        if (f is PurchaseFailure && f.isStale) {
          _resetToSelecting(message: f.message);
        } else {
          _set(state.copyWith(
              phase: phase, notice: PurchaseNotice(++_noticeSeq, f.message)));
        }
        return null;
      },
      (final session) {
        _set(state.copyWith(phase: PurchasePhase.awaitingPayment));
        _track(hold.orderId);
        return session;
      },
    );
  }

  /// Ücretsiz: `confirmFree`.
  Future<bool> confirmFree() async {
    final hold = state.hold;
    if (hold == null || !hold.free || state.phase != PurchasePhase.held) {
      return false;
    }
    _set(state.copyWith(
        phase: PurchasePhase.startingPayment, clearNotice: true));
    final result = await _confirmFree(hold.orderId);
    if (_disposed) {
      return false;
    }
    return result.fold(
      (final f) {
        if (f is PurchaseFailure && f.code == 'resource-exhausted') {
          // Ücretsiz bilet sınırı: koltukları boşuna tutma.
          unawaited(_release(hold.orderId));
          _resetToSelecting(message: f.message);
        } else if (f is PurchaseFailure && f.isStale) {
          _resetToSelecting(message: f.message);
        } else {
          _set(state.copyWith(
              phase: PurchasePhase.held,
              notice: PurchaseNotice(++_noticeSeq, f.message)));
        }
        return false;
      },
      (final _) {
        _complete(seats: hold.seatIds, total: 0, free: true);
        return true;
      },
    );
  }

  /// Ücretli, sahnede ödemeli: `confirmReservation`. Koltuklar bilete
  /// dönüşür; tutar etkinlik günü gişede ödenir.
  Future<bool> confirmReservation() async {
    final hold = state.hold;
    if (hold == null || hold.free || state.phase != PurchasePhase.held) {
      return false;
    }
    _set(state.copyWith(
        phase: PurchasePhase.startingPayment, clearNotice: true));
    final result = await _confirmReservation(hold.orderId);
    if (_disposed) {
      return false;
    }
    return result.fold(
      (final f) {
        if (f is PurchaseFailure && f.code == 'resource-exhausted') {
          // Rezervasyon sınırı: koltukları boşuna tutma.
          unawaited(_release(hold.orderId));
          _resetToSelecting(message: f.message);
        } else if (f is PurchaseFailure && f.isStale) {
          _resetToSelecting(message: f.message);
        } else {
          _set(state.copyWith(
              phase: PurchasePhase.held,
              notice: PurchaseNotice(++_noticeSeq, f.message)));
        }
        return false;
      },
      (final _) {
        _complete(
            seats: hold.seatIds,
            total: hold.total,
            free: false,
            reservation: true);
        return true;
      },
    );
  }

  void _complete(
      {required final List<String> seats,
      required final double total,
      required final bool free,
      final bool reservation = false}) {
    _cancelTimers();
    unawaited(_stopTracking());
    _set(SeatPurchaseState(
      phase: PurchasePhase.completed,
      completedFree: free,
      completedReservation: reservation,
      completedSeats: seats,
      completedTotal: total,
    ));
  }

  // ───────────────────────────── ödeme sonucu (Order belgesi)

  void _track(final String orderId) {
    if (_trackedOrderId == orderId && _orderSub != null) {
      return;
    }
    _orderSub?.cancel();
    _trackedOrderId = orderId;
    _orderSub = _watchOrder(orderId).listen(_onOrder, onError: (final Object _) {
      // İzleme hatası ödemeyi etkilemez; sonuç Biletlerim'de görünür.
    });
  }

  void _onOrder(final PurchaseOrder? order) {
    if (_disposed || order == null) {
      return;
    }
    if (order.status.isFulfilled) {
      final hold = state.hold;
      _complete(
        seats: hold?.seatIds ?? order.seatIds,
        total: hold?.total ?? order.total,
        free: order.free,
      );
      return;
    }
    if (order.status.isDeadEnd) {
      if (state.phase == PurchasePhase.completed) {
        return;
      }
      _resetToSelecting(
        message: order.status == OrderStatus.cancelled
            ? null
            : order.status == OrderStatus.expired
                ? 'Ödeme süresi doldu; bilet oluşmadı.'
                : 'Ödeme tamamlanamadı, bilet oluşmadı. Kartından tutar '
                    'çekildiyse Yardım ve Destek\'ten bize ulaş.',
      );
      return;
    }
    // Ödeme penceresi uzadıysa sunucunun yeni süresini benimse.
    final hold = state.hold;
    if (order.status == OrderStatus.paying &&
        hold != null &&
        order.expiresAt != null &&
        order.expiresAt != hold.expiresAt) {
      _set(state.copyWith(
          hold: SeatHold(
        orderId: hold.orderId,
        expiresAt: order.expiresAt!,
        total: hold.total,
        currency: hold.currency,
        free: hold.free,
        seats: hold.seats,
      )));
      _scheduleExpiry();
    }
  }

  /// Ödeme sayfasından dönüldü (başarılı ya da değil — karar Order
  /// belgesindedir). "Doğrulanıyor" durumuna geçer.
  void paymentReturned() {
    final hold = state.hold;
    if (hold == null || state.phase == PurchasePhase.completed) {
      return;
    }
    _track(hold.orderId);
    _set(state.copyWith(phase: PurchasePhase.verifying, clearNotice: true));
    _verifyTimer?.cancel();
    _verifyTimer = Timer(kVerifyWindow, () {
      if (_disposed || state.phase != PurchasePhase.verifying) {
        return;
      }
      _set(state.copyWith(
        phase: PurchasePhase.awaitingPayment,
        notice: PurchaseNotice(++_noticeSeq,
            'Ödemen hâlâ doğrulanıyor. Biletin hazır olunca Biletlerim\'de görünür.',
            isError: false),
      ));
    });
  }

  /// Ödeme sayfası sonuç alınmadan kapatıldı (geri tuşu).
  void paymentDismissed() {
    if (state.phase == PurchasePhase.awaitingPayment ||
        state.phase == PurchasePhase.startingPayment) {
      _set(state.copyWith(
        phase: PurchasePhase.awaitingPayment,
        notice: PurchaseNotice(++_noticeSeq,
            'Ödeme tamamlanmadı. Hazır olduğunda "Ödemeye devam et"i kullanabilirsin.',
            isError: false),
      ));
    }
  }

  // ───────────────────────────── uygulama kapanması / geri dönüş

  /// Ekran açılırken: kullanıcının bu etkinlikteki yarım kalmış siparişini
  /// (held/paying, süresi dolmamış) sunucudan bulup akışa devam ettirir.
  /// Süresi dolmuş siparişler sessizce yok sayılır (sunucu bırakır).
  Future<void> restore(final String userId) async {
    if (state.phase != PurchasePhase.selecting || userId.isEmpty) {
      return;
    }
    final result = await _getOpenOrders(userId);
    if (_disposed || state.phase != PurchasePhase.selecting) {
      return;
    }
    final now = _now();
    result.fold((final _) {}, (final orders) {
      final mine = orders
          .where((final o) =>
              o.eventId == eventId &&
              o.status.isOpen &&
              o.expiresAt != null &&
              !o.isExpiredAt(now))
          .toList()
        ..sort((final a, final b) => b.expiresAt!.compareTo(a.expiresAt!));
      if (mine.isEmpty) {
        return;
      }
      final o = mine.first;
      final per = o.seatIds.isEmpty ? 0.0 : o.total / o.seatIds.length;
      _adoptHold(
        SeatHold(
          orderId: o.id,
          expiresAt: o.expiresAt!,
          total: o.total,
          currency: 'TRY',
          free: o.free,
          seats: [for (final id in o.seatIds) HeldSeat(id: id, price: per)],
        ),
        paying: o.status == OrderStatus.paying,
      );
    });
  }

  /// `WidgetsBindingObserver` köprüsü. Arka plana alınırken zamanlayıcılar
  /// durur; geri gelince süre duvar saatine göre yeniden hesaplanır.
  void onLifecycle(final AppLifecycleState s) {
    if (_disposed) {
      return;
    }
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _expiryTimer?.cancel();
      _expiryTimer = null;
    } else if (s == AppLifecycleState.resumed) {
      if (state.hold != null && state.phase != PurchasePhase.completed) {
        _scheduleExpiry();
      }
      final id = state.hold?.orderId;
      if (id != null && state.paymentStarted && _orderSub == null) {
        _track(id);
      }
    }
  }
}

/// Etkinlik başına bir akış; ekran kapanınca kendini temizler.
final seatPurchaseControllerProvider = NotifierProvider.autoDispose
    .family<SeatPurchaseController, SeatPurchaseState, String>(
        SeatPurchaseController.new);
