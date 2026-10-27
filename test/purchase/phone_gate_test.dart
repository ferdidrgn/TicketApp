import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/auth/data/phone_link_service.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import 'purchase_test_helpers.dart';

Future<void> settle([final int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

FirebaseFunctionsException phoneRequired() => FirebaseFunctionsException(
      message: 'Telefon doğrulaması gerekli.',
      code: 'failed-precondition',
      details: const {'code': 'PHONE_REQUIRED'},
    );

void main() {
  late PurchaseHarness h;
  late ProviderSubscription<SeatPurchaseState> sub;

  SeatPurchaseController ctrl() =>
      h.container.read(seatPurchaseControllerProvider('e1').notifier);
  SeatPurchaseState st() => h.container.read(seatPurchaseControllerProvider('e1'));

  setUp(() {
    h = PurchaseHarness();
    sub = h.container
        .listen(seatPurchaseControllerProvider('e1'), (final _, final __) {});
  });
  tearDown(() {
    sub.close();
    h.dispose();
  });

  group('telefon kapısı (istemci)', () {
    test('telefonu doğrulanmamış: holdSeats ÇAĞRILMAZ, kapı açılır', () async {
      h.phone.verified = false;
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');

      expect(await c.holdSelected(), isFalse);
      expect(h.client.callsOf('holdSeats'), isEmpty);
      expect(st().phoneRequired, isTrue);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().selected, {'A1'});
    });

    test('doğrulama sonrası işlem kalınan yerden sürer', () async {
      h.phone.verified = false;
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      h.phone.verified = true; // SMS ile bağlandı
      expect(await c.phoneVerified(), isTrue);
      expect(h.client.callsOf('holdSeats').length, 1);
      expect(st().phoneRequired, isFalse);
      expect(st().phase, PurchasePhase.held);
    });

    test('vazgeçilirse bekleyen işlem düşer, çağrı yapılmaz', () async {
      h.phone.verified = false;
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      c.phoneGateDismissed();
      expect(st().phoneRequired, isFalse);
      expect(await c.phoneVerified(), isFalse);
      expect(h.client.calls, isEmpty);
      expect(st().selected, {'A1'});
    });

    test('ücretsiz onay da kapıdan geçer (yeniden açılmış sipariş)', () async {
      h.stubHold(free: true);
      h.client.handlers['confirmFree'] = (final _) => {'ticketIds': ['ord1']};
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      h.phone.verified = false;

      expect(await c.confirmFree(), isFalse);
      expect(h.client.callsOf('confirmFree'), isEmpty);
      expect(st().phoneRequired, isTrue);
      expect(st().phase, PurchasePhase.held);

      h.phone.verified = true;
      expect(await c.phoneVerified(), isTrue);
      expect(st().phase, PurchasePhase.completed);
      expect(st().completedFree, isTrue);
    });
  });

  group('PHONE_REQUIRED (sunucu)', () {
    test('token eskiyse: yenile + bir kez yeniden dene, kullanıcı görmez',
        () async {
      var tokenFresh = false;
      h.phone.onSync = () => tokenFresh = true;
      h.stubHold();
      final ok = h.client.handlers['holdSeats']!;
      h.client.handlers['holdSeats'] =
          (final d) => tokenFresh ? ok(d) : throw phoneRequired();

      final c = ctrl()..toggleSeat('A1');
      expect(await c.holdSelected(), isTrue);
      expect(h.client.callsOf('holdSeats').length, 2);
      expect(h.phone.syncCalls, 1);
      expect(st().phase, PurchasePhase.held);
      expect(st().phoneRequired, isFalse);
    });

    test('yenilemeden sonra da PHONE_REQUIRED ise kapı açılır (döngü yok)',
        () async {
      h.client.handlers['holdSeats'] = (final _) => throw phoneRequired();
      final c = ctrl()..toggleSeat('A1');

      expect(await c.holdSelected(), isFalse);
      expect(h.client.callsOf('holdSeats').length, 2);
      expect(st().phoneRequired, isTrue);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().selected, {'A1'});
      expect(st().notice, isNull);
    });

    test('yerelde doğrulanmamış + sunucu PHONE_REQUIRED: yenileme denenmez',
        () async {
      // İstemci kapısı zaten engeller; sunucuya hiç gidilmez.
      h.phone.verified = false;
      h.client.handlers['holdSeats'] = (final _) => throw phoneRequired();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(h.phone.syncCalls, 0);
      expect(h.client.callsOf('holdSeats'), isEmpty);
      expect(st().phoneRequired, isTrue);
    });

    test('confirmReservation PHONE_REQUIRED: held\'te kalır, kapı açılır',
        () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] =
          (final _) => throw phoneRequired();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.confirmReservation(), isFalse);
      expect(st().phase, PurchasePhase.held);
      expect(st().phoneRequired, isTrue);
      expect(st().hold, isNotNull);
    });
  });

  group('diğer hata kodları', () {
    test('limit aşımı: sunucunun Türkçe mesajı olduğu gibi gösterilir',
        () async {
      h.stubHold();
      const msg = 'Bu etkinlik için en fazla 3 koltuk alabilirsiniz.';
      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: msg, code: 'resource-exhausted');
      final c = ctrl()..toggleSeat('A1');
      expect(await c.holdSelected(), isFalse);
      expect(st().notice!.text, msg);
      expect(st().phoneRequired, isFalse);
    });

    test('ağ hatası: teknik metin sızmaz, kullanıcı dostu mesaj', () async {
      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: 'UNAVAILABLE: io exception', code: 'unavailable');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(st().notice!.text, contains('ulaşılamıyor'));
      expect(st().notice!.text, isNot(contains('io exception')));
      expect(st().phoneRequired, isFalse);
    });
  });

  group('telefon yardımcıları', () {
    test('maskPhone numarayı ham göstermez', () {
      expect(maskPhone('+905321234567'), '+90 5** *** ** 67');
      expect(maskPhone(null), '');
      expect(maskPhone('123'), '');
      expect(maskPhone('+905321234567'), isNot(contains('321')));
    });

    test('bağlama hata kodları Türkçe mesaja çevrilir', () {
      expect(phoneAuthErrorMessage('invalid-verification-code'),
          contains('SMS kodu hatalı'));
      expect(phoneAuthErrorMessage('session-expired'), contains('süresi doldu'));
      expect(phoneAuthErrorMessage('too-many-requests'), contains('Çok fazla'));
      expect(phoneAuthErrorMessage('xyz'), contains('doğrulanamadı'));
    });
  });
}
