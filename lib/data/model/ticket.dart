class Ticket {
  final String id;
  final String? createdAt;
  final String? updatedAt;
  final String customerId;
  final String showId;
  final String stageId;
  final String eventId;
  final String orderMethod;
  final String orderPrice;
  final String? isPast;

  Ticket({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.customerId,
    required this.showId,
    required this.stageId,
    required this.eventId,
    required this.orderMethod,
    required this.orderPrice,
    this.isPast
  });
}
