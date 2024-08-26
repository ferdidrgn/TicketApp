import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSettingsPage extends StatelessWidget {
  // App Store ve Google Play Store URL'leri
  final String appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID'; // App Store URL
  final String playStoreUrl = 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';

  const AppSettingsPage({super.key}); // Google Play Store URL

  // Uygulamayı oyla sayfası URL'leri
  String get reviewUrl => playStoreUrl; // Google Play Store URL'yi kullan

  // Uygulamayı paylaşma URL'leri
  String get shareUrl => 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME'; // Google Play Store URL

  // Uygulama özellikleri URL'leri
  String get featuresUrl => playStoreUrl; // Google Play Store URL'yi kullan

  // URL'yi açma fonksiyonu
  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'URL açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildActionButton(
              context,
              'Uygulamayı Oyla',
              Icons.star,
                  () => _launchUrl(reviewUrl),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Uygulamayı Paylaş',
              Icons.share,
                  () => _launchUrl(shareUrl),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Uygulama Özellikleri',
              Icons.info,
                  () => _launchUrl(featuresUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      onPressed: onPressed,
    );
  }
}