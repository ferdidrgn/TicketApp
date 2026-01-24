import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String? id;
  final String? stageId;
  final String? showId;
  final String? date;
  final String? price;
  final Map<String, dynamic>? seats;

  const EventModel({
    this.id,
    this.stageId,
    this.showId,
    this.date,
    this.price,
    this.seats,
  });

  factory EventModel.fromFirestore(final Map<String, dynamic> data) =>
      EventModel(
        id: data['_id'] as String?,
        stageId: data['stageId'] as String?,
        showId: data['showId'] as String?,
        price: data['price'] as String?,
        seats: data['seats'] as Map<String, dynamic>?,
        // Firestore Timestamp kontrolü (Eğer tarih Timestamp gelirse)
        date: data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate().toIso8601String()
            : data['date']?.toString(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'stageId': stageId,
        'showId': showId,
        'date': date,
        'price': price,
        'seats': seats,
      };
}
