import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/domain/entities/purchase_entities.dart';
import 'package:ticketapp/features/purchase/presentation/providers/purchase_provider.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';
import 'package:ticketapp/features/tickets/domain/entities/ticket.dart';
import 'package:ticketapp/features/tickets/presentation/providers/my_ticket_provider.dart';
import 'package:ticketapp/features/tickets/presentation/widgets/ticket_status.dart';

import 'purchase_test_helpers.dart';

Future<void> settle([final int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Ticket ticket({
  final String method = 'venue',
  final String status = 'pay_at_venue',
  final String usedAt = '',
  final String cancelledAt = '',
}) =>
    Ticket(
      id: 't1',
      createdAt: '',
      updatedAt: '',
      customerId: 'u1',
      showId: 's1',
      stageId: 'st1',
      eventId: 'e1',
      orderMethod: method,
      orderPrice: '300.00',
      buySeats: const ['A1'],
      isPast: false,
      paymentStatus: status,
      usedAt: usedAt,
      cancelledAt: cancelledAt,
    );

void main() {
  late PurchaseHarness h;
  late ProviderSubscription<SeatPurchaseState> sub;

  SeatPurchaseController ctrl() =>
      h.container.read(seatPurchaseControllerProvider('e1').notifier);
  SeatPurchaseState st() =>
      h.container.read(seatPurchaseControllerProvider('e1'));

  setUp(() {
    h = PurchaseHarness();
    sub = h.container.listen(seatPurchaseControllerProvider('e1'), (_, __) {});
  });
  tearDown(() {
    sub.close();
    h.dispose();
  });

  group('SalesConfig', () {
    test('belge yoksa/bozuksa varsayılan: rezervasyon, 3, 24', () {
      expect(SalesConfig.fromMap(null), SalesConfig.defaults);
      expect(SalesConfig.defaults.mode, SalesMode.rezervasyon);
      expect(SalesConfig.defaults.rezervasyonLimit, 3);
      expect(SalesConfig.defaults.iptalSaat, 24);
      expect(SalesConfig.fromMap({'mode': 'xx', 'rezervasyonLimit': 'a'}),
          SalesConfig.defaults);
    });

    test('alanlar okunur', () {
      final c = SalesConfig.fromMap(
          {'mode': 'online', 'rezervasyonLimit': 5, 'iptalSaat': 6});
      expect(c.mode, SalesMode.online);
      expect(c.rezervasyonLimit, 5);
      expect(c.iptalSaat, 6);
      expect(SalesConfig.fromMap({'mode': 'kapali'}).mode, SalesMode.kapali);
    });

    test('düğme etiketi ve kapalı satış yalnızca ücretlide', () {
      const kapali = SalesConfig(mode: SalesMode.kapali);
      const rez = SalesConfig();
      const online = SalesConfig(mode: SalesMode.online);
      expect(kapali.isClosedFor(paid: true), isTrue);
      expect(kapali.isClosedFor(paid: false), isFalse);
      expect(kapali.ctaLabel(paid: true), 'Satış kapalı');
      expect(kapali.ctaLabel(paid: false), 'Bilet al');
      expect(rez.ctaLabel(paid: true), 'Rezervasyon yap');
      expect(online.ctaLabel(paid: true), 'Bilet al');
      expect(rez.ctaLabel(paid: true, fallback: 'Koltuk seç'),
          'Rezervasyon yap');
      expect(rez.ctaLabel(paid: false, fallback: 'Koltuk seç'), 'Koltuk seç');
    });

    test('Config/satis akışı: belge yok → varsayılan, sonra belge değeri',
        () async {
      // Akış henüz değer vermeden de UI varsayılanı görür.
      expect(h.container.read(salesConfigProvider), SalesConfig.defaults);
      final repo = h.container.read(purchaseRepositoryProvider);
      expect((await repo.watchSalesConfig().first), SalesConfig.defaults);
      await h.firestore.collection('Config').doc('satis').set(
          {'mode': 'kapali', 'rezervasyonLimit': 2, 'iptalSaat': 12});
      final cfg = await repo.watchSalesConfig().first;
      expect(cfg.mode, SalesMode.kapali);
      expect(cfg.rezervasyonLimit, 2);
    });
  });

  group('ConfirmReservationUseCase', () {
    test('yalnızca orderId gönderir, bilet kimliklerini döner', () async {
      h.client.handlers['confirmReservation'] =
          (final _) => {'ticketIds': ['ord1'], 'status': 'rezervasyon'};
      final r =
          await h.container.read(confirmReservationUseCaseProvider)('ord1');
      expect(h.client.callsOf('confirmReservation').single, {'orderId': 'ord1'});
      expect(r.getOrElse(() => []), ['ord1']);
    });

    test('limit hatasında sunucu mesajı korunur', () async {
      const msg = 'En fazla 3 rezervasyon yapabilirsin.';
      h.client.handlers['confirmReservation'] = (final _) =>
          throw FirebaseFunctionsException(
              message: msg, code: 'resource-exhausted');
      final r =
          await h.container.read(confirmReservationUseCaseProvider)('ord1');
      r.fold((final f) {
        expect(f.message, msg);
        expect((f as PurchaseFailure).code, 'resource-exhausted');
      }, (_) => fail('Left bekleniyordu'));
    });
  });

  group('CancelTicketUseCase', () {
    test('ticketId gönderir; sunucu reddini mesajıyla döner', () async {
      h.client.handlers['cancelTicket'] = (final _) => {'ok': true};
      final ok = await h.container.read(cancelTicketUseCaseProvider)('t1');
      expect(ok.isRight(), isTrue);
      expect(h.client.callsOf('cancelTicket').single, {'ticketId': 't1'});

      h.client.handlers['cancelTicket'] = (final _) =>
          throw FirebaseFunctionsException(
              message: 'İptal süresi geçti.', code: 'failed-precondition');
      final bad = await h.container.read(cancelTicketUseCaseProvider)('t1');
      bad.fold((final f) => expect(f.message, 'İptal süresi geçti.'),
          (_) => fail('Left bekleniyordu'));
    });
  });

  group('SeatPurchaseController.confirmReservation', () {
    test('başarılı: completed + rezervasyon, tutar korunur', () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] =
          (final _) => {'ticketIds': ['ord1'], 'status': 'rezervasyon'};
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.confirmReservation(), isTrue);
      expect(st().phase, PurchasePhase.completed);
      expect(st().completedReservation, isTrue);
      expect(st().completedFree, isFalse);
      expect(st().completedTotal, 150);
      expect(st().completedSeats, ['A1']);
      // Tamamlanmış sipariş dispose'ta bırakılmaz.
      sub.close();
      h.container.invalidate(seatPurchaseControllerProvider('e1'));
      await settle();
      expect(h.client.callsOf('releaseHold'), isEmpty);
    });

    test('ücretsiz tutmada çalışmaz', () async {
      h.stubHold(free: true);
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(await c.confirmReservation(), isFalse);
      expect(h.client.callsOf('confirmReservation'), isEmpty);
    });

    test('limit aşımı: sunucu mesajı, koltuklar bırakılır, seçime dönülür',
        () async {
      h.stubHold();
      const msg = 'Toplam en fazla 3 rezervasyon yapabilirsin.';
      h.client.handlers['confirmReservation'] = (final _) =>
          throw FirebaseFunctionsException(
              message: msg, code: 'resource-exhausted');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.confirmReservation(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().hold, isNull);
      expect(st().notice!.text, msg);
      await settle();
      expect(h.client.callsOf('releaseHold').length, 1);
    });

    test('geçici hata: held kalır, genel mesaj, tekrar denenebilir', () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] = (final _) =>
          throw FirebaseFunctionsException(message: 'x', code: 'internal');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();

      expect(await c.confirmReservation(), isFalse);
      expect(st().phase, PurchasePhase.held);
      expect(st().notice!.text, isNot(contains('internal')));

      h.client.handlers['confirmReservation'] =
          (final _) => {'ticketIds': ['ord1']};
      expect(await c.confirmReservation(), isTrue);
    });

    test('süresi dolmuş tutma (failed-precondition): seçime döner', () async {
      h.stubHold();
      h.client.handlers['confirmReservation'] = (final _) =>
          throw FirebaseFunctionsException(
              message: 'Tutma süresi doldu.', code: 'failed-precondition');
      final c = ctrl()..toggleSeat('A1');
      await c.holdSelected();
      expect(await c.confirmReservation(), isFalse);
      expect(st().phase, PurchasePhase.selecting);
      expect(st().notice!.text, 'Tutma süresi doldu.');
    });
  });

  group('Ticket modeli ve durum rozeti', () {
    DetailedTicket dt(final Ticket t, {final bool past = false}) =>
        DetailedTicket(ticket: t, isPast: past);

    test('Firestore alanları okunur', () {
      final t = Ticket(
        id: 'x',
        createdAt: '',
        updatedAt: '',
        customerId: 'u',
        showId: '',
        stageId: '',
        eventId: '',
        orderMethod: 'venue',
        orderPrice: '0',
        buySeats: const [],
        isPast: false,
        paymentStatus: 'cancelled',
        cancelledAt: '2026-11-01T10:00:00',
      );
      expect(t.isCancelled, isTrue);
      expect(ticket().isPayAtVenue, isTrue);
      expect(ticket(status: 'no_show').isNoShow, isTrue);
    });

    test('rozet durumları', () {
      expect(ticketPayState(dt(ticket())), TicketPayState.venue);
      expect(ticketPayState(dt(ticket(status: 'paid'))), TicketPayState.paid);
      expect(ticketPayState(dt(ticket(status: 'no_show'))),
          TicketPayState.noShow);
      expect(
          ticketPayState(dt(ticket(status: 'cancelled'))),
          TicketPayState.cancelled);
      expect(ticketPayState(dt(ticket(method: 'free', status: ''))),
          TicketPayState.free);
      expect(ticketPayState(dt(ticket(method: 'card', status: ''))),
          TicketPayState.paid);
      expect(ticketPayState(dt(ticket(method: '', status: ''))),
          TicketPayState.unknown);
      expect(ticketPayStateLabel(TicketPayState.venue),
          'Rezervasyon · ödeme sahnede');
    });

    test('canCancelTicket: süre, yöntem ve durum kuralları', () {
      final now = DateTime(2026, 11, 1, 12);
      // Etkinlik tarihi biçimini DateFormatter çözer; ticket.eventDate ile.
      DetailedTicket withDate(final Ticket t, final String date) =>
          DetailedTicket(
              ticket: Ticket(
                id: t.id,
                createdAt: '',
                updatedAt: '',
                customerId: t.customerId,
                showId: t.showId,
                stageId: t.stageId,
                eventId: t.eventId,
                orderMethod: t.orderMethod,
                orderPrice: t.orderPrice,
                buySeats: t.buySeats,
                isPast: false,
                eventDate: date,
                paymentStatus: t.paymentStatus,
                usedAt: t.usedAt,
                cancelledAt: t.cancelledAt,
              ),
              isPast: false);
      // Tarih ayrıştırılamıyorsa güvenli taraf: iptal gösterilmez.
      expect(canCancelTicket(withDate(ticket(), ''), 24, now), isFalse);
      expect(canCancelTicket(dt(ticket(), past: true), 24, now), isFalse);
      expect(canCancelTicket(dt(ticket(status: 'paid')), 24, now), isFalse);
      expect(canCancelTicket(dt(ticket(method: 'card', status: '')), 24, now),
          isFalse);
      expect(
          canCancelTicket(
              dt(ticket(usedAt: '2026-11-01T10:00:00')), 24, now),
          isFalse);
      expect(canCancelTicket(dt(ticket(status: 'cancelled')), 24, now),
          isFalse);
    });

    test('iptal / gelmedi biletler "past" ve "upcoming" dışında, history içinde',
        () {
      final list = [
        dt(ticket()),
        dt(ticket(status: 'cancelled')),
        dt(ticket(status: 'no_show'), past: true),
        dt(ticket(status: 'paid'), past: true),
      ];
      expect(list.upcoming.length, 1);
      expect(list.past.length, 1);
      expect(list.history.length, 3);
    });
  });

  test('putOrder yardımcı: Timestamp import kullanımı', () {
    expect(Timestamp.fromMillisecondsSinceEpoch(0).seconds, 0);
  });
}
