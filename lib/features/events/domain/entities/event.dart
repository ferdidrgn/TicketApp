import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String stageId, showId;
  final String date;
  final String price;
  final Map<String, dynamic> seats;

  /// Diğer koleksiyonlarla (Stage/Show/Ticket) aynı meta sözleşmesi
  /// (13.11.2026) — önceden bu modelde yoktu. Mevcut çağıranları bozmamak
  /// için varsayılan boş string: eski/okunamayan dökümanlarda boş kalır.
  final String createdAt, updatedAt;

  const Event({
    required this.id,
    required this.stageId,
    required this.showId,
    required this.date,
    required this.price,
    required this.seats,
    this.createdAt = '',
    this.updatedAt = '',
  });

  @override
  List<Object?> get props =>
      [id, stageId, showId, date, price, seats, createdAt, updatedAt];
}
