import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String stageId;
  final String date;
  final String price;
  final Map<String, dynamic>? seatStatus;

  const Event({
    required this.id,
    required this.stageId,
    required this.date,
    required this.price,
    this.seatStatus,
  });

  @override
  List<Object?> get props => [id, stageId, date, price, seatStatus];

  factory Event.fromMap(final Map<String, dynamic> data) {
    return Event(
      id: data['_id'],
      stageId: data['stageId'] ?? '',
      date: data['date'] ?? '',
      price: data['price'] ?? '',
      seatStatus: data['seatStatus'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'stageId': stageId,
      'date': date,
      'price': price,
      'seatStatus': seatStatus,
    };
  }
}
