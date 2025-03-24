import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/util/date_formatter.dart';
import '../seat/seat_remote_data_source_and_impl.dart';

abstract class EventRemoteDataSource {
  Future<void> initializeAndGetEventSeats(final String eventId);

  Future<Map<String, Map<String, dynamic>>?> getSeatStatusByEvent(
      final String eventId);

  Future<List<String?>?> getPurchasedSeatsByCustomerId(
      final String eventId, final String customerId);

  Future<void> updateSeatStatus(
      final String eventId, final String seatId, final String status,
      {final String? customerId});

  Future<String?> getStageId(final String eventId);

  Future<String?> getEventPrice(final String eventId);

  Future<Map<String, String>?> getEventDate(final String eventId,
      {final bool formatWithMonthName = false});

  Future<void> reserveSeat(
      final String eventId, final String seatId, final String customerId);

  Future<void> cancelReservation(final String eventId, final String seatId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    try {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

      final eventDoc = await firestore.doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found.');

      final eventData = eventDoc.data();
      if (eventData == null || eventData['seats'] == null || (eventData['seats'] as Map).isEmpty) {
        final stageSeats = await SeatRemoteDataSourceImpl(firestore: firestore)
            .getSeatsByStage(eventData?['stageId']);

        if (stageSeats == null || stageSeats.isEmpty) return;

        final seatStatus = <String, Map<String, dynamic>>{};

        for (final entry in stageSeats.entries) {
          final seats = entry.value;
          if (seats is List) {
            for (final seat in seats!.whereType<String>()) {
              seatStatus[seat] = {'status': 'available', 'customerId': null};
            }
          }
        }

        await firestore.doc(eventId).update({'seats': seatStatus});
      }
    } catch (e) {
      throw Exception('Error initializing event seats: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>?> getSeatStatusByEvent(
      final String eventId) async {
    try {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

      final doc = await firestore.doc(eventId).get();
      if (!doc.exists) throw Exception('Event not found.');

      final data = doc.data()!;
      final seatStatus = <String, Map<String, dynamic>>{};

      if (data['seats'] is Map) {
        data['seats'].forEach((final seatId, final seatInfo) {
          if (seatInfo is Map<String, dynamic>) seatStatus[seatId] = seatInfo;
        });
      } else
        throw Exception('Seat status is not a valid map.');
      return seatStatus;
    } catch (e) {
      throw Exception('Error fetching seat status: ${e.toString()}');
    }
  }

  @override
  Future<List<String?>?> getPurchasedSeatsByCustomerId(
      final String eventId, final String customerId) async {
    try {
      if (eventId.isEmpty || customerId.isEmpty)
        throw Exception('Event ID and Customer ID cannot be empty.');

      final DocumentSnapshot doc = await firestore.doc(eventId).get();

      if (doc.exists) {
        final Map<String, dynamic> eventData =
            doc.data()! as Map<String, dynamic>;

        if (eventData['seats'] != null) {
          final List<String> purchasedSeats = [];

          eventData['seats'].forEach((final seatId, final seatInfo) {
            if (seatInfo['customerId'] == customerId)
              purchasedSeats.add(seatId);
          });

          return purchasedSeats;
        } else {
          throw Exception('Seat data not found.');
        }
      } else {
        throw Exception('Event not found.');
      }
    } catch (e) {
      throw Exception('Error fetching seats by customerId: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSeatStatus(
      final String eventId, final String seatId, final String status,
      {final String? customerId}) async {
    if (eventId.isEmpty || seatId.isEmpty || status.isEmpty)
      throw Exception('Event ID, Seat ID, and Status cannot be empty.');

    try {
      final Map<String, dynamic> seatUpdate = {'status': status};

      if (customerId != null) seatUpdate['customerId'] = customerId;

      await firestore.doc(eventId).update({
        'seats.$seatId': seatUpdate,
      });
    } catch (e) {
      throw Exception('Error updating seat status: ${e.toString()}');
    }
  }

  @override
  Future<String?> getStageId(final String eventId) async {
    if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) throw Exception("Stage data not found");

      final eventData = docSnapshot.data()!;
      return eventData['stageId'] as String;
    } catch (error) {
      throw Exception("Error fetching stage data: ${error.toString()}");
    }
  }

  @override
  Future<String?> getEventPrice(final String eventId) async {
    if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()!;
      return eventData['price'] as String;
    } catch (error) {
      throw Exception("Error fetching event price: ${error.toString()}");
    }
  }

  @override
  Future<Map<String, String>?> getEventDate(final String eventId,
      {final bool formatWithMonthName = false}) async {
    try {
      final docSnapshot = await firestore.doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()!;
      final date = eventData['date'] as String;
      return DateFormatter.parseFormattedDateTime(date,
          formatWithMonthName: formatWithMonthName);
    } catch (error) {
      throw Exception("Error fetching event date: ${error.toString()}");
    }
  }

  @override
  Future<void> reserveSeat(final String eventId, final String seatId,
      final String customerId) async {
    await firestore.doc(eventId).update({
      'seats.$seatId': {
        'status': 'reserved',
        'customerId': customerId,
      }
    });
  }

  @override
  Future<void> cancelReservation(
      final String eventId, final String seatId) async {
    await firestore.doc(eventId).update({
      'seats.$seatId': {'status': 'available', 'customerId': null}
    });
  }
}
