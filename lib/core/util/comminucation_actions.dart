import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationActions {
  // --- TEMEL BİLGİLER ---
  static const String ticketBaseUrl = "https://www.tiyatrol.web.app/";
  static const String instagramUser = "tiyatrol";
  static const String officialPhoneNumber = "";

  // --- OYUN PAYLAŞ ---
  static Future<void> sharePlay(
      {required String playTitle, required String playId}) async {
    final String message =
        "Harika bir oyun buldum! 🎭 '$playTitle' oyununu mutlaka izlemelisin. \nDetaylar ve bilet: $ticketBaseUrl$playId";
    await Share.share(message);
  }

  // --- OYUNCU PAYLAŞ ---
  static Future<void> shareActor(
      {required String actorName, required String actorId}) async {
    final String url = "https://www.tiyatrol.web.app/team/$actorId";
    await Share.share(
        "Tiyatro ekibimizin yetenekli oyuncusu $actorName hakkında detaylı bilgi: $url");
  }

  // --- BİLET ALMA (URL LAUNCH) ---
  static Future<void> buyTicket(String playId) async {
    final Uri url = Uri.parse("$ticketBaseUrl$playId");
    await _launch(url);
  }

  // --- INSTAGRAM'A GİT ---
  static Future<void> openInstagram() async {
    final Uri nativeUrl = Uri.parse("instagram://user?username=$instagramUser");
    final Uri webUrl = Uri.parse("https://www.instagram.com/$instagramUser");

    try {
      // Önce uygulamayı (deep link) dene
      if (await canLaunchUrl(nativeUrl)) {
        await launchUrl(nativeUrl,
            mode: LaunchMode.externalApplication); // Düzeltildi
      } else {
        // Uygulama yoksa tarayıcıda aç
        await launchUrl(webUrl,
            mode: LaunchMode.externalApplication); // Düzeltildi
      }
    } catch (e) {
      await launchUrl(webUrl,
          mode: LaunchMode.externalApplication); // Düzeltildi
    }
  }

// --- ORTAK LAUNCHER ---
  static Future<void> _launch(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Düzeltildi
      throw 'Açamadık: $url';
    }
  }

  // --- WHATSAPP İLETİŞİM HATTI ---
  static Future<void> contactSupport() async {
    final Uri url = Uri.parse(
        "https://wa.me/$officialPhoneNumber?text=${Uri.encodeComponent("Merhaba, oyunlar/biletler hakkında bilgi almak istiyorum.")}");
    await _launch(url);
  }

  // --- SAHNE KONUMU (HARİTA) ---
  static Future<void> openStageLocation(
      {required double lat, required double lng}) async {
    final String appleUrl = "https://maps.apple.com/?q=$lat,$lng";
    final String googleUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    if (await canLaunchUrl(Uri.parse(googleUrl)))
      await launchUrl(Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication);
    else
      await launchUrl(Uri.parse(appleUrl),
          mode: LaunchMode.externalApplication);
  }
}
