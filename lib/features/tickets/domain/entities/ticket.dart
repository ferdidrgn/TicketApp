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
  });

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
      ];
}
