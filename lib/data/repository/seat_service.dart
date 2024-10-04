import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/event.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Event? eventInfo;

  // Event ID'sine göre koltuk durumu kontrolü ve boş koltukların ilk defa eklenmesi
  Future<void> initializeEventSeats(String eventId, String stageId) async {
    try {
      DocumentSnapshot eventDoc =
          await _firestore.collection('Event').doc(eventId).get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;

        // Eğer seats verisi boşsa, Seats koleksiyonundan verileri çek ve Event'e ekle
        if (eventData['seats'] == null || (eventData['seats'] as Map).isEmpty) {
          Map<String, List<String>> stageSeats = await getSeatsByStage(stageId);
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
          await _firestore.collection('Event').doc(eventId).update({
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

  // Sahne ID'sine göre koltukları çekmek için bir fonksiyon
  Future<Map<String, List<String>>> getSeatsByStage(String stageId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Seats').doc(stageId).get();
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

  // Event ID'sine göre koltuk durumu
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(
      String eventId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Event').doc(eventId).get();
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

  //Price Get
  Future<String?> getEventPrice() async {
    try {
      return eventInfo?.price;
    } catch (e) {
      throw Exception('Fiyat verisi alınırken hata oluştu: $e');
    }
  }

  // Get Date and Time
  Future<Map<String, String>> getEventDate({bool formatWithMonthName = false}) async {
    try {
      if (eventInfo?.date == null) return {};

      List<String> parts = eventInfo!.date.split(',');
      List<String> dateParts = parts[0].split('.');

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);
      String timePart = parts[1];

      String formattedDate = formatWithMonthName
          ? "${_getMonthName(month)} $day" //Like "10 Ekim"
          : "$day.${month.toString().padLeft(2, '0')}.$year"; //Like "18.09.2024"

      return {"date": formattedDate, "time": timePart};
    } catch (e) {
      throw Exception("Tarihte bir hata oldu: $e");
    }
  }

  String _getMonthName(int month) {
    const Map<int, String> monthNames = {
      1: "Ocak", 2: "Şubat", 3: "Mart", 4: "Nisan",
      5: "Mayıs", 6: "Haziran", 7: "Temmuz", 8: "Ağustos",
      9: "Eylül", 10: "Ekim", 11: "Kasım", 12: "Aralık"
    };
    return monthNames[month] ?? '';
  }

// Koltuk rezerve etme işlemi (müşteri ID'si ile birlikte)
  Future<void> reserveSeat(
      String eventId, String seatId, String customerId) async {
    await _firestore.collection('Event').doc(eventId).update({
      'seats.$seatId': {
        'status': 'reserved',
        'customerId': customerId, // Koltuğu rezerve eden kullanıcının ID'si
      }
    });
  }

// Koltuk rezervasyonu iptal etme işlemi
  Future<void> cancelReservation(String eventId, String seatId) async {
    await _firestore.collection('Event').doc(eventId).update({
      'seats.$seatId': {
        'status': 'available',
        'customerId': null // Koltuk boş olduğunda customerId null olur
      }
    });
  }

  Future<void> updateSeatStatus(String eventId, String seatId, String status,
      {String? customerId}) async {
    try {
      Map<String, dynamic> seatUpdate = {'status': status};

      // Eğer customerId belirtilmişse, koltuk bilgisine ekle
      if (customerId != null) {
        seatUpdate['customerId'] = customerId;
      }

      await _firestore.collection('Event').doc(eventId).update({
        'seats.$seatId': seatUpdate,
      });
    } catch (e) {
      throw Exception('Error updating seat status: $e');
    }
  }

  Map<int, String> monthNames = {
    1: "Ocak",
    2: "Şubat",
    3: "Mart",
    4: "Nisan",
    5: "Mayıs",
    6: "Haziran",
    7: "Temmuz",
    8: "Ağustos",
    9: "Eylül",
    10: "Ekim",
    11: "Kasım",
    12: "Aralık"
  };
}
