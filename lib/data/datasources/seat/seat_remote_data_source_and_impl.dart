import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SeatRemoteDataSource {
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId);
}

class SeatRemoteDataSourceImpl implements SeatRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Seats';

  const SeatRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId) async {
    if (stageId.isEmpty) throw Exception('Stage ID boş olamaz.');

    try {
      final doc = await _firestore.collection(_collection).doc(stageId).get();

      if (!doc.exists) throw Exception('Belirtilen sahne bulunamadı.');

      final data = doc.data();
      if (data == null || data.isEmpty)
        throw Exception('Sahne verisi boş veya geçersiz.');

      // Map<String, List<String>> olarak dönüştür
      final seats = <String, List<String>>{};
      data.forEach((final row, final seatList) {
        if (seatList is List)
          seats[row] = seatList.whereType<String>().toList();
      });

      if (seats.isEmpty) throw Exception('Sahne üzerinde koltuk bulunamadı.');

      return seats;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getSeatsByStage): ${e.message}');
    } catch (e) {
      throw Exception('Koltuklar alınamadı: $e');
    }
  }
}
