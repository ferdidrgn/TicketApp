class Event {
  final String id;
  final String stageId;
  final String date;
  final String price;
  final Map<String, dynamic>? seatStatus;

  Event({
    required this.id,
    required this.stageId,
    required this.date,
    required this.price,
    this.seatStatus
  });
}
