import 'package:cloud_firestore/cloud_firestore.dart';

class SeatService {
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('Seats');

  // Sahne ID'sine göre koltukları çekmek için bir fonksiyon
  Future<Map<String, List<String>>> getSeatsByStage(String stageId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.doc(stageId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, List<String>> seats = {};
        data.forEach((row, seatList) {
          seats[row] = List<String>.from(seatList);
        });
        return seats;
      } else {
        throw Exception('Belirtilen sahne bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error fetching seats: $e');
    }
  }

}
