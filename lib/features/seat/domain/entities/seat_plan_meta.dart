import 'package:equatable/equatable.dart';

/// `Seats/{stageId}` dökümanının meta verisi — koltuk DÜZENİNİ değil, hangi
/// sahneye ait olduğunu ve ne zaman oluşturulup güncellendiğini taşır.
/// Diğer koleksiyonlarla (Stage/Show/Event/Ticket) aynı `_id`/`_createdAt`/
/// `_updatedAt` sözleşmesi; bkz. firestore.rules `match /Seats/{stageId}`.
class SeatPlanMeta extends Equatable {
  final String stageId;
  final String stageName;
  final String address;
  final String createdAt;
  final String updatedAt;

  const SeatPlanMeta({
    required this.stageId,
    required this.stageName,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasData => stageId.isNotEmpty;

  static const empty = SeatPlanMeta(
    stageId: '',
    stageName: '',
    address: '',
    createdAt: '',
    updatedAt: '',
  );

  @override
  List<Object?> get props => [stageId, stageName, address, createdAt, updatedAt];
}
