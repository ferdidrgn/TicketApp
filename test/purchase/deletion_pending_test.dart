import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import 'purchase_test_helpers.dart';

FirebaseFunctionsException deletionPending() => FirebaseFunctionsException(
      message: 'Hesap silinmek üzere.',
      code: 'failed-precondition',
      details: const {'code': 'ACCOUNT_DELETION_PENDING'},
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
    sub = h.container
        .listen(seatPurchaseControllerProvider('e1'), (final _, final __) {});
  });
  tearDown(() {
    sub.close();
    h.dispose();
  });

  test('silme bekleyen hesap: satın alma reddedilir, iptal eylemi açılır',
      () async {
    h.client.handlers['holdSeats'] = (final _) => throw deletionPending();
    final c = ctrl()..toggleSeat('A1');

    expect(await c.holdSelected(), isFalse);
    expect(st().deletionPending, isTrue);
    expect(st().phase, PurchasePhase.selecting);
    expect(st().selected, {'A1'});
    expect(st().notice?.text, contains('silinmek üzere'));
    expect(st().phoneRequired, isFalse);
  });

  test('silmeyi iptal et: callable çağrılır, bayrak iner, tutma sürer',
      () async {
    h.client.handlers['holdSeats'] = (final _) => throw deletionPending();
    h.client.handlers['cancelAccountDeletion'] = (final _) => {'ok': true};
    final c = ctrl()..toggleSeat('A1');
    await c.holdSelected();

    expect(await c.cancelAccountDeletion(), isTrue);
    expect(h.client.callsOf('cancelAccountDeletion').length, 1);
    expect(st().deletionPending, isFalse);
    expect(st().notice?.isError, isFalse);

    h.stubHold();
    expect(await c.holdSelected(), isTrue);
    expect(st().phase, PurchasePhase.held);
  });

  test('iptal başarısız olursa bayrak kalır ve hata bildirilir', () async {
    h.client.handlers['holdSeats'] = (final _) => throw deletionPending();
    h.client.handlers['cancelAccountDeletion'] = (final _) =>
        throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
    final c = ctrl()..toggleSeat('A1');
    await c.holdSelected();

    expect(await c.cancelAccountDeletion(), isFalse);
    expect(st().deletionPending, isTrue);
    expect(st().notice?.isError, isTrue);
  });
}
