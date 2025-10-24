import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/util/date_formatter.dart';
import '../seat/seat_remote_data_source_and_impl.dart';

abstract class EventRemoteDataSource {
  Future<void> initializeAndGetEventSeats(final String eventId);

  Future<Map<String, String>?> getEventDate(final String eventId,
      {final bool formatWithMonthName = false});

  // --- YENİ ATOMİK VE REAL-TIME METODLAR ---

  /// Koltuk durumlarını anlık olarak dinler.
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  /// Bir koltuğu 'reserved' olarak işaretlemeyi dener.
  /// Sadece 'available' ise başarılı olur (true döner).
  Future<bool> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  /// 'reserved' durumdaki bir koltuğu 'available' yapar.
  /// Sadece rezervasyonu yapan müşteri iptal edebilir.
  Future<void> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  /// Seçilen koltukları 'sold' olarak işaretler.
  Future<void> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> initializeAndGetEventSeats(final String eventId) async {
    try {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

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

        for (final entry in stageSeats.entries) {
          final seats = entry.value;
          if (seats is List) {
            for (final seat in seats!.whereType<String>())
              seatStatus[seat] = {'status': 'available', 'customerId': null};
          }
        }

        await FirebaseFirestore.instance
            .collection('Event')
            .doc(eventId)
            .update({'seats': seatStatus});
      }
    } catch (e) {
      throw Exception('Error initializing event seats: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, String>?> getEventDate(final String eventId,
      {final bool formatWithMonthName = false}) async {
    try {
      final docSnapshot =
          await firestore.collection('Event').doc(eventId).get();

      if (!docSnapshot.exists) return null;

      final eventData = docSnapshot.data()!;
      final date = eventData['date'] as String?;

      if (date == null) return null;

      return DateFormatter.parseFormattedDateTime(date,
          formatWithMonthName: formatWithMonthName);
    } catch (error) {
      throw Exception("Error fetching event date: ${error.toString()}");
    }
  }

  /// Koltuk durumlarını tek seferlik çekmek YERİNE anlık dinler.
  /// UI bu stream'i dinleyecek.
  @override
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId) {
    if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

    try {
      final docStream = firestore.collection('Event').doc(eventId).snapshots();

      return docStream.asyncMap((final doc) async {
        if (!doc.exists) throw Exception('Event not found.');

        final data = doc.data();

        // Eğer seats yoksa veya boşsa, initialize et ve BEKLEYEREk tekrar oku
        if (data == null || data['seats'] == null || data['seats'] is! Map) {
          try {
            await initializeAndGetEventSeats(eventId);

            // Initialize ettikten sonra güncel veriyi al
            final updatedDoc =
                await firestore.collection('Event').doc(eventId).get();
            final updatedData = updatedDoc.data();

            if (updatedData == null || updatedData['seats'] == null)
              return <String, Map<String, dynamic>>{};

            return _parseSeatStatus(
                updatedData['seats'] as Map<String, dynamic>);
          } catch (e) {
            return <String, Map<String, dynamic>>{};
          }
        }

        // Data zaten varsa direkt parse et
        final seatsMap = data['seats'] as Map<String, dynamic>;
        return _parseSeatStatus(seatsMap);
      });
    } catch (e) {
      return Stream.error(
          Exception('Error fetching seat status stream: ${e.toString()}'));
    }
  }

// Helper method
  Map<String, Map<String, dynamic>> _parseSeatStatus(
      final Map<String, dynamic> seatsMap) {
    final seatStatus = <String, Map<String, dynamic>>{};

    seatsMap.forEach((final seatId, final seatInfo) {
      if (seatInfo is Map<String, dynamic>) {
        seatStatus[seatId] = seatInfo;
      }
    });

    return seatStatus;
  }

  /// BİR KOLTUĞU GÜVENLİ BİR ŞEKİLDE REZERVE ETME (ATOMIC)
  @override
  Future<bool> attemptReservation(final String eventId, final String seatId,
      final String customerId) async {
    if (eventId.isEmpty || seatId.isEmpty || customerId.isEmpty)
      throw Exception('Event ID, Seat ID, and Customer ID cannot be empty.');

    final eventRef = firestore.collection('Event').doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(eventRef);

        if (!snapshot.exists) throw Exception("Event not found!");

        final data = snapshot.data();
        if (data == null ||
            data['seats'] == null ||
            data['seats'][seatId] == null)
          throw Exception("Seat data not found or event not initialized.");

        final seatData = data['seats'][seatId] as Map<String, dynamic>;
        final currentStatus = seatData['status'] as String?;

        if (currentStatus == 'available') {
          transaction.update(eventRef, {
            'seats.$seatId.status': 'reserved',
            'seats.$seatId.customerId': customerId,
            'seats.$seatId.reservedAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception("Seat is not available.");
        }
      });
      return true;
    } catch (e) {
      print("Reservation failed: $e");
      return false;
    }
  }

  /// BİR REZERVASYONU GÜVENLİ BİR ŞEKİLDE İPTAL ETME (ATOMIC)
  @override
  Future<void> releaseReservation(final String eventId, final String seatId,
      final String customerId) async {
    if (eventId.isEmpty || seatId.isEmpty || customerId.isEmpty) {
      throw Exception('Event ID, Seat ID, and Customer ID cannot be empty.');
    }

    final eventRef = firestore.collection('Event').doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(eventRef);

        if (!snapshot.exists) throw Exception("Event not found!");

        final data = snapshot.data();
        if (data == null ||
            data['seats'] == null ||
            data['seats'][seatId] == null) {
          throw Exception("Seat data not found.");
        }

        final seatData = data['seats'][seatId] as Map<String, dynamic>;
        final currentStatus = seatData['status'] as String?;
        final currentCustomerId = seatData['customerId'] as String?;

        if (currentStatus == 'reserved' && currentCustomerId == customerId) {
          transaction.update(eventRef, {
            'seats.$seatId.status': 'available',
            'seats.$seatId.customerId': null,
            'seats.$seatId.reservedAt': null,
          });
        }
      });
    } catch (e) {
      print("Error releasing reservation: $e");
    }
  }

  /// ÖDEME SONRASI KOLTUKLARI 'SOLD' OLARAK İŞARETLEME (BATCHED WRITE)
  @override
  Future<void> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId) async {
    if (eventId.isEmpty || seatIds.isEmpty || customerId.isEmpty)
      throw Exception('Invalid data for confirmation.');

    final eventRef = firestore.collection('Event').doc(eventId);
    final batch = firestore.batch();

    for (final seatId in seatIds) {
      batch.update(eventRef, {
        'seats.$seatId.status': 'sold',
        'seats.$seatId.customerId': customerId,
        'seats.$seatId.reservedAt': null,
      });
    }
    await batch.commit();
  }
}
