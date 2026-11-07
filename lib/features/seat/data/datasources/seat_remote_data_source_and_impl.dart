import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/seat_plan_meta.dart';

abstract class SeatRemoteDataSource {
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId);

  /// `Seats/{stageId}` meta verisi (hangi sahne, adres, oluşturma/güncelleme
  /// zamanı) — koltuk DÜZENİNİ etkilemez, yalnızca izlenebilirlik/gösterim.
  Future<SeatPlanMeta> getSeatPlanMeta(final String stageId);
}

class SeatRemoteDataSourceImpl implements SeatRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Seats';

  /// Layout dışı meta alanlar — satır gibi okunmaz.
  static const _metaKeys = {
    'closedSeatsId',
    '_id',
    '_createdAt',
    '_updatedAt',
    'stageId',
    'stageName',
    'address',
  };

  const SeatRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId) async {
    if (stageId.isEmpty) throw Exception('Stage ID boş olamaz.');

    try {
      final doc = await _firestore.collection(_collection).doc(stageId).get();

      if (!doc.exists) throw Exception('Belirtilen sahne bulunamadı.');

      final data = doc.data();
      if (data == null || data.isEmpty) {
        throw Exception('Sahne verisi boş veya geçersiz.');
      }

      final seats = <String, List<String>>{};

      // Yeni şema: tek düz dizi `seatsId` (Halit / SES).
      final dynamic flat = data['seatsId'];
      if (flat is List) {
        seats['seatsId'] = flat.whereType<String>().toList();
      } else {
        // Eski şema: sıra adı → koltuk listesi
        data.forEach((final row, final seatList) {
          if (_metaKeys.contains(row)) {
            return;
          }
          if (seatList is List) {
            seats[row] = seatList.whereType<String>().toList();
          }
        });
      }

      if (seats.isEmpty) {
        throw Exception('Sahne üzerinde koltuk bulunamadı.');
      }

      return seats;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getSeatsByStage): ${e.message}');
    } catch (e) {
      throw Exception('Koltuklar alınamadı: $e');
    }
  }

  @override
  Future<SeatPlanMeta> getSeatPlanMeta(final String stageId) async {
    if (stageId.isEmpty) return SeatPlanMeta.empty;
    try {
      final doc = await _firestore.collection(_collection).doc(stageId).get();
      if (!doc.exists) return SeatPlanMeta.empty;
      final data = doc.data();
      if (data == null) return SeatPlanMeta.empty;

      String iso(final dynamic v) => v is Timestamp
          ? v.toDate().toIso8601String()
          : (v?.toString() ?? '');

      return SeatPlanMeta(
        stageId: (data['stageId'] as String?) ?? doc.id,
        stageName: (data['stageName'] as String?) ?? '',
        address: (data['address'] as String?) ?? '',
        createdAt: iso(data['_createdAt']),
        updatedAt: iso(data['_updatedAt']),
      );
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getSeatPlanMeta): ${e.message}');
    }
  }
}
