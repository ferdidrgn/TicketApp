import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/custom_art_words_card.dart';

class AppSettingsPage extends StatelessWidget {
  final String appStoreUrl =
      'https://apps.apple.com/app/idYOUR_APP_ID'; // App Store URL
  final String playStoreUrl =
      'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME'; // Google Play Store URL

  const AppSettingsPage({super.key});

  String get reviewUrl => playStoreUrl;

  String get shareUrl =>
      'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';

  String get featuresUrl => playStoreUrl;

  Future<void> _launchUrl(final String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'URL açılamadı: $url';
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomArtWordsCard(
                  word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
              const SizedBox(height: 30),
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
      ),
    );
  }

  Widget _buildActionButton(
    final BuildContext context,
    final String text,
    final IconData icon,
    final VoidCallback onPressed,
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
