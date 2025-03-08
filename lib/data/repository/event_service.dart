import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/repository/seat_service.dart';
import '../../core/util/date_formatter.dart';

class EventService {
  final CollectionReference _firestore =
      FirebaseFirestore.instance.collection("Event");

  // Event ID'sine göre koltuk durumu kontrolü ve boş koltukların ilk defa eklenmesi
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    try {
      final DocumentSnapshot eventDoc = await _firestore.doc(eventId).get();

      if (eventDoc.exists) {
        final Map<String, dynamic> eventData =
            eventDoc.data()! as Map<String, dynamic>;

        // Eğer seats verisi boşsa, Seats koleksiyonundan verileri çek ve Event'e ekle
        if (eventData['seats'] == null || (eventData['seats'] as Map).isEmpty) {
          final Map<String, List<String>> stageSeats =
              await SeatService().getSeatsByStage(eventData['stageId']);
          final Map<String, Map<String, dynamic>> seatStatus = {};

          // Boş koltukları 'available' olarak işaretle
          stageSeats.forEach((final row, final seatList) {
            for (final seat in seatList) {
              seatStatus[seat] = {
                'status': 'available',
                'customerId': null
              }; // Koltuk durumu ve müşteri ID'si
            }
          });

          // Koltukları Event'e kaydet
          await _firestore.doc(eventId).update({
            'seats': seatStatus,
          });
        }
      } else {
        throw Exception('Etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error initializing event seats: $e');
    }
  }

  // Event ID'sine göre koltuk durumu
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(
      final String eventId) async {
    try {
      final DocumentSnapshot doc = await _firestore.doc(eventId).get();
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
        final Map<String, Map<String, dynamic>> seatStatus = {};

        if (data['seats'] is Map) {
          data['seats'].forEach((final seatId, final seatInfo) {
            if (seatInfo is Map<String, dynamic>) {
              seatStatus[seatId] =
                  seatInfo; // Koltuk durumu ve customerId içeren obje
            }
          });
        } else {
          throw ('Koltuk durumu geçerli bir harita değil.');
        }
        return seatStatus;
      } else {
        throw ('Belirtilen etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error fetching seat status: $e');
    }
  }

  // Belirli bir müşteri ID'sine göre alınmış koltukları getirir
  Future<List<String>> getPurchasedSeatsByCustomerId(
      final String eventId, final String customerId) async {
    try {
      final DocumentSnapshot doc = await _firestore.doc(eventId).get();

      if (doc.exists) {
        final Map<String, dynamic> eventData = doc.data()! as Map<String, dynamic>;

        if (eventData['seats'] != null) {
          final List<String> purchasedSeats = [];

          // Tüm koltuklar arasında müşteri ID'sine göre filtreleme yap
          eventData['seats'].forEach((final seatId, final seatInfo) {
            if (seatInfo['customerId'] == customerId) {
              purchasedSeats.add(seatId);
            }
          });

          return purchasedSeats;
        } else {
          throw ('Koltuk verisi bulunamadı.');
        }
      } else {
        throw ('Etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error fetching seats by customerId: $e');
    }
  }

  Future<void> updateSeatStatus(final String eventId, final String seatId, final String status,
      {final String? customerId}) async {
    try {
      final Map<String, dynamic> seatUpdate = {'status': status};

      // Eğer customerId belirtilmişse, koltuk bilgisine ekle
      if (customerId != null) {
        seatUpdate['customerId'] = customerId;
      }

      await _firestore.doc(eventId).update({
        'seats.$seatId': seatUpdate,
      });
    } catch (e) {
      throw Exception('Error updating seat status: $e');
    }
  }

  //Price StageId
  Future<String> getStageId(final String eventId) async {
    try {
      final docSnapshot = await _firestore.doc(eventId).get();

      if (!docSnapshot.exists) return throw Exception("Sahne verisi Alınamadı");

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      return eventData['stageId'] as String;
    } catch (error) {
      throw Exception(
          "Etkinlik Sahne verisi alınırken bir hata oluştu: $error");
    }
  }

  //Price Get
  Future<String?> getEventPrice(final String eventId) async {
    try {
      final docSnapshot = await _firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      return eventData['price'] as String;
    } catch (error) {
      throw Exception(
          "Etkinlik Tarih verisi alınırken bir hata oluştu: $error");
    }
  }

// Get Date and Time
  Future<Map<String, String>?> getEventDate(final eventId,
      {final bool formatWithMonthName = false}) async {
    try {
      final docSnapshot = await _firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      final date = eventData['date'] as String; // Sadece tarih alanını al
      return DateFormatter.parseFormattedDateTime(date,
          formatWithMonthName: formatWithMonthName);
    } catch (error) {
      throw Exception(
          "Etkinlik Tarih verisi alınırken bir hata oluştu: $error");
    }
  }

// Koltuk rezerve etme işlemi (müşteri ID'si ile birlikte)
  Future<void> reserveSeat(
      final String eventId, final String seatId, final String customerId) async {
    await _firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'reserved',
        'customerId': customerId, // Koltuğu rezerve eden kullanıcının ID'si
      }
    });
  }

// Koltuk rezervasyonu iptal etme işlemi
  Future<void> cancelReservation(final String eventId, final String seatId) async {
    await _firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'available',
        'customerId': null // Koltuk boş olduğunda customerId null olur
      }
    });
  }
}
