import '../../domain/entities/event.dart';

class EventModel {
  final String id;
  final String stageId;
  final String date;
  final String price;
  final Map<String, dynamic>? seatStatus;

  const EventModel({
    required this.id,
    required this.stageId,
    required this.date,
    required this.price,
    this.seatStatus,
  });

  factory EventModel.fromFirestore(final Map<String, dynamic> data) {
    return EventModel(
      id: data['_id'] ?? '',
      stageId: data['stageId'] ?? '',
      date: data['date'] ?? '',
      price: data['price'] ?? '',
      seatStatus: data['seatStatus'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_id': id,
      'stageId': stageId,
      'date': date,
      'price': price,
      'seatStatus': seatStatus,
    };
  }

  Event toEntity() {
    return Event(
      id: id,
      stageId: stageId,
      date: date,
      price: price,
      seatStatus: seatStatus,
    );
  }

  factory EventModel.fromEntity(final Event event) {
    return EventModel(
      id: event.id,
      stageId: event.stageId,
      date: event.date,
      price: event.price,
      seatStatus: event.seatStatus,
    );
  }
}
