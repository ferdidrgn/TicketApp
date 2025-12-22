import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  String get reviewUrl => AppConstants.playStoreUrl;

  String get featuresUrl => AppConstants.playStoreUrl;

  void _shareApp() {
    final message = 'Bu uygulamayı incele: ${AppConstants.shareUrl}';
// share_plus güncel API kullanımı
    Share.share(message, subject: 'Tiyatrol App');
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Uygulama Ayarları')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomArtWordsCard(
                  word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
              const SizedBox(height: 30),
              CustomElevatedButton(
                text: 'Uygulamayı Oyla',
                iconData: Icons.star,
                backgroundColor: theme.colorScheme.primary,
                textColor: Colors.white,
                iconColor: Colors.white,
                arrowColor: Colors.white70,
                onPressed: () => UrlLauncherService.launchUrl(reviewUrl),
              ),
              const SizedBox(height: 16),
              CustomElevatedButton(
                text: 'Uygulamayı Paylaş',
                iconData: Icons.share,
                backgroundColor: theme.colorScheme.secondary,
                textColor: Colors.white,
                iconColor: Colors.white,
                arrowColor: Colors.white70,
                onPressed: _shareApp,
              ),
              const SizedBox(height: 16),
              CustomElevatedButton(
                text: 'Uygulama Özellikleri',
                iconData: Icons.info_outline,
                backgroundColor: theme.colorScheme.tertiary ?? Colors.teal,
                textColor: Colors.white,
                iconColor: Colors.white,
                arrowColor: Colors.white70,
                onPressed: () => UrlLauncherService.launchUrl(featuresUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
