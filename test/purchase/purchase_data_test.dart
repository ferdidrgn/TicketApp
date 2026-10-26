import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/data/datasources/purchase_remote_data_source_and_impl.dart';
import 'package:ticketapp/features/purchase/domain/entities/purchase_entities.dart';
import 'package:ticketapp/features/purchase/presentation/pages/payment_web_view_page.dart';
import 'package:ticketapp/features/purchase/presentation/providers/purchase_provider.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import 'purchase_test_helpers.dart';

void main() {
  late PurchaseHarness h;

  setUp(() => h = PurchaseHarness());
  tearDown(() => h.dispose());

  group('HoldSeatsUseCase', () {
    test('yalnızca eventId ve seatIds gönderir; fiyat/tutar ASLA', () async {
      h.stubHold();
      final r = await h.container
          .read(holdSeatsUseCaseProvider)('e1', ['A1', 'A2']);

      final sent = h.client.callsOf('holdSeats').single;
      expect(sent.keys.toSet(), {'eventId', 'seatIds'});
      expect(sent['eventId'], 'e1');
      expect(sent['seatIds'], ['A1', 'A2']);

      final hold = r.getOrElse(() => throw StateError('Left geldi'));
      expect(hold.orderId, 'ord1');
      expect(hold.total, 300);
      expect(hold.seatIds, ['A1', 'A2']);
      expect(hold.free, isFalse);
      expect(hold.expiresAt, h.now.add(const Duration(minutes: 10)));
    });

    test('sunucunun Türkçe mesajını olduğu gibi taşır (failed-precondition)',
        () async {
      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: 'Koltuk artık müsait değil: A1', code: 'failed-precondition');
      final r =
          await h.container.read(holdSeatsUseCaseProvider)('e1', ['A1']);
      final f = r.swap().getOrElse(() => throw StateError('Right geldi'))
          as PurchaseFailure;
      expect(f.message, 'Koltuk artık müsait değil: A1');
      expect(f.code, 'failed-precondition');
      expect(f.isStale, isTrue);
    });

    test('teknik hata ayrıntısı sızmaz (internal / bilinmeyen istisna)',
        () async {
      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: 'INTERNAL at line 42 Error: ECONNRESET stack…',
          code: 'internal');
      var r = await h.container.read(holdSeatsUseCaseProvider)('e1', ['A1']);
      var msg = (r.swap().getOrElse(() => throw StateError('x')) as PurchaseFailure)
          .message;
      expect(msg, isNot(contains('INTERNAL')));
      expect(msg, isNot(contains('ECONNRESET')));
      expect(msg, contains('tekrar dene'));

      h.client.handlers['holdSeats'] =
          (final _) => throw const FormatException('SocketException: 10.0.0.1');
      r = await h.container.read(holdSeatsUseCaseProvider)('e1', ['A1']);
      msg = (r.swap().getOrElse(() => throw StateError('x')) as PurchaseFailure)
          .message;
      expect(msg, isNot(contains('Socket')));
      expect(msg, isNot(contains('10.0.0.1')));
    });

    test('unauthenticated -> giriş mesajı; unavailable -> bağlantı mesajı',
        () async {
      h.client.handlers['holdSeats'] = (final _) =>
          throw FirebaseFunctionsException(message: 'x', code: 'unauthenticated');
      var r = await h.container.read(holdSeatsUseCaseProvider)('e1', ['A1']);
      expect((r.swap().getOrElse(() => throw StateError('x')) as PurchaseFailure).message,
          contains('giriş'));

      h.client.handlers['holdSeats'] = (final _) => throw FirebaseFunctionsException(
          message: 'Unable to resolve host', code: 'unavailable');
      r = await h.container.read(holdSeatsUseCaseProvider)('e1', ['A1']);
      final f = r.swap().getOrElse(() => throw StateError('x')) as PurchaseFailure;
      expect(f.message, isNot(contains('resolve')));
      expect(f.code, 'network');
    });
  });

  group('diğer use-case\'ler', () {
    test('releaseHold / confirmFree / startPayment sözleşmeye uyar', () async {
      h.client.handlers['releaseHold'] = (final _) => {'ok': true};
      h.client.handlers['confirmFree'] =
          (final _) => {'ticketIds': ['ord1']};
      h.client.handlers['startPayment'] = (final _) => {
            'provider': 'iyzico',
            'paymentPageUrl': 'https://pay.example/x',
            'token': 'tok12345',
          };

      expect((await h.container.read(releaseHoldUseCaseProvider)('ord1')).isRight(),
          isTrue);
      final free = await h.container.read(confirmFreeUseCaseProvider)('ord1');
      expect(free.getOrElse(() => []), ['ord1']);

      final pay = await h.container
          .read(startPaymentUseCaseProvider)('ord1', purchaseReturnUrl('ord1'));
      final session = pay.getOrElse(() => throw StateError('x'));
      expect(session.paymentPageUrl, 'https://pay.example/x');
      expect(session.checkoutFormContent, isNull);

      final sent = h.client.callsOf('startPayment').single;
      expect(sent.keys.toSet(), {'orderId', 'provider', 'returnUrl'});
      expect(sent['provider'], 'iyzico');
      expect(sent['returnUrl'],
          'https://tiyatrol-web.web.app/odeme-sonuc?order=ord1');
    });

    test('confirmFree limit hatası sunucu mesajıyla döner', () async {
      h.client.handlers['confirmFree'] = (final _) => throw FirebaseFunctionsException(
          message: 'Ücretsiz etkinliklerde toplam en fazla 3 bilet alabilirsiniz.',
          code: 'resource-exhausted');
      final r = await h.container.read(confirmFreeUseCaseProvider)('ord1');
      final f = r.swap().getOrElse(() => throw StateError('x')) as PurchaseFailure;
      expect(f.message, contains('en fazla 3 bilet'));
      expect(f.code, 'resource-exhausted');
    });

    test('startPayment cevabında URL de HTML de yoksa genel hata', () async {
      h.client.handlers['startPayment'] =
          (final _) => {'provider': 'iyzico', 'token': 't'};
      final r = await h.container
          .read(startPaymentUseCaseProvider)('ord1', purchaseReturnUrl('ord1'));
      expect(r.isLeft(), isTrue);
    });
  });

  group('Order okuma (yalnızca kendi userId)', () {
    test('getOpenOrders yalnızca kendi held/paying siparişlerini döner',
        () async {
      await h.putOrder('mine_held', userId: 'u1', status: 'held');
      await h.putOrder('mine_paying', userId: 'u1', status: 'paying');
      await h.putOrder('mine_paid', userId: 'u1', status: 'paid');
      await h.putOrder('other', userId: 'u2', status: 'held');

      final r = await h.container.read(getOpenOrdersUseCaseProvider)('u1');
      final ids = r.getOrElse(() => []).map((final o) => o.id).toSet();
      expect(ids, {'mine_held', 'mine_paying'});
    });

    test('watchOrder durum değişimini yayınlar; var olmayan belge null',
        () async {
      await h.putOrder('o1', status: 'paying');
      final stream = h.container.read(watchOrderUseCaseProvider)('o1');
      final events = <OrderStatus?>[];
      final sub = stream.listen((final o) => events.add(o?.status));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await h.firestore
          .collection('Order')
          .doc('o1')
          .update({'status': 'paid', 'ticketIds': ['o1']});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(events.first, OrderStatus.paying);
      expect(events.last, OrderStatus.paid);

      final none = await h.container
          .read(watchOrderUseCaseProvider)('yok')
          .first;
      expect(none, isNull);
    });
  });

  group('ödeme dönüş adresi', () {
    test('odeme-sonuc yakalanır, başka adresler yakalanmaz', () {
      final ok = parsePaymentReturn(Uri.parse(
          'https://tiyatrol-web.web.app/odeme-sonuc?order=abc&durum=basarili'));
      expect(ok, isNotNull);
      expect(ok!.orderId, 'abc');
      expect(ok.status, 'basarili');

      expect(
          parsePaymentReturn(
              Uri.parse('https://evil.example/odeme-sonuc?order=abc')),
          isNull);
      expect(
          parsePaymentReturn(
              Uri.parse('http://tiyatrol-web.web.app/odeme-sonuc?order=abc')),
          isNull);
      expect(
          parsePaymentReturn(
              Uri.parse('https://sandbox-api.iyzipay.com/checkout/x')),
          isNull);
    });
  });
}
