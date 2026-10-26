import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';

/// Sunucunun (Cloud Functions) bilet satışı sözleşmesi — bkz.
/// `docs/ODEME-GUVENLIK.md`. Tutarlar yalnızca GÖSTERİM içindir; istemci
/// asla fiyat/tutar göndermez, hesabı sunucu `Event.price`'tan yapar.

/// Tutulan tek koltuk ve sunucunun hesapladığı birim fiyatı.
class HeldSeat extends Equatable {
  final String id;
  final double price;

  const HeldSeat({required this.id, required this.price});

  @override
  List<Object?> get props => [id, price];
}

/// `holdSeats` sonucu: süreli koltuk tutma (Order `held`).
class SeatHold extends Equatable {
  final String orderId;
  final DateTime expiresAt;
  final double total;
  final String currency;
  final bool free;
  final List<HeldSeat> seats;

  const SeatHold({
    required this.orderId,
    required this.expiresAt,
    required this.total,
    required this.currency,
    required this.free,
    required this.seats,
  });

  List<String> get seatIds => [for (final s in seats) s.id];

  @override
  List<Object?> get props =>
      [orderId, expiresAt, total, currency, free, seats];
}

/// `startPayment` sonucu. `paymentPageUrl` ya da `checkoutFormContent`
/// (HTML) dolu gelir.
class PaymentSession extends Equatable {
  final String provider;
  final String? paymentPageUrl;
  final String? checkoutFormContent;
  final String token;

  const PaymentSession({
    required this.provider,
    required this.token,
    this.paymentPageUrl,
    this.checkoutFormContent,
  });

  @override
  List<Object?> get props =>
      [provider, paymentPageUrl, checkoutFormContent, token];
}

/// Satış modu (`Config/satis.mode`).
enum SalesMode {
  /// Ücretli bilet satışı kapalı (ücretsiz etkinlikler çalışır).
  kapali,

  /// Koltuk tutulur, ücret sahnede ödenir.
  rezervasyon,

  /// Kartla online ödeme de açık.
  online;

  static SalesMode parse(final Object? raw) => switch (raw) {
        'kapali' => kapali,
        'online' => online,
        _ => rezervasyon,
      };
}

/// `Config/satis` belgesi. Belge yoksa/bozuksa [defaults].
class SalesConfig extends Equatable {
  final SalesMode mode;

  /// Kişi başı toplam en fazla rezervasyon (kesin kontrol sunucuda).
  final int rezervasyonLimit;

  /// Başlangıca en az bu kadar saat varsa bilet iptal edilebilir.
  final int iptalSaat;

  const SalesConfig({
    this.mode = SalesMode.rezervasyon,
    this.rezervasyonLimit = 3,
    this.iptalSaat = 24,
  });

  static const SalesConfig defaults = SalesConfig();

  factory SalesConfig.fromMap(final Map<String, dynamic>? d) {
    if (d == null) {
      return defaults;
    }
    int intOr(final Object? v, final int fallback, final int min) =>
        v is num && v >= min ? v.toInt() : fallback;
    return SalesConfig(
      mode: SalesMode.parse(d['mode']),
      rezervasyonLimit: intOr(d['rezervasyonLimit'], 3, 1),
      iptalSaat: intOr(d['iptalSaat'], 24, 0),
    );
  }

  /// Ücretli etkinlikte satış kapalı mı (ücretsiz etkinlikler hep açık).
  bool isClosedFor({required final bool paid}) =>
      paid && mode == SalesMode.kapali;

  /// Oyun detayındaki satın alma düğmesi etiketi. [fallback] satış
  /// açık/ücretsiz durumdaki mevcut etiket ("Bilet al" / "Koltuk seç").
  String ctaLabel({required final bool paid, final String fallback = 'Bilet al'}) {
    if (!paid) {
      return fallback;
    }
    return switch (mode) {
      SalesMode.kapali => 'Satış kapalı',
      SalesMode.rezervasyon => 'Rezervasyon yap',
      SalesMode.online => fallback,
    };
  }

  @override
  List<Object?> get props => [mode, rezervasyonLimit, iptalSaat];
}

enum OrderStatus {
  held,
  paying,
  paid,
  freeConfirmed,
  expired,
  failed,
  cancelled,
  unknown;

  static OrderStatus parse(final Object? raw) => switch (raw) {
        'held' => held,
        'paying' => paying,
        'paid' => paid,
        'free_confirmed' => freeConfirmed,
        'expired' => expired,
        'failed' => failed,
        'cancelled' => cancelled,
        _ => unknown,
      };

  /// Bilet kesildi.
  bool get isFulfilled => this == paid || this == freeConfirmed;

  /// Sipariş artık ilerlemez ve bilet de kesilmedi.
  bool get isDeadEnd => this == expired || this == failed || this == cancelled;

  /// Koltuklar hâlâ kullanıcının elinde (devam edilebilir).
  bool get isOpen => this == held || this == paying;
}

/// Kullanıcının kendi `Order` belgesi (yalnızca okunur).
class PurchaseOrder extends Equatable {
  final String id;
  final String userId;
  final String eventId;
  final String showId;
  final String stageId;
  final List<String> seatIds;
  final double total;
  final bool free;
  final OrderStatus status;
  final DateTime? expiresAt;
  final List<String> ticketIds;

  const PurchaseOrder({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.seatIds,
    required this.status,
    this.showId = '',
    this.stageId = '',
    this.total = 0,
    this.free = false,
    this.expiresAt,
    this.ticketIds = const [],
  });

  bool isExpiredAt(final DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  @override
  List<Object?> get props => [
        id,
        userId,
        eventId,
        showId,
        stageId,
        seatIds,
        total,
        free,
        status,
        expiresAt,
        ticketIds,
      ];
}

/// Kullanıcıya gösterilebilir satın alma hatası. [message] her zaman
/// Türkçe ve teknik ayrıntı içermez.
class PurchaseFailure extends Failure {
  /// Sunucu hata kodu (`failed-precondition`, `resource-exhausted`, …) ya da
  /// istemci tarafı `network` / `unknown`.
  final String code;

  const PurchaseFailure(super.message, {this.code = 'unknown'});

  /// Koltuk/sipariş artık geçerli değil (süre doldu, başkası aldı): tutma
  /// durumunu sıfırlamak gerekir.
  bool get isStale => code == 'failed-precondition' || code == 'not-found';

  @override
  List<Object?> get props => [message, code];
}
