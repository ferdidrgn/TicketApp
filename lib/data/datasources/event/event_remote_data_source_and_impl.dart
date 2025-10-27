import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/event_model.dart';
import '../seat/seat_remote_data_source_and_impl.dart';

abstract class EventRemoteDataSource {
  Future<void> initializeAndGetEventSeats(final String eventId);

  Future<List<EventModel?>?> getEventsByIds(final List<String> eventIds);

  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  Future<bool> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  Future<bool> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  Future<bool> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({required this.firestore});

  // ---------------- HELPER METHODS ----------------

  void _validateParams(final Map<String, String> params) =>
      params.forEach((final key, final value) {
        if (value.isEmpty) throw Exception('$key cannot be empty.');
      });

  Map<String, Map<String, dynamic>> _parseSeatStatus(
          final Map<String, dynamic> seatsMap) =>
      Map.fromEntries(
        seatsMap.entries
            .where((final e) => e.value is Map<String, dynamic>)
            .map((final e) => MapEntry(e.key, e.value as Map<String, dynamic>)),
      );

  Map<String, dynamic> _getSeatData(
      final Map<String, dynamic> eventData, final String seatId) {
    final seatData = eventData['seats']?[seatId];
    if (seatData == null || seatData is! Map<String, dynamic>)
      throw Exception("Seat data not found or is invalid.");
    return seatData;
  }

  Future<Map<String, Map<String, dynamic>>> _ensureSeatsInitialized(
      final String eventId) async {
    await initializeAndGetEventSeats(eventId);
    final updatedDoc = await firestore.collection('Event').doc(eventId).get();
    final updatedData = updatedDoc.data();
    if (updatedData == null || updatedData['seats'] == null) return {};
    return _parseSeatStatus(updatedData['seats'] as Map<String, dynamic>);
  }

  // ---------------- INTERFACE METHODS ----------------

  @override
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    _validateParams({'Event ID': eventId});

    try {
      final eventDoc = await firestore.collection('Event').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found.');

      final eventData = eventDoc.data();

      if (eventData == null ||
          eventData['seats'] == null ||
          (eventData['seats'] as Map).isEmpty) {
        final stageSeats = await SeatRemoteDataSourceImpl(firestore: firestore)
            .getSeatsByStage(eventData?['stageId']);

        if (stageSeats == null || stageSeats.isEmpty) return;

        final seatStatus = <String, Map<String, dynamic>>{};
        stageSeats.forEach((final _, final seats) {
          (seats as List?)?.whereType<String>().forEach((final seat) {
            seatStatus[seat] = {'status': 'available', 'customerId': null};
          });
        });

        await firestore
            .collection('Event')
            .doc(eventId)
            .update({'seats': seatStatus});
      }
    } catch (e) {
      throw Exception('Error initializing event seats: ${e.toString()}');
    }
  }

  // EventRemoteDataSourceImpl içinde

  @override
  Future<List<EventModel?>?> getEventsByIds(final List<String> eventIds) async {
    try {
      if (eventIds.isEmpty) throw Exception('Event ID cannot be empty.');

      final result = await firestore
          .collection('Event')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      if (result.docs.isEmpty)
        return []; // Döküman bulunamazsa boş liste döndür
      return _convertQuerySnapshotToEventList(result);
    } catch (error) {
      throw Exception('Error fetching events: $error');
    }
  }

  List<EventModel?> _convertQuerySnapshotToEventList(
      final QuerySnapshot snapshot) {
    return snapshot.docs.map((final doc) {
      return EventModel.fromFirestore(doc.data()! as Map<String, dynamic>);
    }).toList();
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId) {
    _validateParams({'Event ID': eventId});

    try {
      final docStream = firestore.collection('Event').doc(eventId).snapshots();

      return docStream.asyncMap((final doc) async {
        if (!doc.exists) throw Exception('Event not found.');
        final data = doc.data();

        // Eğer seats yoksa veya boşsa, initialize et ve BEKLEYEREk tekrar oku
        if (data == null || data['seats'] == null || data['seats'] is! Map)
          return await _ensureSeatsInitialized(eventId);

        return _parseSeatStatus(data['seats'] as Map<String, dynamic>);
      });
    } catch (e) {
      return Stream.error(
          Exception('Error fetching seat status stream: ${e.toString()}'));
    }
  }

  @override
  Future<bool> attemptReservation(final String eventId, final String seatId,
      final String customerId) async {
    _validateParams(
        {'Event ID': eventId, 'Seat ID': seatId, 'Customer ID': customerId});

    final eventRef = firestore.collection('Event').doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) throw Exception("Event not found!");

        final data = snapshot.data();
        if (data == null) throw Exception("Event data is null.");

        final seatData = _getSeatData(data, seatId);
        final currentStatus = seatData['status'] as String?;
        final currentCustomerId = seatData['customerId'] as String?;

        if (currentStatus == 'available' && currentCustomerId == null)
          transaction.update(eventRef, {
            'seats.$seatId.status': 'reserved',
            'seats.$seatId.customerId': customerId,
            'seats.$seatId.reservedAt': FieldValue.serverTimestamp(),
          });
        else
          throw Exception("Seat is not available.");
      });
      return true;
    } catch (e) {
      print("Reservation failed: $e");
      return false;
    }
  }

  @override
  Future<bool> releaseReservation(final String eventId, final String seatId,
      final String customerId) async {
    _validateParams(
        {'Event ID': eventId, 'Seat ID': seatId, 'Customer ID': customerId});

    final eventRef = firestore.collection('Event').doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) throw Exception("Event not found!");

        final data = snapshot.data();
        if (data == null || data['seats'] == null)
          throw Exception("Seat data not found.");
        final seatData = _getSeatData(data, seatId);

        final currentStatus = seatData['status'] as String?;
        final currentCustomerId = seatData['customerId'] as String?;

        if (currentStatus == 'reserved' && currentCustomerId == customerId)
          transaction.update(eventRef, {
            'seats.$seatId.status': 'available',
            'seats.$seatId.customerId': null,
            'seats.$seatId.reservedAt': null,
          });
      });
      return true;
    } catch (e) {
      print("Error releasing reservation: $e");
      return false;
    }
  }

  @override
  Future<bool> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId) async {
    _validateParams({'Event ID': eventId, 'Customer ID': customerId});
    if (seatIds.isEmpty) throw Exception('Seat IDs cannot be empty.');

    final eventRef = firestore.collection('Event').doc(eventId);
    final batch = firestore.batch();

    for (final seatId in seatIds)
      batch.update(eventRef, {
        'seats.$seatId.status': 'sold',
        'seats.$seatId.customerId': customerId,
        'seats.$seatId.reservedAt': null,
      });

    await batch.commit();
    return true;
  }
}
