import 'package:cloud_functions/cloud_functions.dart';

/// Kredi/banka kartı ödemesi için desteklenen sağlayıcılar. `id`, Cloud
/// Functions tarafındaki `createPaymentSession`'ın beklediği string ile
/// birebir eşleşmelidir (bkz. functions/payments/index.js).
enum PaymentGatewayProvider { iyzico, paytr, stripe }

extension PaymentGatewayProviderX on PaymentGatewayProvider {
  String get id => switch (this) {
        PaymentGatewayProvider.iyzico => 'iyzico',
        PaymentGatewayProvider.paytr => 'paytr',
        PaymentGatewayProvider.stripe => 'stripe',
      };

  String get displayName => switch (this) {
        PaymentGatewayProvider.iyzico => 'iyzico',
        PaymentGatewayProvider.paytr => 'PayTR',
        PaymentGatewayProvider.stripe => 'Stripe',
      };
}

class PaymentSession {
  final String paymentId;
  final String checkoutUrl;

  const PaymentSession({required this.paymentId, required this.checkoutUrl});
}

/// Sağlayıcı Cloud Functions tarafında henüz secret'larla yapılandırılmadığında
/// (bkz. functions/payments/secrets.js) fırlatılır. UI bu durumu ayrı
/// yakalayıp "bu yöntem şu an aktif değil" mesajı gösterebilir — genel bir
/// hata gibi ele alınmamalıdır.
class PaymentProviderNotConfiguredException implements Exception {
  final String message;
  const PaymentProviderNotConfiguredException(this.message);

  @override
  String toString() => message;
}

/// Kredi/banka kartı ödeme akışının Flutter tarafındaki tek giriş noktası.
/// Gerçek kart bilgileri hiçbir zaman uygulamadan geçmez — kullanıcı
/// sağlayıcının barındırılan (hosted) ödeme sayfasına yönlendirilir,
/// sonucu ise `Payment/{paymentId}` Firestore dökümanı üzerinden (bkz.
/// payment_status_provider.dart) öğrenilir.
abstract final class PaymentGatewayService {
  static Future<PaymentSession> createSession({
    required final PaymentGatewayProvider provider,
    required final String eventId,
    required final List<String> seatIds,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('createPaymentSession');
      final result = await callable.call<Map<String, dynamic>>({
        'provider': provider.id,
        'eventId': eventId,
        'seatIds': seatIds,
      });
      final data = result.data;
      return PaymentSession(
        paymentId: data['paymentId'] as String,
        checkoutUrl: data['checkoutUrl'] as String,
      );
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? e.code;
      if (message.contains('PAYMENT_PROVIDER_NOT_CONFIGURED')) {
        throw PaymentProviderNotConfiguredException(
          '${provider.displayName} ödeme yöntemi henüz aktif değil. '
          'Lütfen başka bir yöntem deneyin.',
        );
      }
      throw Exception(message);
    }
  }
}
