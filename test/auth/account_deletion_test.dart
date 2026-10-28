import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ticketapp/features/auth/data/account_deletion_service.dart';
import 'package:ticketapp/features/auth/presentation/providers/account_deletion_provider.dart';
import 'package:ticketapp/features/auth/presentation/widgets/account_deletion_widgets.dart';

import '../purchase/purchase_test_helpers.dart';

FirebaseFunctionsException upcoming() => FirebaseFunctionsException(
      message: 'Gelecek biletiniz var',
      code: 'failed-precondition',
      details: {
        'code': 'UPCOMING_TICKETS',
        'count': 2,
        'nextEventDate': DateTime(2026, 11, 12, 20).millisecondsSinceEpoch,
        'nextEventTitle': 'Hamlet',
      },
    );

AccountDeletionController build(final FakeCallableClient client) =>
    AccountDeletionController(AccountDeletionService(client));

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('hata eşleme', () {
    test('UPCOMING_TICKETS adet, tarih ve oyun adıyla eşlenir', () {
      final e = AccountDeletionService.mapError(upcoming());
      expect(e, isA<UpcomingTicketsException>());
      final u = e as UpcomingTicketsException;
      expect(u.count, 2);
      expect(u.nextEventTitle, 'Hamlet');
      expect(u.nextEventDate, DateTime(2026, 11, 12, 20));
    });

    test('UPCOMING_TICKETS GERÇEK backend şekli: ISO tarih; tarihi bilinmeyen bilette nextEventDate/başlık YOK', () {
      final iso = FirebaseFunctionsException(
        message: 'UPCOMING_TICKETS',
        code: 'failed-precondition',
        details: {
          'code': 'UPCOMING_TICKETS',
          'count': 1,
          'nextEventDate': '2026-11-12T17:00:00.000Z',
          'nextEventTitle': 'Hamlet',
        },
      );
      final a = AccountDeletionService.mapError(iso) as UpcomingTicketsException;
      expect(a.nextEventDate, DateTime.utc(2026, 11, 12, 17));
      final bare = AccountDeletionService.mapError(FirebaseFunctionsException(
        message: 'UPCOMING_TICKETS',
        code: 'failed-precondition',
        details: {'code': 'UPCOMING_TICKETS', 'count': 1},
      )) as UpcomingTicketsException;
      expect(bare.count, 1);
      expect(bare.nextEventDate, isNull);
      expect(bare.nextEventTitle, isNull);
    });

    test('ACCOUNT_DELETION_PENDING tarihle eşlenir', () {
      final e = AccountDeletionService.mapError(FirebaseFunctionsException(
        message: 'x',
        code: 'failed-precondition',
        details: {
          'code': 'ACCOUNT_DELETION_PENDING',
          'scheduledAt': '2026-11-27T10:00:00.000Z',
        },
      ));
      expect(e, isA<DeletionPendingException>());
      expect((e as DeletionPendingException).scheduledAt, isNotNull);
    });

    test('ağ hatası ve bilinmeyen hata teknik sızıntı içermez', () {
      final net = AccountDeletionService.mapError(
          FirebaseFunctionsException(message: 'boom', code: 'unavailable'));
      expect(net.code, 'network');
      final other = AccountDeletionService.mapError(StateError('secret'));
      expect(other.message, isNot(contains('secret')));
    });
  });

  group('kapı (controller)', () {
    late FakeCallableClient client;
    setUp(() => client = FakeCallableClient());

    test('gelecek bilet: reddedilir, çıkışa gidecek sonuç dönmez', () async {
      client.handlers['requestAccountDeletion'] = (final _) => throw upcoming();
      final o = await build(client).request();
      expect(o, isA<DeletionBlocked>());
      expect((o as DeletionBlocked).reason.count, 2);
    });

    test('bilet yok: planlanır, tarih sunucudan gelir', () async {
      final at = DateTime(2026, 11, 27, 10);
      client.handlers['requestAccountDeletion'] = (final _) => {
            'status': 'pending',
            'scheduledAt': at.toUtc().toIso8601String(),
            'already': false
          };
      final o = await build(client).request();
      expect(o, isA<DeletionScheduled>());
      expect((o as DeletionScheduled).date!.isAtSameMomentAs(at), isTrue);
      expect(client.callsOf('requestAccountDeletion').length, 1);
    });

    test('misafir: sunucu hemen sildi', () async {
      client.handlers['requestAccountDeletion'] =
          (final _) => {'status': 'deleted'};
      expect(await build(client).request(), isA<DeletionDone>());
    });

    test('zaten bekliyor ve genel hata ayrı sonuç verir', () async {
      client.handlers['requestAccountDeletion'] = (final _) =>
          throw FirebaseFunctionsException(
              message: 'x',
              code: 'failed-precondition',
              details: {'code': 'ACCOUNT_DELETION_PENDING'});
      expect(await build(client).request(), isA<DeletionAlreadyPending>());

      client.handlers['requestAccountDeletion'] = (final _) =>
          throw FirebaseFunctionsException(message: 'x', code: 'internal');
      expect(await build(client).request(), isA<DeletionFailed>());
    });

    test('iptal: başarıda null, hatada mesaj', () async {
      client.handlers['cancelAccountDeletion'] = (final _) => {'ok': true};
      expect(await build(client).cancel(), isNull);
      client.handlers['cancelAccountDeletion'] = (final _) =>
          throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
      expect(await build(client).cancel(), isNotNull);
    });
  });

  group('kullanıcı belgesi', () {
    test('yalnız pending + geçerli tarih banner üretir', () {
      expect(AccountDeletionInfo.fromUserData(null), isNull);
      expect(AccountDeletionInfo.fromUserData({'deletionStatus': 'none'}),
          isNull);
      expect(AccountDeletionInfo.fromUserData({'deletionStatus': 'pending'}),
          isNull);
      final i = AccountDeletionInfo.fromUserData({
        'deletionStatus': 'pending',
        'deletionScheduledAt': DateTime(2026, 11, 27).millisecondsSinceEpoch,
      });
      expect(i?.scheduledAt, DateTime(2026, 11, 27));
    });
  });

  group('arayüz', () {
    testWidgets('onay metni 30 gün ve tr_TR tarih içerir', (final t) async {
      final m = deletionConfirmMessage(DateTime(2026, 11, 27));
      expect(m, contains('30 gün'));
      expect(m, contains('27 Kasım 2026'));
      expect(m, contains('vazgeçebilirsiniz'));
    });

    testWidgets('red sheet: özet + Biletlerim\'e git', (final t) async {
      var tapped = false;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UpcomingTicketsSheet(
            reason: UpcomingTicketsException(
                count: 2,
                nextEventDate: DateTime(2026, 11, 12),
                nextEventTitle: 'Hamlet'),
            onGoToTickets: () => tapped = true,
          ),
        ),
      ));
      expect(find.text('Gelecek etkinlik biletiniz var'), findsOneWidget);
      expect(find.textContaining('2 bilet'), findsOneWidget);
      expect(find.textContaining('Hamlet'), findsOneWidget);
      await t.tap(find.text("Biletlerim'e git"));
      expect(tapped, isTrue);
    });

    testWidgets('banner tarihi gösterir, iptal tetiklenir', (final t) async {
      var cancelled = false;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AccountDeletionBannerView(
              scheduledAt: DateTime(2026, 11, 27),
              onCancel: () => cancelled = true),
        ),
      ));
      expect(find.textContaining('27 Kasım 2026 tarihinde silinecek'),
          findsOneWidget);
      await t.tap(find.text('Silmeyi iptal et'));
      expect(cancelled, isTrue);
    });
  });
}
