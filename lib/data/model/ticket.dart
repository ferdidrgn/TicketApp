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
  final bool isPast;

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
    this.isPast = false,
  });

  Ticket copyWith({
    final String? id,
    final String? createdAt,
    final String? updatedAt,
    final String? customerId,
    final String? showId,
    final String? stageId,
    final String? eventId,
    final String? orderMethod,
    final String? orderPrice,
    final bool? isPast,
  }) {
    return Ticket(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      showId: showId ?? this.showId,
      stageId: stageId ?? this.stageId,
      eventId: eventId ?? this.eventId,
      orderMethod: orderMethod ?? this.orderMethod,
      orderPrice: orderPrice ?? this.orderPrice,
      isPast: isPast ?? this.isPast,
    );
  }
}
