import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/purchase/presentation/providers/purchase_provider.dart';
import 'package:ticketapp/features/purchase/presentation/providers/seat_purchase_controller.dart';

import '../purchase/purchase_test_helpers.dart';

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

  test(
      'confirmReservation yanıtı kayboldu (unavailable) ama sunucuda order reserved: başarı',
      () async {
    h.stubHold();
    await h.putOrder('ord1', status: 'reserved');
    h.client.handlers['confirmReservation'] = (final _) =>
        throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
    final c = ctrl()..toggleSeat('A1');
    await c.holdSelected();
    expect(await c.confirmReservation(), isTrue);
    expect(st().phase, PurchasePhase.completed);
    expect(st().completedReservation, isTrue);
  });

  test('aynı hata ama sipariş hâlâ held: hata gösterilir, tutma sürer',
      () async {
    h.stubHold();
    await h.putOrder('ord1', status: 'held');
    h.client.handlers['confirmReservation'] = (final _) =>
        throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
    final c = ctrl()..toggleSeat('A1');
    await c.holdSelected();
    expect(await c.confirmReservation(), isFalse);
    expect(st().phase, PurchasePhase.held);
    expect(st().notice, isNotNull);
  });

  test('kesin iş-kuralı reddi (resource-exhausted) siparişe bakılmadan hata',
      () async {
    h.stubHold();
    await h.putOrder('ord1', status: 'reserved');
    h.client.handlers['confirmReservation'] = (final _) =>
        throw FirebaseFunctionsException(
            message: 'Limit doldu.', code: 'resource-exhausted');
    final c = ctrl()..toggleSeat('A1');
    await c.holdSelected();
    expect(await c.confirmReservation(), isFalse);
    expect(st().phase, PurchasePhase.selecting);
  });
}
