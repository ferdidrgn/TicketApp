import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/event.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Event? eventInfo;
  
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

        eventInfo = Event(id: eventData['_id'], date: eventData['date'], price: eventData['price'], stageId: eventData['stageId'], seatStatus: eventData['seats']);
      } else {
        throw Exception('Etkinlik bulunamadı.');
      }
    } catch (e) {
      throw Exception('Error initializing event seats: $e');
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
              seatStatus[seatId] = seatInfo; // Koltuk durumu ve customerId içeren obje
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
  Future<Map<String, String>> getEventDate() async {
    try {
      if (eventInfo?.price == null) {
        return {};
      }

      List<String> dateParts = eventInfo!.price.split(' at ');
      DateTime parsedDate = _parseDate(dateParts);

      return {
        "date": _formatDate(parsedDate),
        "time": _formatTime(parsedDate)
      };
    } catch (e) {
      throw Exception("Tarihte bir hata oldu: $e");
    }
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


  DateTime _parseDate(List<String> dateParts) {
    String monthName = dateParts[0].split(' ')[0];
    int day = int.parse(dateParts[0].split(' ')[1]);
    int month = _getMonthNumber(monthName);
    String time = dateParts[1].split(' ')[0];

    return DateTime.parse("${DateTime.now().year}-$month-$day T$time");
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Ay ismini sayıya çeviren yardımcı fonksiyon
  int _getMonthNumber(String month) {
    Map<String, int> months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[month] ?? 1;
  }
}
