import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/event.dart';
import 'package:ticketapp/data/repository/seat_service.dart';
import '../../core/util/date_formatter.dart';

class EventService {
  final CollectionReference _firestore =
      FirebaseFirestore.instance.collection("Event");
  late Event? eventInfo;

  // Event ID'sine göre koltuk durumu kontrolü ve boş koltukların ilk defa eklenmesi
  Future<void> initializeAndGetEventSeats(String eventId, String stageId) async {
    try {
      DocumentSnapshot eventDoc = await _firestore.doc(eventId).get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;

        // Eğer seats verisi boşsa, Seats koleksiyonundan verileri çek ve Event'e ekle
        if (eventData['seats'] == null || (eventData['seats'] as Map).isEmpty) {
          Map<String, List<String>> stageSeats =
              await SeatService().getSeatsByStage(stageId);
          Map<String, Map<String, dynamic>> seatStatus = {};

          // Boş koltukları 'available' olarak işaretle
          stageSeats.forEach((row, seatList) {
            for (var seat in seatList) {
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

        eventInfo = Event(
            id: eventData['_id'],
            date: eventData['date'],
            price: eventData['price'],
            stageId: eventData['stageId'],
            seatStatus: eventData['seats']);
      } else {
        throw Exception('Etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error initializing event seats: $e');
    }
  }

  Event? getEvent(){
    try {
     return eventInfo;
    } catch (e) {
      throw Exception('Event verilerinde bir hata oluştu: $e');
    }
  }

  // Event ID'sine göre koltuk durumu
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(
      String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.doc(eventId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, Map<String, dynamic>> seatStatus = {};

        if (data['seats'] is Map) {
          data['seats'].forEach((seatId, seatInfo) {
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

  Future<void> updateSeatStatus(String eventId, String seatId, String status,
      {String? customerId}) async {
    try {
      Map<String, dynamic> seatUpdate = {'status': status};

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

  //Price Get
  Future<String?> getEventPrice() async {
    try {
      return eventInfo?.price;
    } catch (e) {
      throw Exception('Fiyat verisi alınırken hata oluştu: $e');
    }
  }

  // Get Date and Time
  Future<Map<String, String>> getEventDate(
      {bool formatWithMonthName = false}) async {
    try {
      if (eventInfo?.date == null) return {};
      return DateFormatter.parseFormattedDateTime(eventInfo!.date,
          formatWithMonthName: formatWithMonthName);
    } catch (e) {
      throw Exception("Tarihte bir hata oldu: $e");
    }
  }

// Koltuk rezerve etme işlemi (müşteri ID'si ile birlikte)
  Future<void> reserveSeat(
      String eventId, String seatId, String customerId) async {
    await _firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'reserved',
        'customerId': customerId, // Koltuğu rezerve eden kullanıcının ID'si
      }
    });
  }

// Koltuk rezervasyonu iptal etme işlemi
  Future<void> cancelReservation(String eventId, String seatId) async {
    await _firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'available',
        'customerId': null // Koltuk boş olduğunda customerId null olur
      }
    });
  }
}
