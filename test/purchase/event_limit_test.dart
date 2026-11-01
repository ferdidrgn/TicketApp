import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/data/datasources/purchase_remote_data_source_and_impl.dart';
import 'package:ticketapp/features/purchase/domain/entities/purchase_entities.dart';
import 'package:ticketapp/features/purchase/presentation/providers/purchase_provider.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import 'purchase_test_helpers.dart';

FirebaseFunctionsException ex(final String code,
        {final String? message, final Object? details}) =>
    FirebaseFunctionsException(
        message: message ?? 'x', code: code, details: details);

void main() {
  group('EventQuota', () {
    test('sunucu cevabı okunur; özet metni', () {
      final q = EventQuota.tryParse(
          {'limit': 3, 'used': 1, 'remaining': 2, 'held': 0})!;
      expect(q.summary, 'Bu etkinlikte 1/3 biletin var. 2 bilet daha alabilirsin.');
      expect(q.isFull, isFalse);
      final full = EventQuota.tryParse({'limit': 3, 'used': 3, 'remaining': 0})!;
      expect(full.isFull, isTrue);
      expect(full.summary, contains('bilet hakkını doldurdun'));
    });

    test('bozuk / eksik cevap null (arayüz varsayılana düşer)', () {
      expect(EventQuota.tryParse(null), isNull);
      expect(EventQuota.tryParse({'limit': 'x'}), isNull);
      expect(EventQuota.tryParse({'limit': 0, 'used': 0}), isNull);
    });
  });

  group('mapPurchaseError tablosu (Türkçe, teknik sızıntı yok)', () {
    PurchaseException m(final Object e) => mapPurchaseError(e);

    test('EVENT_LIMIT', () {
      final r = m(ex('resource-exhausted', details: {
        'code': 'EVENT_LIMIT', 'limit': 3, 'used': 3, 'remaining': 0,
      }));
      expect(r.code, kEventLimitCode);
      expect(r.message, contains('en fazla 3 bilet'));
      final srv = m(ex('resource-exhausted',
          message:
              'Bu etkinlik için en fazla 3 bilet alabilirsin. Şu an 2 biletin var; 1 bilet daha alabilirsin.',
          details: {'code': 'EVENT_LIMIT', 'limit': 3, 'used': 2}));
      expect(srv.message, startsWith('Bu etkinlik için en fazla 3'));
    });

    test('PHONE_REQUIRED / ACCOUNT_DELETION_PENDING / SALT_MISSING', () {
      expect(m(ex('failed-precondition', details: {'code': 'PHONE_REQUIRED'})).code,
          kPhoneRequiredCode);
      expect(
          m(ex('failed-precondition', details: {'code': 'ACCOUNT_DELETION_PENDING'}))
              .code,
          kDeletionPendingPurchaseCode);
      final s = m(ex('unavailable', details: {'code': 'SALT_MISSING'}));
      expect(s.code, kServiceUnavailableCode);
      expect(s.message, kServiceUnavailableMessage);
    });

    test('fonksiyon yok (404) / ham NOT_FOUND -> kullanılamıyor, ham metin yok', () {
      final r = m(ex('not-found', message: 'NOT_FOUND'));
      expect(r.code, kServiceUnavailableCode);
      expect(r.message, isNot(contains('NOT_FOUND')));
      expect(m(ex('unimplemented')).code, kServiceUnavailableCode);
    });

    test('temiz Türkçe not-found mesajı olduğu gibi kalır', () {
      expect(m(ex('not-found', message: 'Sipariş bulunamadı.')).message,
          'Sipariş bulunamadı.');
    });

    test('ağ / zaman aşımı / unavailable -> network', () {
      expect(m(ex('unavailable')).code, 'network');
      expect(m(ex('deadline-exceeded')).code, 'network');
      expect(m(Exception('SocketException: Failed host lookup')).code, 'network');
    });

    test('internal ve ham metinler genel mesaja düşer', () {
      final r = m(ex('internal', message: 'INTERNAL at x.js:42'));
      expect(r.message, kGenericPurchaseMessage);
      for (final raw in [
        'functions/not-found',
        'PERMISSION_DENIED',
        'FirebaseError: boom',
        'https://x.y/z',
      ]) {
        for (final code in [
          'permission-denied',
          'failed-precondition',
          'resource-exhausted',
          'invalid-argument',
          'not-found'
        ]) {
          final out = m(ex(code, message: raw)).message;
          expect(out, isNot(contains('functions/')));
          expect(out, isNot(contains('PERMISSION_DENIED')));
          expect(out, isNot(contains('Firebase')));
          expect(out, isNot(contains('http')));
        }
      }
      expect(m(StateError('boom')).message, kGenericPurchaseMessage);
    });

    test('koltuk dolu (failed-precondition, Türkçe) sunucu mesajıyla', () {
      expect(
          m(ex('failed-precondition', message: 'Koltuk artık müsait değil: A1'))
              .message,
          'Koltuk artık müsait değil: A1');
    });
  });

  group('Kota ile seçim sınırı ve limit akışı', () {
    late PurchaseHarness h;
    late ProviderSubscription<SeatPurchaseState> sub;
    SeatPurchaseController ctrl() =>
        h.container.read(seatPurchaseControllerProvider('e1').notifier);
    SeatPurchaseState st() =>
        h.container.read(seatPurchaseControllerProvider('e1'));
    EventQuota? quota() => h.container.read(eventQuotaProvider('e1'));
    Future<void> refresh() =>
        h.container.read(eventQuotaProvider('e1').notifier).refresh();

    setUp(() {
      h = PurchaseHarness();
      sub = h.container.listen(seatPurchaseControllerProvider('e1'), (_, __) {});
      h.container.listen(eventQuotaProvider('e1'), (_, __) {});
    });
    tearDown(() {
      sub.close();
      h.dispose();
    });

    test('kota yokken varsayılan 3; kota 1 kalan -> ikinci koltuk reddedilir', () async {
      expect(quota(), isNull);
      for (final s in ['A1', 'A2', 'A3']) {
        expect(ctrl().toggleSeat(s), isTrue);
      }
      expect(ctrl().toggleSeat('A4'), isFalse);
      for (final s in ['A1', 'A2', 'A3']) {
        ctrl().toggleSeat(s);
      }
      h.client.handlers['getEventQuota'] =
          (final _) => {'limit': 3, 'used': 2, 'remaining': 1, 'held': 0};
      await refresh();
      expect(quota()!.remaining, 1);
      expect(ctrl().toggleSeat('A1'), isTrue);
      expect(ctrl().toggleSeat('A2'), isFalse);
      expect(st().notice!.text, contains('en fazla 1 koltuk'));
    });

    test('hak doldu: hiçbir koltuk seçilemez, açıklama gösterilir', () async {
      h.client.handlers['getEventQuota'] =
          (final _) => {'limit': 3, 'used': 3, 'remaining': 0};
      await refresh();
      expect(ctrl().toggleSeat('A1'), isFalse);
      expect(st().notice!.text, contains('bilet hakkını doldurdun'));
      expect(st().selected, isEmpty);
    });

    test('kota okunamazsa (fonksiyon yok) null kalır, akış bozulmaz', () async {
      h.client.handlers['getEventQuota'] =
          (final _) => throw ex('not-found', message: 'NOT_FOUND');
      await refresh();
      expect(quota(), isNull);
      expect(ctrl().toggleSeat('A1'), isTrue);
    });

    test('holdSeats EVENT_LIMIT: Türkçe mesaj, seçim temizlenir, kota tazelenir', () async {
      h.client.handlers['holdSeats'] = (final _) => throw ex('resource-exhausted',
          message:
              'Bu etkinlik için en fazla 3 bilet alabilirsin. Şu an 3 biletin var; 0 bilet daha alabilirsin.',
          details: {'code': 'EVENT_LIMIT', 'limit': 3, 'used': 3, 'remaining': 0});
      h.client.handlers['getEventQuota'] =
          (final _) => {'limit': 3, 'used': 3, 'remaining': 0};
      ctrl().toggleSeat('A1');
      expect(await ctrl().holdSelected(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().notice!.text, startsWith('Bu etkinlik için en fazla 3'));
      expect(st().selected, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(quota()!.isFull, isTrue);
    });

    test('confirmReservation EVENT_LIMIT: tutma bırakılır, seçime dönülür', () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] = (final _) => throw ex(
          'resource-exhausted',
          message: 'Bu etkinlik için en fazla 3 bilet alabilirsin. Şu an 3 biletin var; 0 bilet daha alabilirsin.',
          details: {'code': 'EVENT_LIMIT', 'limit': 3, 'used': 3, 'remaining': 0});
      ctrl().toggleSeat('A1');
      await ctrl().holdSelected();
      expect(await ctrl().confirmReservation(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(h.client.callsOf('releaseHold').length, 1);
    });

    test('başarılı onay -> completed ve kota tazelenir (sayfa buna göre çıkar)', () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] =
          (final _) => {'ticketIds': ['ord1']};
      h.client.handlers['getEventQuota'] =
          (final _) => {'limit': 3, 'used': 1, 'remaining': 2};
      ctrl().toggleSeat('A1');
      await ctrl().holdSelected();
      expect(await ctrl().confirmReservation(), isTrue);
      expect(st().phase, PurchasePhase.completed);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(quota()!.used, 1);
    });
  });
}
