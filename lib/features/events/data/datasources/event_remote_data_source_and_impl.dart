import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/features/events/data/models/event_model.dart';
import '../../../seat/data/datasources/seat_remote_data_source_and_impl.dart';

abstract class EventRemoteDataSource {
  Future<void> initializeAndGetEventSeats(final String eventId);

  Future<List<EventModel>> getEventsByIds(final List<String> eventIds);

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
  Future<List<EventModel>> getEventsByIds(final List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    try {
      final snapshot = await _eventCollection
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      return snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return EventModel.fromFirestore(data);
      }).toList();
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
    final ref = _eventCollection.doc(eventId);
    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw Exception('Etkinlik bulunamadı.');

        final data = snapshot.data();
        final seats = Map<String, dynamic>.from(data?['seats'] ?? {});

        // 🔥 3 BİLET KONTROLÜ (DB SEVİYESİNDE)
        int userSeatCount = 0;
        seats.forEach((final key, final value) {
          final seatMap = value as Map<String, dynamic>;
          if (seatMap['customerId'] == customerId &&
              (seatMap['status'] == 'reserved' || seatMap['status'] == 'sold'))
            userSeatCount++;
        });

        if (userSeatCount >= 3)
          throw Exception('Maksimum 3 bilet sınırına ulaştınız.');

        final seat = seats[seatId] as Map<String, dynamic>?;
        if (seat == null) throw Exception('Koltuk bulunamadı.');

        if (seat['status'] == 'available') {
          transaction.update(ref, {
            'seats.$seatId.status': 'reserved',
            'seats.$seatId.customerId': customerId,
            'seats.$seatId.reservedAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception('Bu koltuk artık müsait değil.');
        }
      });
      return true;
    } catch (e) {
      // 🔥 DÜZELTME: "Maksimum 3 bilet sınırına ulaştınız." veya "Bu koltuk
      // artık müsait değil." gibi anlamlı hatalar önceden burada yutulup
      // sadece konsola print ediliyordu; kullanıcıya `false` dönüyordu ve
      // seat_details.dart bu dönüş değerini hiç kontrol etmiyordu — yani
      // kullanıcı koltuğa dokunuyor, hiçbir şey olmuyor, NEDEN olmadığını
      // asla göremiyordu. Artık hata yukarı fırlatılıyor ki UI'daki
      // try/catch gerçek nedeni SnackBar ile gösterebilsin.
      print('Reservation Error: $e');
      rethrow;
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
      rethrow;
    }
  }

  @override
  Future<bool> confirmPurchase(final String eventId, final List<String> seatIds,
      final String customerId) async {
    _validateParams({'Event ID': eventId, 'Customer ID': customerId});
    if (seatIds.isEmpty) throw Exception('Seat IDs cannot be empty.');

    final ref = _eventCollection.doc(eventId);

    try {
      // 🔥 GÜVENLİK DÜZELTMESİ:
      // Önceki implementasyon, hangi koltukların gerçekten bu müşteri
      // tarafından 'reserved' durumunda olduğunu HİÇ KONTROL ETMEDEN
      // doğrudan 'sold' olarak yazıyordu (basit bir batch update).
      // Bu; (a) başka bir kullanıcının koltuğunun üzerine yazılabilmesine,
      // (b) süresi dolmuş/serbest kalmış bir koltuğun yine de "satılmış"
      // gibi işaretlenebilmesine, (c) client tarafından gönderilen seatId
      // listesine sunucu tarafında hiçbir doğrulama yapılmadan güvenilmesine
      // açık kapı bırakıyordu. Artık tek bir transaction içinde önce her
      // koltuğun durumu okunuyor, sadece bu müşteri tarafından 'reserved'
      // durumundaki koltuklar 'sold' yapılıyor; aksi halde işlem tamamen
      // geri alınıp (atomik) anlamlı bir hata fırlatılıyor.
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw Exception('Etkinlik bulunamadı.');

        final data = snapshot.data();
        final seats = Map<String, dynamic>.from(data?['seats'] ?? {});

        final List<String> invalidSeats = [];
        for (final id in seatIds) {
          final seat = seats[id] as Map<String, dynamic>?;
          final bool isMineAndReserved = seat != null &&
              seat['status'] == 'reserved' &&
              seat['customerId'] == customerId;
          if (!isMineAndReserved) invalidSeats.add(id);
        }

        if (invalidSeats.isNotEmpty)
          throw Exception(
              'Şu koltuklar artık sizin rezervasyonunuzda değil (süresi dolmuş '
              'veya başka biri tarafından alınmış olabilir): '
              '${invalidSeats.join(", ")}');

        for (final id in seatIds) {
          transaction.update(ref, {
            'seats.$id.status': 'sold',
            'seats.$id.customerId': customerId,
            'seats.$id.soldAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return true;
    } catch (e) {
      print('confirmPurchase failed: $e');
      rethrow;
    }
  }
}
