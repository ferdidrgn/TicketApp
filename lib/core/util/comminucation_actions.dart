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
  // `Uri(queryParameters:)` boşlukları `+` olarak kodluyor ve mail
  // istemcileri konuyu "TiyatRol+Destek" diye gösteriyordu — mailto için
  // `%20` gerekiyor.
  static Future<void> sendEmail(
      {final String subject = "TiyatRol Destek"}) async {
    final Uri uri = Uri.parse(
        'mailto:$_officialEmail?subject=${Uri.encodeComponent(subject)}');
    await _launch(uri);
  }

  // --- 📱 WHATSAPP DESTEK HATTI ---
  static Future<void> contactWhatsApp() async {
    final Uri url = Uri.parse(
        "https://wa.me/$_officialWhatsApp?text=${Uri.encodeComponent("Merhaba, oyunlar ve biletler hakkında bilgi almak istiyorum.")}");
    await _launch(url);
  }

  // --- 📸 INSTAGRAM PROFİLİNİ AÇ ---
  // Eskiden önce `instagram://` / `fb://facename/` gibi özel şemalar
  // deneniyordu. Web'de bu şemalar hiçbir şey açmadan "başarılı" dönüyordu
  // (yedek https linkine hiç düşmüyordu), `fb://facename/` ise geçerli bir
  // Facebook şeması bile değil. Doğrudan https linki açılıyor: web'de yeni
  // sekme, Android/iOS'ta uygulama yüklüyse işletim sistemi (App Links /
  // Universal Links) linki zaten uygulamaya yönlendiriyor.
  static Future<void> openInstagram() async =>
      _launch(Uri.parse("https://www.instagram.com/$_instagramUser"));

  // --- 👥 FACEBOOK SAYFASINI AÇ ---
  static Future<void> openFacebook() async =>
      _launch(Uri.parse("https://www.facebook.com/$_facebookPage"));

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

  // --- 🔎 SAHNEYİ GOOGLE'DA (ADRESİYLE) AÇ ---
  // `openStageLocation` enlem/boylam ile Google Maps'i navigasyon niyetiyle
  // açıyor; bu ise "Yakınımdakiler" kartlarındaki "Google'da Gör/Fotoğraflar"
  // aksiyonu için ayrı bir GERÇEK giriş noktası — sahnenin gerçek adıyla
  // gerçek adresini bir Google Maps arama URL'sine (`/maps/search`) taşıyor.
  // Stage entity'sinde bir Google Place ID alanı YOK (bkz.
  // `lib/features/stages/domain/entities/stage.dart`) — uydurma bir Place
  // ID icat etmek yerine, Google'ın kendi arama/eşleştirmesine bırakılıyor;
  // Google o adresi kendi kayıtlı bir işletmeyle eşleştirirse kullanıcı
  // orada Google'ın kendi (gerçek, bizim üretmediğimiz) fotoğraflarını da
  // görebilir.
  static Future<void> openAddressOnGoogleMaps(final String query) async {
    if (query.trim().isEmpty) return;
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    await _launch(googleMapsUrl);
  }

  // --- 🛠 YARDIMCI METOTLAR ---

  /// Genel URL başlatıcı
  static Future<void> _launch(final Uri url) async {
    try {
      final launched = await launchUrl(
        url,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        // mailto yeni sekmede açılırsa arkada boş bir sekme kalıyor.
        webOnlyWindowName: url.scheme == 'mailto' ? '_self' : '_blank',
      );
      if (!launched) debugPrint("URL başlatılamadı: $url");
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }
}
