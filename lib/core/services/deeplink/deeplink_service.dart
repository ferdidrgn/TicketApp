import 'package:share_plus/share_plus.dart';
import '../../common/constants/app_constants.dart';
import '../../common/extentions/reg_exp_extentions.dart';

final class TiyatrolDeeplinkService {
  TiyatrolDeeplinkService._();

  static const String _baseUrl = "https://www.tiyatrol.web.app";

  /// 🛠 URL Oluşturucu (Slug-ID yapısı)
  static String _createUrl(
      final String folder, final String name, final String id) {
    final slug = name.toSlug();
    return "$_baseUrl/$folder/$slug-$id";
  }

  /// 🎭 Gösteri Paylaşımı
  static Future<void> shareShow(
      {required final String id, required final String name}) async {
    final url = _createUrl("show", name, id);
    await Share.share(
        "TiyatRol - $name oyununu kaçırma! 🎭\nDetaylar ve Bilet: $url");
  }

  /// 👤 Oyuncu/Ekip Paylaşımı
  static Future<void> shareActor(
      {required final String id, required final String name}) async {
    final url = _createUrl("team", name, id);
    await Share.share(
        "Ekibimizin yetenekli ismi $name hakkında her şey burada: $url");
  }

  /// 🎟 Bilet Paylaşımı
  static Future<void> shareTicket(final String ticketId) async {
    final url = "$_baseUrl/my-tickets/$ticketId";
    await Share.share("Biletini buradan kontrol edebilirsin: $url");
  }

  /// 📱 Uygulama Paylaşımı (Market Linkleri ile)
  static Future<void> shareApp() async {
    const String message = "TiyatRol ile sanat her yerde! 🎭\n\n"
        "Hemen indirmek için:\n"
        "🤖 Android: ${AppConstants.playStoreUrl}\n"
        "🍎 iOS: ${AppConstants.appStoreUrl}";

    await Share.share(message);
  }
}
