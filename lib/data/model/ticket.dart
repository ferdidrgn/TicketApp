class Ticket {
  final String id;
  final String? createdAt;
  final String? updatedAt;
  final String customerId;
  final String showId;
  final String stageId;
  final String eventId;

  Ticket({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.customerId,
    required this.showId,
    required this.stageId,
    required this.eventId,
  });
}
