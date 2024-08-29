import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSettingsPage extends StatelessWidget {
  final String appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID'; // App Store URL
  final String playStoreUrl = 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME'; // Google Play Store URL

  const AppSettingsPage({super.key});

  String get reviewUrl => playStoreUrl;
  String get shareUrl => 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';
  String get featuresUrl => playStoreUrl;

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'URL açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = MediaQuery.of(context).size.width * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sanatla ilgili görsel ve özlü söz
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/400x200'), // Sanatla ilgili görsel URL'sini buraya ekleyin
                  fit: BoxFit.cover,
                ),
              ),
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.5),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: const Text(
                          'Sanat, hayata dokunan bir büyüdür. Herkesin kendi sanatını yaratma zamanı!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Uygulama ayarları butonları
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
