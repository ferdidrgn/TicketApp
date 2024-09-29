import 'package:cloud_firestore/cloud_firestore.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sahne ID'sine göre koltukları çekmek için bir fonksiyon
  Future<Map<String, List<String>>> getSeatsByStage(String stageId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Seats').doc(stageId).get();
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

  // Event ID'sine göre koltuk doluluk durumu
  Future<Map<String, String>> getSeatStatusByEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Event').doc(eventId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> seatStatus = {};
        // seats değerinin Map olduğundan emin olun
        if (data['seats'] is Map) {
          data['seats'].forEach((seatId, status) {
            seatStatus[seatId] = status; // available, reserved, sold vb.
          });
        } else {
          throw Exception('Koltuk durumu geçerli bir harita değil.');
        }
        return seatStatus;
      } else {
        throw Exception('Belirtilen etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error fetching seat status: $e');
    }
  }

  Future<void> reserveSeat(String eventId, String seatId) async {
    // Koltuğu rezerve et
    await _firestore.collection('Event').doc(eventId).update({
      'reservedSeats': FieldValue.arrayUnion([seatId]),
    });
  }

  Future<void> cancelReservation(String eventId, String seatId) async {
    // Rezervasyonu iptal et
    await _firestore.collection('Event').doc(eventId).update({
      'reservedSeats': FieldValue.arrayRemove([seatId]),
    });
  }

  Future<void> confirmPurchase(String eventId, List<String> selectedSeats) async {
    // Satın alma işlemini onayla
    await _firestore.collection('Event').doc(eventId).update({
      'purchasedSeats': FieldValue.arrayUnion(selectedSeats),
    });
  }

  Future<void> updateSeatStatus(String eventId, String seatId, String status) async {
    try {
      await _firestore.collection('Event').doc(eventId).update({
        'seats.$seatId': status,
      });
    } catch (e) {
      throw Exception('Error updating seat status: $e');
    }
  }
}
