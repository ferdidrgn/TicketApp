import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String stageId;
  final String date;
  final String price;
  final Map<String, dynamic> seatStatus;

  const Event({
    required this.id,
    required this.stageId,
    required this.date,
    required this.price,
    required this.seatStatus,
  });

  @override
  List<Object?> get props => [
        id,
        stageId,
        date,
        price,
        seatStatus,
      ];

  factory Event.fromMap(final Map<String, dynamic>? data) => Event(
        id: data?['_id'] as String? ?? '0',
        stageId: data?['stageId'] as String? ?? '0',
        date: data?['date'] as String? ?? 'Tarih bulunamadı',
        price: data?['price'] as String? ?? '0',
        seatStatus: data?['seatStatus'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toMap() => {
        '_id': id,
        'stageId': stageId,
        'date': date,
        'price': price,
        'seatStatus': seatStatus,
      };
}
