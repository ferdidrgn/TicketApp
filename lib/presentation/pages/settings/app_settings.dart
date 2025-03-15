import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/util/url_launcher_service.dart';
import '../../../core/widgets/custom_art_words_card.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  String get reviewUrl => AppConstants.playStoreUrl;

  String get featuresUrl => AppConstants.playStoreUrl;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomArtWordsCard(
                  word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
              const SizedBox(height: 30),
              _buildActionButton(
                context: context,
                text: 'Uygulamayı Oyla',
                icon: Icons.star,
                onPressed: () => UrlLauncherService.launchUrl(reviewUrl),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context: context,
                text: 'Uygulamayı Paylaş',
                icon: Icons.share,
                onPressed: () =>
                    UrlLauncherService.launchUrl(AppConstants.shareUrl),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context: context,
                text: 'Uygulama Özellikleri',
                icon: Icons.info,
                onPressed: () => UrlLauncherService.launchUrl(featuresUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButton(
    {required final Future<void> Function() onPressed,
    required final String text,
    required final IconData icon,
    required final BuildContext context}) {
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
