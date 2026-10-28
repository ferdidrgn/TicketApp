import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/domain/entities/purchase_entities.dart';
import 'package:ticketapp/features/tickets/data/datasources/ticket_remote_data_source_and_impl.dart';
import 'package:ticketapp/features/tickets/data/mappers/ticket_mapper.dart';
import 'package:ticketapp/features/tickets/data/models/ticket_model.dart';
import 'package:ticketapp/features/tickets/domain/ticket_purchase_time.dart';

/// functions/src/orders.js `writeFulfillment` ile BİREBİR aynı alanlar.
Map<String, dynamic> serverTicket(
        {final String method = 'venue', final String status = 'pay_at_venue'}) =>
    {
      '_id': 'ord_1',
      '_createdAt': '2026-10-28T11:32:07.123Z',
      '_updatedAt': '2026-10-28T11:32:07.123Z',
      'customerId': 'uid1',
      'showId': 's1',
      'stageId': 'st1',
      'eventId': 'e1',
      'orderPrice': '300.00',
      'orderMethod': method,
      'buySeats': ['A1', 'A2'],
      'isPast': false,
      'showName': 'Hamlet',
      'showImageUrl': '',
      'stageName': 'Sahne',
      'eventDate': '15.11.2026,20:00',
      'orderId': 'ord_1',
      'paymentStatus': status,
    };

void main() {
  group('sunucu biçimli Ticket ayrıştırma', () {
    test('rezervasyon belgesi -> Ticket', () {
      final t = TicketModel.fromFirestore(serverTicket()).toEntity();
      expect(t.id, 'ord_1');
      expect(t.customerId, 'uid1');
      expect(t.buySeats, ['A1', 'A2']);
      expect(t.orderPrice, '300.00');
      expect(t.isPayAtVenue, isTrue);
      expect(t.createdAt, '2026-10-28T11:32:07.123Z');
      expect(t.eventDate, '15.11.2026,20:00');
    });

    test('ücretsiz belge (paymentStatus free) ayrışır', () {
      final t = TicketModel.fromFirestore(
              serverTicket(method: 'free', status: 'free'))
          .toEntity();
      expect(t.paymentStatus, 'free');
      expect(t.orderMethod, 'free');
    });

    test('tür karışıklığı istisna fırlatmaz', () {
      final m = TicketModel.fromFirestore({
        '_id': 'x',
        '_createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 28, 11, 32)),
        'orderPrice': 300, // sayı
        'buySeats': ['A1', 7],
        'isPast': 'false',
        'customerId': {'bozuk': 1},
        'cancelledAt': Timestamp.fromDate(DateTime.utc(2026, 10, 29)),
        'usedAt': 1782000000000,
        'showName': null,
      });
      final t = m.toEntity();
      expect(t.orderPrice, '300');
      expect(t.buySeats, ['A1', '7']);
      expect(t.isPast, false);
      expect(t.customerId, '');
      expect(t.createdAt, '2026-10-28T11:32:00.000Z');
      expect(t.isCancelled, isTrue);
      expect(t.usedAt, isNotEmpty);
    });

    test('tamamen boş belge bile Ticket üretir', () {
      final t = TicketModel.fromFirestore({'_id': 'y'}).toEntity();
      expect(t.id, 'y');
      expect(t.buySeats, isEmpty);
      expect(t.createdAt, '');
    });

    test('_createdAt yoksa createdAt alanına düşer', () {
      final t = TicketModel.fromFirestore(
          {'_id': 'z', 'createdAt': '2026-01-02T10:00:00.000Z'}).toEntity();
      expect(t.createdAt, '2026-01-02T10:00:00.000Z');
    });
  });

  group('TicketRemoteDataSource (fake Firestore)', () {
    test('customerId sorgusu yalnızca kendi biletlerini döner; bozuk alan listeyi öldürmez',
        () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('Ticket').doc('ord_1').set(serverTicket());
      await fs
          .collection('Ticket')
          .doc('ord_2')
          .set({...serverTicket(), '_id': 'ord_2', 'customerId': 'baskasi'});
      await fs.collection('Ticket').doc('ord_3').set({
        ...serverTicket(method: 'free', status: 'free'),
        '_id': 'ord_3',
        'orderPrice': 0,
        'buySeats': 'bozuk',
      });
      final ds = TicketRemoteDataSourceImpl(firestore: fs);
      final list = await ds.getTicketsByCustomerId('uid1');
      expect(list.map((e) => e.id).toSet(), {'ord_1', 'ord_3'});
      expect(list.firstWhere((e) => e.id == 'ord_3').buySeats, isNull);
    });
  });

  group('alış zamanı', () {
    test('UTC ISO -> Europe/Istanbul (+3)', () {
      expect(formatPurchaseStamp('2026-10-28T11:32:07.123Z'),
          '28.10.2026 14:32');
    });
    test('gece yarısı gün atlar', () {
      expect(formatPurchaseStamp('2026-12-31T22:05:00.000Z'),
          '01.01.2027 01:05');
    });
    test('ms sayısı ve boş/bozuk metin', () {
      expect(
          formatPurchaseStamp(
              '${DateTime.utc(2026, 10, 28, 11, 32).millisecondsSinceEpoch}'),
          '28.10.2026 14:32');
      expect(formatPurchaseStamp(''), '');
      expect(formatPurchaseStamp('bozuk'), '');
    });
  });

  group('OrderStatus', () {
    test('reserved (rezervasyon) bilet kesilmiş sayılır', () {
      expect(OrderStatus.parse('reserved'), OrderStatus.reserved);
      expect(OrderStatus.reserved.isFulfilled, isTrue);
      expect(OrderStatus.parse('held').isFulfilled, isFalse);
    });
  });
}
