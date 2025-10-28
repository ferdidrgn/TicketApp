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

  CollectionReference<Map<String, dynamic>> get _eventCollection =>
      firestore.collection('Event');

  // ---------- Utility & Validation ----------

  void _validateParams(final Map<String, String> params) {
    for (final entry in params.entries)
      if (entry.value.trim().isEmpty)
        throw Exception('${entry.key} cannot be empty.');
  }

  Map<String, Map<String, dynamic>> _parseSeatStatus(
          final Map<String, dynamic> seatsMap) =>
      seatsMap.map((final key, final value) =>
          MapEntry(key, Map<String, dynamic>.from(value)));

  Map<String, dynamic> _getSeatData(
      final Map<String, dynamic> eventData, final String seatId) {
    final seatData = eventData['seats']?[seatId];
    if (seatData is! Map<String, dynamic>)
      throw Exception("Invalid or missing seat data for $seatId.");
    return seatData;
  }

  Future<Map<String, Map<String, dynamic>>> _ensureSeatsInitialized(
      final String eventId) async {
    await initializeAndGetEventSeats(eventId);
    final doc = await _eventCollection.doc(eventId).get();
    final data = doc.data();
    if (data == null || data['seats'] == null) return {};
    return _parseSeatStatus(Map<String, dynamic>.from(data['seats']));
  }

  // ---------- Interface Methods ----------

  @override
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    _validateParams({'Event ID': eventId});

    try {
      final doc = await _eventCollection.doc(eventId).get();
      if (!doc.exists) throw Exception('Event not found.');

      final data = doc.data();
      final existingSeats = data?['seats'] as Map<String, dynamic>?;

      // Eğer koltuklar yoksa, sahneye göre yükle
      if (existingSeats == null || existingSeats.isEmpty) {
        final stageSeats = await SeatRemoteDataSourceImpl(firestore: firestore)
            .getSeatsByStage(data?['stageId']);
        if (stageSeats == null || stageSeats.isEmpty) return;

        final seatStatus = <String, Map<String, dynamic>>{};
        for (final seats in stageSeats.values) {
          for (final seat in (seats! as List).whereType<String>())
            seatStatus[seat] = {'status': 'available', 'customerId': null};
        }

        await _eventCollection.doc(eventId).update({'seats': seatStatus});
      }
    } catch (e) {
      throw Exception('initializeAndGetEventSeats failed: $e');
    }
  }

  @override
  Future<List<EventModel?>?> getEventsByIds(final List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    try {
      final snapshot = await _eventCollection
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      return snapshot.docs
          .map((final doc) => EventModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('getEventsByIds failed: $e');
    }
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId) {
    _validateParams({'Event ID': eventId});

    return _eventCollection
        .doc(eventId)
        .snapshots()
        .asyncMap((final doc) async {
      if (!doc.exists) throw Exception('Event not found.');
      final data = doc.data();

      if (data == null || data['seats'] == null || data['seats'] is! Map)
        return await _ensureSeatsInitialized(eventId);

      return _parseSeatStatus(Map<String, dynamic>.from(data['seats']));
    });
  }

  @override
  Future<bool> attemptReservation(final String eventId, final String seatId,
      final String customerId) async {
    _validateParams({
      'Event ID': eventId,
      'Seat ID': seatId,
      'Customer ID': customerId,
    });

    final ref = _eventCollection.doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw Exception('Event not found.');

        final data = snapshot.data();
        if (data == null) throw Exception('Event data is null.');

        final seat = _getSeatData(data, seatId);
        if (seat['status'] == 'available' && seat['customerId'] == null) {
          transaction.update(ref, {
            'seats.$seatId.status': 'reserved',
            'seats.$seatId.customerId': customerId,
            'seats.$seatId.reservedAt': FieldValue.serverTimestamp(),
            //ya da DateTime.now().toIso8601String()
          });
        } else {
          throw Exception('Seat is not available.');
        }
      });
      return true;
    } catch (e) {
      print('attemptReservation failed: $e');
      return false;
    }
  }

  @override
  Future<bool> releaseReservation(final String eventId, final String seatId,
      final String customerId) async {
    _validateParams({
      'Event ID': eventId,
      'Seat ID': seatId,
      'Customer ID': customerId,
    });

    final ref = _eventCollection.doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw Exception('Event not found.');

        final data = snapshot.data();
        final seat = _getSeatData(data!, seatId);

        if (seat['status'] == 'reserved' && seat['customerId'] == customerId)
          transaction.update(ref, {
            'seats.$seatId.status': 'available',
            'seats.$seatId.customerId': null,
            'seats.$seatId.reservedAt': null,
          });
      });
      return true;
    } catch (e) {
      print('releaseReservation failed: $e');
      return false;
    }
  }

  @override
  Future<bool> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId) async {
    _validateParams({'Event ID': eventId, 'Customer ID': customerId});
    if (seatIds.isEmpty) throw Exception('Seat IDs cannot be empty.');

    final ref = _eventCollection.doc(eventId);
    final batch = firestore.batch();

    for (final id in seatIds)
      batch.update(ref, {
        'seats.$id.status': 'sold',
        'seats.$id.customerId': customerId,
        'seats.$id.reservedAt': FieldValue.serverTimestamp(),
        //ya da DateTime.now().toIso8601String()
      });

    try {
      await batch.commit();
      return true;
    } catch (e) {
      print('confirmPurchase failed: $e');
      return false;
    }
  }
}
