import '../../domain/entities/event.dart';

class EventModel {
  final String? id;
  final String? stageId;
  final String? date;
  final String? price;
  final Map<String, dynamic>? seatStatus;

  const EventModel({
    this.id,
    this.stageId,
    this.date,
    this.price,
    this.seatStatus,
  });

  factory EventModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const EventModel();
    return EventModel(
      id: data['_id'] as String?,
      stageId: data['stageId'] as String?,
      date: data['date'] as String?,
      price: data['price'] as String?,
      seatStatus: data['seatStatus'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'stageId': stageId,
        'date': date,
        'price': price,
        'seatStatus': seatStatus,
      };

  Event toEntity() => Event(
        id: id,
        stageId: stageId,
        date: date,
        price: price,
        seatStatus: seatStatus ?? {},
      );

  factory EventModel.fromEntity(final Event event) => EventModel(
        id: event.id,
        stageId: event.stageId,
        date: event.date,
        price: event.price,
        seatStatus: event.seatStatus,
      );
}
