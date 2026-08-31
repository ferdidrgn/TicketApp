import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String stageId, showId;
  final String date;
  final String price;
  final Map<String, dynamic> seats;
  final List<String> sponsors;

  const Event({
    required this.id,
    required this.stageId,
    required this.showId,
    required this.date,
    required this.price,
    required this.seats,
    this.sponsors = const [],
  });

  /// Küratör fiyatı "0" (veya parse edilemeyen bir değer değilse ve <= 0)
  /// olarak ayarlamışsa etkinlik ücretsiz sayılır — ayrı bir Firestore
  /// alanı gerekmez, mevcut `price` alanı yeterli.
  bool get isFree {
    final parsed = double.tryParse(price);
    return parsed != null && parsed <= 0;
  }

  @override
  List<Object?> get props =>
      [id, stageId, showId, date, price, seats, sponsors];
}
