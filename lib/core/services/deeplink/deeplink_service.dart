import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../common/extentions/reg_exp_extentions.dart';
import 'deeplink_service_stub.dart'
    if (dart.library.js_interop) 'deeplink_service_web.dart';
// KOŞULLU IMPORT: Web ise web dosyasını, değilse stub dosyasını yükle

final class DeeplinkShareService {
  DeeplinkShareService._();

  static const String _baseUrl = "https://saglamspot.com";

  static String generateProductUrl(final String id, final String name) {
    final slug = name.toSlug();
    return "$_baseUrl/product/$slug-$id";
  }

  static Future<void> shareProduct({
    required final String productId,
    required final String productName,
  }) async {
    final url = generateProductUrl(productId, productName);
    final message = "Sağlam Spot - $productName\n$url";

    await Share.share(
      message,
      subject: productName,
    );
  }

  /// WEB ONLY — SEO + OG META
  static void updateWebMeta({
    required final String title,
    required final String description,
    required final String imageUrl,
    required final String productId,
    required final String productName,
  }) {
    if (!kIsWeb) return;

    try {
      final url = generateProductUrl(productId, productName);
      setMeta(title, description, imageUrl, url);
    } catch (e) {
      debugPrint("Meta error: $e");
    }
  }
}
