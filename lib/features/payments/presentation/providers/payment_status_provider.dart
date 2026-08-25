import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `Payment/{paymentId}` dökümanını canlı izler. Bu döküman, ilgili
/// webhook (bkz. functions/payments/index.js: iyzicoWebhook / paytrWebhook
/// / stripeWebhook) sağlayıcıdan gerçek sonucu aldığında sunucu tarafında
/// 'paid' veya 'failed' olarak güncellenir — UI bu akışı dinleyerek
/// kullanıcıyı otomatik ilerletir, hiçbir zaman ödeme sonucunu client'ın
/// kendisi "varsayarak" işlem yapmaz.
final paymentStatusStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((final ref, final paymentId) {
  return FirebaseFirestore.instance
      .collection('Payment')
      .doc(paymentId)
      .snapshots()
      .map((final doc) => doc.data());
});
