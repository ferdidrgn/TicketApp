import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SeatRemoteDataSource {
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId);
}

class SeatRemoteDataSourceImpl implements SeatRemoteDataSource {
  final FirebaseFirestore firestore;

  SeatRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Map<String, List<String?>?>?> getSeatsByStage(final String stageId) async {
    try {
      if (stageId.isEmpty) throw Exception('Stage ID boş olamaz.');

      final DocumentSnapshot doc = await firestore.collection('Seats').doc(stageId).get();
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
        final Map<String, List<String>> seats = {};
        data.forEach((final row, final seatList) {
          seats[row] = List<String>.from(seatList);
        });

        if (seats.isEmpty) throw Exception('Sahne bulunamadı.');
        return seats;
      } else throw Exception('Belirtilen sahne bulunamadı.');
    } catch (e) {
      throw Exception('Error fetching seats: $e');
    }
  }
}
