import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String stageId;
  final String showId;
  final String date;
  final String price;
  final Map<String, dynamic> seats;

  const Event({
    required this.id,
    required this.stageId,
    required this.showId,
    required this.date,
    required this.price,
    required this.seats,
  });

  @override
  List<Object?> get props => [
        id,
        stageId,
        showId,
        date,
        price,
        seats,
      ];

  factory Event.fromMap(final Map<String, dynamic>? data) => Event(
        id: data?['_id'] as String? ?? '0',
        stageId: data?['stageId'] as String? ?? '0',
        showId: data?['showId'] as String? ?? '0',
        date: data?['date'] as String? ?? 'Tarih bulunamadı',
        price: data?['price'] as String? ?? '0',
        seats: data?['seats'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toMap() => {
        '_id': id,
        'stageId': stageId,
        'showId': showId,
        'date': date,
        'price': price,
        'seats': seats,
      };
}
