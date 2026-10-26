import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/features/events/data/models/event_model.dart';
import '../../domain/repositories/event_repository.dart' show kAdminBlockCustomerId;

abstract class EventRemoteDataSource {
  /// ➕ Admin panelinden yeni bir seans (Event) oluşturur — `showId`,
  /// `stageId`, `date`, `price` gerçek alanlardır; `seats` boş map olarak
  /// başlar ve ilk koltuk seçimi ekranı açıldığında
  /// `initializeAndGetEventSeats` tarafından sahnenin gerçek koltuk
  /// düzeninden doldurulur (bkz. `_ensureSeatsInitialized`).
  Future<bool> addEvent(final EventModel event);

  Future<List<EventModel>> getEventsByIds(final List<String> eventIds);

  Future<List<EventModel>> getEventsByShowIds(final List<String> showIds);

  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  /// 🛠️ Admin koltuk denetimi (Phase 2).
  Future<bool> adminSetSeatBlocked(
      final String eventId, final String seatId, final bool blocked);
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

  // ---------- Interface Methods ----------

  @override
  Future<bool> addEvent(final EventModel event) async {
    try {
      // Show'daki addShow ile aynı desen: önce dökümanı oluştur, sonra
      // Firestore'un verdiği gerçek ID'yi dökümanın kendisine yazar.
      final data = event.toFirestore()..remove('_id');
      final docRef = await _eventCollection.add(data);
      await docRef.update({'_id': docRef.id});
      return true;
    } catch (e) {
      throw Exception('Add event failed: $e');
    }
  }

  /// Firestore 'whereIn' sorgusu en fazla 30 eleman alır — bkz.
  /// `show_remote_data_source_and_impl.dart`'taki `getShowsByIds` (aynı
  /// düzeltme, aynı gerekçe). Bir ID listesini 30'luk parçalara böler.
  List<List<String>> _chunkIds(final List<String> ids) {
    const chunkSize = 30;
    final uniqueIds = ids.toSet().toList();
    return [
      for (var i = 0; i < uniqueIds.length; i += chunkSize)
        uniqueIds.sublist(
            i, i + chunkSize > uniqueIds.length ? uniqueIds.length : i + chunkSize),
    ];
  }

  @override
  Future<List<EventModel>> getEventsByIds(final List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    try {
      // 🔥 DÜZELTME: Eski kod tüm `eventIds` listesini tek bir `whereIn`
      // sorgusuna gönderiyordu. Bir gösterinin (ya da keşfet/anasayfa gibi
      // birçok gösteriyi birleştiren bir ekranın) 30'dan fazla etkinlik
      // ID'si topladığı an Firestore 'invalid-argument' hatası fırlatıyor
      // ve bu Future'ı tüketen sayfa (ör. mobil Keşfet) kalıcı bir hata/boş
      // durumda kilitleniyordu. Artık `getShowsByIds` ile aynı desende
      // 30'luk parçalara bölünüp paralel çekiliyor.
      final chunks = _chunkIds(eventIds);
      final snapshots = await Future.wait(chunks.map((final chunk) =>
          _eventCollection.where(FieldPath.documentId, whereIn: chunk).get()));

      return snapshots
          .expand((final snapshot) => snapshot.docs.map((final doc) {
                final data = doc.data();
                data['_id'] = doc.id;
                return EventModel.fromFirestore(data);
              }))
          .toList();
    } catch (e) {
      throw Exception('getEventsByIds failed: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByShowIds(
      final List<String> showIds) async {
    if (showIds.isEmpty) return [];
    try {
      // 🔥 DÜZELTME: Aynı >30 eleman `whereIn` hatası burada da vardı —
      // bu metot tam olarak mobil Keşfet sayfasının veri zincirinde
      // (`eventsByShowIdsProvider` -> `_activeShowIdsFromEvents` /
      // `upcomingNearbyEventsProvider`) kullanılıyor. Veritabanında 30'dan
      // fazla gösteri olduğu an (ya da `showsActiveFirstProvider`/
      // `activeShowsProvider`'ın `isLimit:false` çağrıları tüm gösterileri
      // çektiğinde) bu sorgu senkron olmayan bir Firestore hatasıyla
      // reddediliyor, bu da Keşfet'in olay listesini ("Etkinlikler
      // yüklenemedi") her seferinde hataya düşürüyordu — kullanıcının
      // tarif ettiği "sayfa hiç açılmıyor" hissinin en olası kök nedeni.
      final chunks = _chunkIds(showIds);
      final snapshots = await Future.wait(chunks.map((final chunk) =>
          _eventCollection.where('showId', whereIn: chunk).get()));

      return snapshots
          .expand((final snapshot) => snapshot.docs.map((final doc) {
                final data = doc.data();
                data['_id'] = doc.id;
                return EventModel.fromFirestore(data);
              }))
          .toList();
    } catch (e) {
      throw Exception('getEventsByShowIds failed: $e');
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

      // Koltuk haritası artık YALNIZCA sunucu (holdSeats Cloud Function)
      // tarafından üretilir/yazılır; istemci yazamaz. Henüz üretilmediyse boş
      // döner — ekran sahne planından (Seats/{stageId}) çizer.
      if (data == null || data['seats'] == null || data['seats'] is! Map)
        return <String, Map<String, dynamic>>{};

      return _parseSeatStatus(Map<String, dynamic>.from(data['seats']));
    });
  }

  @override
  Future<bool> adminSetSeatBlocked(
      final String eventId, final String seatId, final bool blocked) async {
    _validateParams({'Event ID': eventId, 'Seat ID': seatId});

    final ref = _eventCollection.doc(eventId);

    try {
      await firestore.runTransaction((final transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw Exception('Etkinlik bulunamadı.');

        final data = snapshot.data();
        final seat = _getSeatData(data!, seatId);

        if (blocked) {
          // Sadece gerçekten boş/müsait bir koltuk bloke edilebilir —
          // gerçek bir müşterinin 'reserved'/'sold' koltuğunun üzerine asla
          // yazılmaz (satış verisini bozmamak için).
          if (seat['status'] != 'available')
            throw Exception(
                'Sadece müsait koltuklar bloke edilebilir (bu koltuk '
                '"${seat['status']}" durumunda).');

          transaction.update(ref, {
            'seats.$seatId.status': 'sold',
            'seats.$seatId.customerId': kAdminBlockCustomerId,
            'seats.$seatId.soldAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Sadece BİZİM koyduğumuz admin bloğu geri alınabilir — gerçek bir
          // satışı (gerçek customerId'li 'sold') yanlışlıkla asla serbest
          // bırakmaz.
          if (seat['customerId'] != kAdminBlockCustomerId)
            throw Exception(
                'Bu koltuk bir admin bloğu değil, gerçek bir satış/'
                'rezervasyon içeriyor — buradan serbest bırakılamaz.');

          transaction.update(ref, {
            'seats.$seatId.status': 'available',
            'seats.$seatId.customerId': null,
            'seats.$seatId.soldAt': null,
          });
        }
      });
      return true;
    } catch (e) {
      print('adminSetSeatBlocked failed: $e');
      rethrow;
    }
  }
}
