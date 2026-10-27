import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/purchase_entities.dart';

/// Cloud Functions bölgesi (functions/src/config.js > REGION).
const String kPurchaseFunctionsRegion = 'europe-west1';

/// Sunucu `HttpsError(failed-precondition, details.code = PHONE_REQUIRED)`
/// döndüğünde kullanılan istemci hata kodu/metni.
const String kPhoneRequiredCode = 'phone-required';
const String kPhoneRequiredMessage =
    'Devam etmek için telefon numaranı doğrulaman gerekiyor.';

/// Callable çağrısını soyutlar: üretimde `FirebaseFunctions`, testte sahte.
abstract class PurchaseCallableClient {
  /// [name] callable adı; dönen değer her zaman `Map` (sunucu sözleşmesi).
  Future<Map<String, dynamic>> call(
      final String name, final Map<String, dynamic> data);
}

class FirebasePurchaseCallableClient implements PurchaseCallableClient {
  final FirebaseFunctions _functions;

  FirebasePurchaseCallableClient({final FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: kPurchaseFunctionsRegion);

  @override
  Future<Map<String, dynamic>> call(
      final String name, final Map<String, dynamic> data) async {
    final result = await _functions.httpsCallable(name).call<Object?>(data);
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}

/// Kullanıcıya gösterilebilir, teknik sızıntısı olmayan hata.
class PurchaseException implements Exception {
  final String code;
  final String message;

  const PurchaseException(this.code, this.message);

  @override
  String toString() => 'PurchaseException($code): $message';
}

abstract class PurchaseRemoteDataSource {
  Future<SeatHold> holdSeats(final String eventId, final List<String> seatIds);
  Future<void> releaseHold(final String orderId);
  Future<PaymentSession> startPayment(
      final String orderId, final String returnUrl);
  Future<List<String>> confirmFree(final String orderId);
  Future<List<String>> confirmReservation(final String orderId);
  Future<void> cancelTicket(final String ticketId);
  Stream<SalesConfig> watchSalesConfig();
  Stream<PurchaseOrder?> watchOrder(final String orderId);
  Future<List<PurchaseOrder>> getOpenOrders(final String userId);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final PurchaseCallableClient client;
  final FirebaseFirestore firestore;

  PurchaseRemoteDataSourceImpl(
      {required this.client, required this.firestore});

  CollectionReference<Map<String, dynamic>> get _orders =>
      firestore.collection('Order');

  /// Sunucu mesajının (Türkçe, kullanıcıya yönelik) olduğu gibi gösterilebildiği
  /// kodlar. Diğer kodlarda (internal/unavailable/unknown…) sunucu ya da SDK
  /// metni gösterilmez; sabit genel mesaj kullanılır.
  static const _trustedMessageCodes = {
    'failed-precondition',
    'resource-exhausted',
    'invalid-argument',
    'permission-denied',
    'not-found',
  };

  static const String _generic =
      'İşlem şu anda tamamlanamadı. Lütfen biraz sonra tekrar dene.';

  /// FirebaseFunctionsException ve diğer hataları [PurchaseException]'a çevirir.
  static PurchaseException mapError(final Object e) {
    if (e is PurchaseException) {
      return e;
    }
    if (e is FirebaseFunctionsException) {
      final code = e.code;
      final msg = (e.message ?? '').trim();
      // Sunucu: doğrulanmış telefon yok / token'da claim eski.
      final details = e.details;
      if (details is Map && details['code'] == 'PHONE_REQUIRED') {
        return const PurchaseException(
            kPhoneRequiredCode, kPhoneRequiredMessage);
      }
      if (code == 'unauthenticated') {
        return const PurchaseException(
            'unauthenticated', 'Devam etmek için giriş yapmalısın.');
      }
      if (_trustedMessageCodes.contains(code) &&
          msg.isNotEmpty &&
          msg.length <= 240) {
        return PurchaseException(code, msg);
      }
      if (code == 'unavailable' || code == 'deadline-exceeded') {
        return const PurchaseException('network',
            'Sunucuya şu an ulaşılamıyor. Bağlantını kontrol edip tekrar dene.');
      }
      return PurchaseException(code, _generic);
    }
    if (e is FirebaseException) {
      return const PurchaseException('unknown', _generic);
    }
    return const PurchaseException('unknown', _generic);
  }

  Future<Map<String, dynamic>> _call(
      final String name, final Map<String, dynamic> data) async {
    try {
      return await client.call(name, data);
    } catch (e) {
      throw mapError(e);
    }
  }

  static double _num(final Object? v) => v is num ? v.toDouble() : 0;

  static DateTime? _date(final Object? v) {
    if (v is Timestamp) {
      return v.toDate();
    }
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    return null;
  }

  static String _str(final Object? v) => v is String ? v : '';

  static List<String> _strings(final Object? v) =>
      v is List ? [for (final x in v) x.toString()] : const [];

  @override
  Future<SeatHold> holdSeats(
      final String eventId, final List<String> seatIds) async {
    // YALNIZCA kimlikler gider; fiyat/tutar istemciden asla gönderilmez.
    final r = await _call(
        'holdSeats', {'eventId': eventId, 'seatIds': List<String>.of(seatIds)});
    final orderId = _str(r['orderId']);
    final expires = _date(r['expiresAt']);
    if (orderId.isEmpty || expires == null) {
      throw const PurchaseException('unknown', _generic);
    }
    final seats = r['seats'];
    return SeatHold(
      orderId: orderId,
      expiresAt: expires,
      total: _num(r['total']),
      currency: _str(r['currency']).isEmpty ? 'TRY' : _str(r['currency']),
      free: r['free'] == true,
      seats: [
        if (seats is List)
          for (final s in seats)
            if (s is Map)
              HeldSeat(id: _str(s['id']), price: _num(s['price'])),
      ],
    );
  }

  @override
  Future<void> releaseHold(final String orderId) async {
    await _call('releaseHold', {'orderId': orderId});
  }

  @override
  Future<PaymentSession> startPayment(
      final String orderId, final String returnUrl) async {
    final r = await _call('startPayment',
        {'orderId': orderId, 'provider': 'iyzico', 'returnUrl': returnUrl});
    final url = _str(r['paymentPageUrl']);
    final html = _str(r['checkoutFormContent']);
    if (url.isEmpty && html.isEmpty) {
      throw const PurchaseException('unknown', _generic);
    }
    return PaymentSession(
      provider: _str(r['provider']).isEmpty ? 'iyzico' : _str(r['provider']),
      token: _str(r['token']),
      paymentPageUrl: url.isEmpty ? null : url,
      checkoutFormContent: html.isEmpty ? null : html,
    );
  }

  @override
  Future<List<String>> confirmFree(final String orderId) async {
    final r = await _call('confirmFree', {'orderId': orderId});
    return _strings(r['ticketIds']);
  }

  @override
  Future<List<String>> confirmReservation(final String orderId) async {
    final r = await _call('confirmReservation', {'orderId': orderId});
    return _strings(r['ticketIds']);
  }

  @override
  Future<void> cancelTicket(final String ticketId) async {
    await _call('cancelTicket', {'ticketId': ticketId});
  }

  @override
  Stream<SalesConfig> watchSalesConfig() => firestore
      .collection('Config')
      .doc('satis')
      .snapshots()
      .map((final d) => SalesConfig.fromMap(d.data()));

  PurchaseOrder? _orderFrom(
      final DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) {
      return null;
    }
    return PurchaseOrder(
      id: doc.id,
      userId: _str(d['userId']),
      eventId: _str(d['eventId']),
      showId: _str(d['showId']),
      stageId: _str(d['stageId']),
      seatIds: _strings(d['seatIds']),
      total: _num(d['total']),
      free: d['free'] == true,
      status: OrderStatus.parse(d['status']),
      expiresAt: _date(d['expiresAt']),
      ticketIds: _strings(d['ticketIds']),
    );
  }

  @override
  Stream<PurchaseOrder?> watchOrder(final String orderId) =>
      _orders.doc(orderId).snapshots().map(_orderFrom);

  @override
  Future<List<PurchaseOrder>> getOpenOrders(final String userId) async {
    if (userId.isEmpty) {
      return const [];
    }
    try {
      // Güvenlik kuralı yalnızca kendi `userId`'li siparişlerin okunmasına
      // izin verir; sorgu bu alana göre filtrelenir.
      final snap = await _orders
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: const ['held', 'paying']).get();
      return [
        for (final d in snap.docs)
          if (_orderFrom(d) case final o?) o,
      ];
    } catch (e) {
      throw mapError(e);
    }
  }
}
