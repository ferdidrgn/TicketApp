import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/util/date_formatter.dart';

abstract class EventRemoteDataSource {
  Future<void> initializeAndGetEventSeats(final String eventId);
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(final String eventId);
  Future<List<String>> getPurchasedSeatsByCustomerId(final String eventId, final String customerId);
  Future<void> updateSeatStatus(final String eventId, final String seatId, final String status, {final String? customerId});
  Future<String> getStageId(final String eventId);
  Future<String?> getEventPrice(final String eventId);
  Future<Map<String, String>?> getEventDate(final String eventId, {final bool formatWithMonthName = false});
  Future<void> reserveSeat(final String eventId, final String seatId, final String customerId);
  Future<void> cancelReservation(final String eventId, final String seatId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({
    required this.firestore
  });

  @override
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    try {
      final DocumentSnapshot eventDoc = await firestore.doc(eventId).get();

      if (eventDoc.exists) {
        final Map<String, dynamic> eventData =
        eventDoc.data()! as Map<String, dynamic>;

        if (eventData['seats'] == null || (eventData['seats'] as Map).isEmpty) {
          final Map<String, List<String>> stageSeats =
          await SeatService().getSeatsByStage(eventData['stageId']);
          final Map<String, Map<String, dynamic>> seatStatus = {};

          stageSeats.forEach((final row, final seatList) {
            for (final seat in seatList) {
              seatStatus[seat] = {
                'status': 'available',
                'customerId': null
              };
            }
          });

          await firestore.doc(eventId).update({
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

  @override
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(final String eventId) async {
    try {
      final DocumentSnapshot doc = await firestore.doc(eventId).get();
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
        final Map<String, Map<String, dynamic>> seatStatus = {};

        if (data['seats'] is Map) {
          data['seats'].forEach((final seatId, final seatInfo) {
            if (seatInfo is Map<String, dynamic>) {
              seatStatus[seatId] = seatInfo;
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

  @override
  Future<List<String>> getPurchasedSeatsByCustomerId(final String eventId, final String customerId) async {
    try {
      final DocumentSnapshot doc = await firestore.doc(eventId).get();

      if (doc.exists) {
        final Map<String, dynamic> eventData = doc.data()! as Map<String, dynamic>;

        if (eventData['seats'] != null) {
          final List<String> purchasedSeats = [];

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

  @override
  Future<void> updateSeatStatus(final String eventId, final String seatId, final String status, {final String? customerId}) async {
    try {
      final Map<String, dynamic> seatUpdate = {'status': status};

      if (customerId != null) {
        seatUpdate['customerId'] = customerId;
      }

      await firestore.doc(eventId).update({
        'seats.$seatId': seatUpdate,
      });
    } catch (e) {
      throw Exception('Error updating seat status: $e');
    }
  }

  @override
  Future<String> getStageId(final String eventId) async {
    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) throw Exception("Sahne verisi Alınamadı");

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      return eventData['stageId'] as String;
    } catch (error) {
      throw Exception("Etkinlik Sahne verisi alınırken bir hata oluştu: $error");
    }
  }

  @override
  Future<String?> getEventPrice(final String eventId) async {
    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      return eventData['price'] as String;
    } catch (error) {
      throw Exception("Etkinlik Tarih verisi alınırken bir hata oluştu: $error");
    }
  }

  @override
  Future<Map<String, String>?> getEventDate(final String eventId, {final bool formatWithMonthName = false}) async {
    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()! as Map<String, dynamic>;
      final date = eventData['date'] as String;
      return DateFormatter.parseFormattedDateTime(date, formatWithMonthName: formatWithMonthName);
    } catch (error) {
      throw Exception("Etkinlik Tarih verisi alınırken bir hata oluştu: $error");
    }
  }

  @override
  Future<void> reserveSeat(final String eventId, final String seatId, final String customerId) async {
    await firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'reserved',
        'customerId': customerId,
      }
    });
  }

  @override
  Future<void> cancelReservation(final String eventId, final String seatId) async {
    await firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'available',
        'customerId': null
      }
    });
  }
}
