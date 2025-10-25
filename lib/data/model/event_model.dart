import '../../domain/entities/event.dart';

class EventModel {
  final String? id;
  final String? stageId;
  final String? showId;
  final String? date;
  final String? price;
  final Map<String, dynamic>? seatStatus;

  const EventModel({
    this.id,
    this.stageId,
    this.showId,
    this.date,
    this.price,
    this.seatStatus,
  });

  factory EventModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const EventModel();
    return EventModel(
      id: data['_id'] as String?,
      stageId: data['stageId'] as String?,
      showId: data['showId'] as String?,
      date: data['date'] as String?,
      price: data['price'] as String?,
      seatStatus: data['seatStatus'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'stageId': stageId,
        'showId': showId,
        'date': date,
        'price': price,
        'seatStatus': seatStatus,
      };

  Event toEntity() => Event(
        id: id ?? '0',
        stageId: stageId ?? '0',
        showId: showId ?? '0',
        date: date ?? 'Tarih bulunamadı',
        price: price ?? 'Fiyat bulunamadı',
        seatStatus: seatStatus ?? {},
      );

  factory EventModel.fromEntity(final Event event) => EventModel(
        id: event.id,
        stageId: event.stageId,
        showId: event.showId,
        date: event.date,
        price: event.price,
        seatStatus: event.seatStatus,
      );
}
