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
