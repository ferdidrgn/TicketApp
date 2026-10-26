import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import 'purchase_test_helpers.dart';

Future<void> settle([final int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late PurchaseHarness h;
  late ProviderSubscription<SeatPurchaseState> sub;

  SeatPurchaseController ctrl() =>
      h.container.read(seatPurchaseControllerProvider('e1').notifier);
  SeatPurchaseState st() => h.container.read(seatPurchaseControllerProvider('e1'));

  setUp(() {
    h = PurchaseHarness();
    // autoDispose sağlayıcıyı canlı tut.
    sub = h.container
        .listen(seatPurchaseControllerProvider('e1'), (final _, final __) {});
  });
  tearDown(() {
    sub.close();
    h.dispose();
  });

  group('yerel seçim', () {
    test('dokunmak sunucuya HİÇBİR çağrı yapmaz; en fazla 3 koltuk', () {
      final c = ctrl();
      expect(c.toggleSeat('A1'), isTrue);
      expect(c.toggleSeat('A2'), isTrue);
      expect(c.toggleSeat('A3'), isTrue);
      expect(c.toggleSeat('A4'), isFalse);
      expect(st().selected, {'A1', 'A2', 'A3'});
      expect(st().notice?.text, contains('En fazla 3'));
      expect(h.client.calls, isEmpty);

      // seçimi kaldırmak serbest
      expect(c.toggleSeat('A2'), isTrue);
      expect(st().selected, {'A1', 'A3'});
      expect(h.client.calls, isEmpty);
    });
  });

  group('tutma (holdSeats)', () {
    test('"Koltukları tut" tek holdSeats çağrısı; held fazına geçer', () async {
      h.stubHold();
      final c = ctrl()
        ..toggleSeat('A1')
        ..toggleSeat('A2');
      expect(await c.holdSelected(), isTrue);

      expect(h.client.callsOf('holdSeats').length, 1);
      expect(st().phase, PurchasePhase.held);
      expect(st().hold!.orderId, 'ord1');
      expect(st().mySeats, ['A1', 'A2']);
      expect(st().selected, isEmpty);
      expect(st().canPick, isFalse);
    });

    test('hata: sunucu mesajı gösterilir, seçim korunur, selecting\'e döner',
        () async {
      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: 'Koltuk artık müsait değil: A1', code: 'failed-precondition');
      final c = ctrl()..toggleSeat('A1');
      expect(await c.holdSelected(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().selected, {'A1'});
      expect(st().notice!.text, 'Koltuk artık müsait değil: A1');
      expect(st().notice!.isError, isTrue);
    });

    test('"Seçimi değiştir": releaseHold çağrılır, seçim geri gelir', () async {
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      await c.releaseHold();

      expect(h.client.callsOf('releaseHold').single, {'orderId': 'ord1'});
      expect(st().phase, PurchasePhase.selecting);
      expect(st().hold, isNull);
      expect(st().selected, {'A1'});
    });

    test('süre dolunca koltuklar bırakılır ve kullanıcı bilgilendirilir',
        () async {
      h.stubHold(ttl: const Duration(milliseconds: 80));
      // Saat gerçek zamanla birlikte ilerlesin.
      final start = DateTime.now();
      h.now = start;
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(st().phase, PurchasePhase.held);

      h.now = start.add(const Duration(milliseconds: 200));
      await settle(160);

      expect(st().phase, PurchasePhase.selecting);
      expect(st().hold, isNull);
      expect(h.client.callsOf('releaseHold').length, 1);
      expect(st().notice!.text, contains('süren doldu'));
    });

    test('ekran kapanınca (dispose) ödemesi başlamamış tutma bırakılır',
        () async {
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      sub.close(); // autoDispose -> notifier dispose
      await settle();
      expect(h.client.callsOf('releaseHold').single, {'orderId': 'ord1'});
    });
  });

  group('ücretsiz (confirmFree)', () {
    test('başarılı: completed + ücretsiz', () async {
      h.stubHold(free: true);
      h.client.handlers['confirmFree'] = (final _) => {'ticketIds': ['ord1']};
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(st().hold!.free, isTrue);

      expect(await c.confirmFree(), isTrue);
      expect(st().phase, PurchasePhase.completed);
      expect(st().completedFree, isTrue);
      expect(st().completedSeats, ['A1']);
    });

    test('limit hatası: sunucu mesajı gösterilir, koltuklar bırakılır',
        () async {
      h.stubHold(free: true);
      const msg = 'Ücretsiz etkinliklerde toplam en fazla 3 bilet alabilirsiniz.';
      h.client.handlers['confirmFree'] = (final _) => throw FirebaseFunctionsException(
          message: msg, code: 'resource-exhausted');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.confirmFree(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().hold, isNull);
      expect(st().notice!.text, msg);
      await settle();
      expect(h.client.callsOf('releaseHold').length, 1);
    });
  });

  group('ücretli ödeme', () {
    void stubPay() {
      h.client.handlers['startPayment'] = (final _) => {
            'provider': 'iyzico',
            'paymentPageUrl': 'https://pay.example/x',
            'token': 'tok12345',
          };
    }

    test('startPayment oturumu döner, awaitingPayment olur; dispose BIRAKMAZ',
        () async {
      h.stubHold();
      stubPay();
      await h.putOrder('ord1', status: 'paying');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      final session = await c.startPayment();
      expect(session!.paymentPageUrl, 'https://pay.example/x');
      expect(st().phase, PurchasePhase.awaitingPayment);
      expect(st().paymentStarted, isTrue);

      sub.close();
      await settle();
      expect(h.client.callsOf('releaseHold'), isEmpty);
    });

    test('Order paid olunca completed (ödeme sonucu Order belgesinden)',
        () async {
      h.stubHold();
      stubPay();
      await h.putOrder('ord1', status: 'paying');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      await c.startPayment();
      c.paymentReturned();
      expect(st().phase, PurchasePhase.verifying);

      await h.firestore.collection('Order').doc('ord1').update(
          {'status': 'paid', 'ticketIds': ['ord1']});
      await settle();

      expect(st().phase, PurchasePhase.completed);
      expect(st().completedFree, isFalse);
      expect(st().completedSeats, ['A1']);
      expect(st().completedTotal, 150);
    });

    test('Order failed olunca selecting + hata mesajı; bilet yok', () async {
      h.stubHold();
      stubPay();
      await h.putOrder('ord1', status: 'paying');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      await c.startPayment();
      c.paymentReturned();

      await h.firestore
          .collection('Order')
          .doc('ord1')
          .update({'status': 'failed'});
      await settle();

      expect(st().phase, PurchasePhase.selecting);
      expect(st().notice!.text, contains('bilet oluşmadı'));
      expect(st().notice!.text, isNot(contains('failed')));
    });

    test('ödeme sayfası kapatılırsa devam edilebilir (awaitingPayment)',
        () async {
      h.stubHold();
      stubPay();
      await h.putOrder('ord1', status: 'paying');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      await c.startPayment();
      c.paymentDismissed();
      expect(st().phase, PurchasePhase.awaitingPayment);
      // tekrar başlat -> sunucu aynı oturumu döner
      final again = await c.startPayment();
      expect(again, isNotNull);
      expect(h.client.callsOf('startPayment').length, 2);
    });

    test('startPayment başarısız (süre doldu): tutma sıfırlanır', () async {
      h.stubHold();
      h.client.handlers['startPayment'] = (final _) => throw FirebaseFunctionsException(
          message: 'Koltuk tutma süreniz doldu. Lütfen yeniden seçin.',
          code: 'failed-precondition');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.startPayment(), isNull);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().hold, isNull);
      expect(st().notice!.text, contains('süreniz doldu'));
    });

    test('startPayment geçici hata: held\'te kalır, tekrar denenebilir',
        () async {
      h.stubHold();
      h.client.handlers['startPayment'] = (final _) => throw FirebaseFunctionsException(
          message: 'Ödeme sağlayıcısına şu an ulaşılamıyor.', code: 'unavailable');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.startPayment(), isNull);
      expect(st().phase, PurchasePhase.held);
      expect(st().hold, isNotNull);
      expect(st().notice!.isError, isTrue);
    });
  });

  group('uygulama kapanması / arka plan', () {
    test('restore: süresi dolmamış held sipariş devam ettirilir', () async {
      await h.putOrder('old', seatIds: ['B1', 'B2'], total: 300);
      await h.putOrder('other_event', eventId: 'e2', seatIds: ['C1']);
      await h.putOrder('someone_else', userId: 'u2', seatIds: ['D1']);

      await ctrl().restore('u1');
      expect(st().phase, PurchasePhase.held);
      expect(st().hold!.orderId, 'old');
      expect(st().mySeats, ['B1', 'B2']);
      expect(st().hold!.total, 300);
    });

    test('restore: paying sipariş -> awaitingPayment (devam et)', () async {
      await h.putOrder('p1', status: 'paying', seatIds: ['B1']);
      await ctrl().restore('u1');
      expect(st().phase, PurchasePhase.awaitingPayment);
      expect(st().hold!.orderId, 'p1');
    });

    test('restore: süresi dolmuş sipariş sessizce yok sayılır', () async {
      await h.putOrder('exp', expiresIn: const Duration(minutes: -1));
      await ctrl().restore('u1');
      expect(st().phase, PurchasePhase.selecting);
      expect(st().notice, isNull);
      expect(h.client.calls, isEmpty);
    });

    test('arka planda süre dolarsa dönüşte (resumed) tutma bırakılır',
        () async {
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      c.onLifecycle(AppLifecycleState.paused);
      h.now = h.now.add(const Duration(minutes: 11)); // uygulama uykudayken
      expect(st().phase, PurchasePhase.held); // zamanlayıcı çalışmadı

      c.onLifecycle(AppLifecycleState.resumed);
      await settle();
      expect(st().phase, PurchasePhase.selecting);
      expect(h.client.callsOf('releaseHold').length, 1);
    });

    test('arka planda süre dolmadıysa dönüşte tutma korunur', () async {
      h.stubHold();
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      c.onLifecycle(AppLifecycleState.paused);
      h.now = h.now.add(const Duration(minutes: 3));
      c.onLifecycle(AppLifecycleState.resumed);
      await settle();
      expect(st().phase, PurchasePhase.held);
      expect(h.client.callsOf('releaseHold'), isEmpty);
    });
  });
}
