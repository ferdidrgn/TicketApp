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
  List<Object?> get props => [id, stageId, showId, date, price, seats];
}
