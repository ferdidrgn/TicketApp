import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
  final String id;
  final String createdAt, updatedAt;
  final String customerId;
  final String showId, stageId, eventId;
  final String orderPrice, orderMethod;
  final List<String> buySeats;
  final bool? isPast;

  /// Satın alma anında bilete KOPYALANAN özet (denormalizasyon). Oyun/seans/
  /// sahne kaydı ileride arşivlenip silinse bile bilet kendi başına
  /// okunabilir kalır. Eski biletlerde boş olabilir.
  final String showName, showImageUrl, stageName, eventDate;

  /// Ödeme durumu: `pay_at_venue` | `paid` | `no_show` | `cancelled`.
  /// Eski biletlerde boş. `usedAt` (girişte okutuldu) ve `cancelledAt` ISO metin.
  final String paymentStatus, usedAt, cancelledAt;

  const Ticket({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.showId,
    required this.stageId,
    required this.eventId,
    required this.orderMethod,
    required this.orderPrice,
    required this.buySeats,
    required this.isPast,
    this.showName = '',
    this.showImageUrl = '',
    this.stageName = '',
    this.eventDate = '',
    this.paymentStatus = '',
    this.usedAt = '',
    this.cancelledAt = '',
  });

  bool get isCancelled => paymentStatus == 'cancelled' || cancelledAt.isNotEmpty;
  bool get isNoShow => paymentStatus == 'no_show';
  bool get isPayAtVenue => paymentStatus == 'pay_at_venue';


  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        customerId,
        showId,
        stageId,
        eventId,
        orderMethod,
        orderPrice,
        buySeats,
        isPast,
        showName,
        showImageUrl,
        stageName,
        eventDate,
        paymentStatus,
        usedAt,
        cancelledAt,
      ];
}
