import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

final class TiyatrolCommunicationActions {
  TiyatrolCommunicationActions._();

  // --- SOSYAL MEDYA VE İLETİŞİM BİLGİLERİ ---
  static const String _instagramUser = "tiyatrol";
  static const String _facebookPage = "tiyatrol"; // Facebook ID veya sayfa adı
  static const String _officialWhatsApp = "905XXXXXXXXX"; // Ülke kodu
  static const String _officialEmail = "iletisim@tiyatrol.com";

  // --- 📧 E-POSTA GÖNDER ---
  static Future<void> sendEmail(
      {final String subject = "TiyatRol Destek"}) async {
    final Uri uri = Uri(
        scheme: 'mailto',
        path: _officialEmail,
        queryParameters: {'subject': subject});
    await _launch(uri);
  }

  // --- 📱 WHATSAPP DESTEK HATTI ---
  static Future<void> contactWhatsApp() async {
    final Uri url = Uri.parse(
        "https://wa.me/$_officialWhatsApp?text=${Uri.encodeComponent("Merhaba, oyunlar ve biletler hakkında bilgi almak istiyorum.")}");
    await _launch(url);
  }

  // --- 📸 INSTAGRAM PROFİLİNİ AÇ ---
  static Future<void> openInstagram() async {
    final Uri nativeUrl =
        Uri.parse("instagram://user?username=$_instagramUser");
    final Uri webUrl = Uri.parse("https://www.instagram.com/$_instagramUser");
    await _launchWithFallback(nativeUrl, webUrl);
  }

  // --- 👥 FACEBOOK SAYFASINI AÇ ---
  static Future<void> openFacebook() async {
    final Uri nativeUrl = Uri.parse("fb://facename/$_facebookPage");
    final Uri webUrl = Uri.parse("https://www.facebook.com/$_facebookPage");
    await _launchWithFallback(nativeUrl, webUrl);
  }

  // --- 📍 SAHNE KONUMUNU HARİTALARDA AÇ ---
  static Future<void> openStageLocation({
    required final double lat,
    required final double lng,
    final String? stageName,
  }) async {
    // Google Maps (Android/iOS)
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    // Apple Maps (Sadece iOS)
    final Uri appleMapsUrl = Uri.parse(
        "https://maps.apple.com/?q=${stageName ?? 'Sahne'}&ll=$lat,$lng");

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }

      if (await canLaunchUrl(googleMapsUrl))
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      else
        throw 'Harita uygulaması bulunamadı.';
    } catch (e) {
      debugPrint("Harita açılırken hata oluştu: $e");
    }
  }

  // --- 🛠 YARDIMCI METOTLAR ---

  /// Önce uygulama (native) denemesi yapar, başarısız olursa tarayıcıda açar.
  static Future<void> _launchWithFallback(
      final Uri nativeUrl, final Uri webUrl) async {
    try {
      final bool launched = await launchUrl(nativeUrl,
          mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) await _launch(webUrl);
    } catch (e) {
      await _launch(webUrl);
    }
  }

  /// Genel URL başlatıcı
  static Future<void> _launch(final Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
        debugPrint("URL başlatılamadı: $url");
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }
}
