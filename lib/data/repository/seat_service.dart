import 'package:cloud_firestore/cloud_firestore.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sahne ID'sine göre koltukları çekmek için bir fonksiyon
  Future<Map<String, List<String>>> getSeatsByStage(String stageId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Seats').doc(stageId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Koltukları Map olarak döndürüyoruz
        Map<String, List<String>> seats = {};
        data.forEach((row, seatList) {
          seats[row] = List<String>.from(seatList);
        });
        return seats;
      } else {
        print('Belirtilen sahne bulunamadı.');
        return {};
      }
    } catch (e) {
      print('Koltukları çekerken hata oluştu: $e');
      return {};
    }
  }

  // Event ID'sine göre koltuk doluluk durumu
  Future<Map<String, String>> getSeatStatusByEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Event').doc(eventId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> seatStatus = {};
        data['seats'].forEach((seatId, status) {
          seatStatus[seatId] = status; // sold, available vb.
        });
        return seatStatus;
      } else {
        print('Belirtilen etkinlik bulunamadı.');
        return {};
      }
    } catch (e) {
      print('Koltuk durumunu çekerken hata oluştu: $e');
      return {};
    }
  }
}
