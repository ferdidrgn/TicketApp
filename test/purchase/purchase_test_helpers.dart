import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/firestore_provider.dart';
import 'package:ticketapp/features/auth/presentation/providers/phone_link_provider.dart';
import 'fake_phone_link.dart';
import 'package:ticketapp/features/purchase/data/datasources/purchase_remote_data_source_and_impl.dart';
import 'package:ticketapp/features/purchase/presentation/providers/purchase_provider.dart';

/// Sahte callable istemcisi: çağrıları kaydeder, senaryolu cevap/hata verir.
class FakeCallableClient implements PurchaseCallableClient {
  final List<({String name, Map<String, dynamic> data})> calls = [];

  /// name → cevap üreticisi (hata için `throw`).
  final Map<String, FutureOr<Map<String, dynamic>> Function(Map<String, dynamic>)>
      handlers = {};

  Iterable<Map<String, dynamic>> callsOf(final String name) =>
      calls.where((final c) => c.name == name).map((final c) => c.data);

  @override
  Future<Map<String, dynamic>> call(
      final String name, final Map<String, dynamic> data) async {
    calls.add((name: name, data: data));
    final h = handlers[name];
    if (h == null) throw StateError('beklenmeyen çağrı: $name');
    return h(data);
  }
}

/// Test ortamı: sahte callable + sahte Firestore + oynatılabilir saat.
class PurchaseHarness {
  final FakeCallableClient client = FakeCallableClient();
  final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
  DateTime now = DateTime(2026, 11, 1, 20, 0, 0);

  /// Varsayılan: telefonu doğrulanmış kullanıcı.
  final FakePhoneLink phone = FakePhoneLink();

  late final ProviderContainer container = ProviderContainer(overrides: [
    phoneLinkServiceProvider.overrideWithValue(phone),
    purchaseCallableClientProvider.overrideWithValue(client),
    firestoreProvider.overrideWithValue(firestore),
    purchaseClockProvider.overrideWithValue(() => now),
  ]);

  void dispose() => container.dispose();

  /// `holdSeats` için varsayılan başarılı cevap.
  void stubHold({
    final String orderId = 'ord1',
    final Duration ttl = const Duration(minutes: 10),
    final double unit = 150,
    final bool free = false,
  }) {
    client.handlers['holdSeats'] = (final data) {
      final ids = (data['seatIds'] as List).cast<String>();
      return {
        'orderId': orderId,
        'expiresAt': now.add(ttl).millisecondsSinceEpoch,
        'total': free ? 0 : unit * ids.length,
        'currency': 'TRY',
        'free': free,
        'seats': [
          for (final id in ids) {'id': id, 'price': free ? 0 : unit}
        ],
      };
    };
    client.handlers['releaseHold'] = (final _) => {'ok': true};
  }

  Future<void> putOrder(
    final String id, {
    final String userId = 'u1',
    final String eventId = 'e1',
    final List<String> seatIds = const ['A1'],
    final String status = 'held',
    final Duration expiresIn = const Duration(minutes: 5),
    final bool free = false,
    final double total = 150,
  }) =>
      firestore.collection('Order').doc(id).set({
        'userId': userId,
        'eventId': eventId,
        'showId': 's1',
        'seatIds': seatIds,
        'status': status,
        'free': free,
        'total': total,
        'expiresAt': Timestamp.fromDate(now.add(expiresIn)),
      });
}
