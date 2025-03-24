import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String? id;
  final String? stageId;
  final String? date;
  final String? price;
  final Map<String, dynamic>? seatStatus;

  const Event({
    this.id,
    this.stageId,
    this.date,
    this.price,
    this.seatStatus,
  });

  @override
  List<Object?> get props => [
        id,
        stageId,
        date,
        price,
        seatStatus,
      ];

  factory Event.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Event();
    return Event(
      id: data['_id'] as String?,
      stageId: data['stageId'] as String?,
      date: data['date'] as String?,
      price: data['price'] as String?,
      seatStatus: data['seatStatus'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        'stageId': stageId,
        'date': date,
        'price': price,
        'seatStatus': seatStatus,
      };
}
