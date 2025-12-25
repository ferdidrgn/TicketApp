import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart'; // Yeni Header Class'ın
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/custom_art_inspirational_quote_view.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  Future<void> _handlePermission(final Permission permission) async {
    if (await permission.isDenied) await permission.request();
    await openAppSettings();
  }

  void _shareApp() => Share.share(
        'Ruhunu sanatla besleyecek bu serüvene sen de katıl: ${AppConstants.shareUrl}',
        subject: 'Sanat Serüveni',
      );

  @override
  Widget build(final BuildContext context) {
    final theme = context.theme;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomAppBackground(
        child: Column(
          children: [
            // 🎨 SANATSAL HEADER (Koleksiyon sayfanla aynı dilde)
            const TopNormalHeader(
              title: 'ATÖLYE PANELİ',
              subtitle: 'Serüvenin teknik detaylarını restore et...',
              rightIcon: Icons.handyman_rounded,
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🕊️ İLHAM KARTI
                    const InspirationalQuoteView(
                      word:
                          "Sanat, ruhun üzerindeki günlük yaşamın tozunu siler.",
                      author: "Pablo Picasso",
                      imageUrl:
                          'https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=800&auto=format&fit=crop',
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'DUYUSAL AYARLAR'),
                    const SizedBox(height: 16),

                    _buildAtelierTile(
                      context,
                      title: 'Mekansal Rezonans',
                      subtitle: 'Çevrendeki sanat duraklarını hisset.',
                      icon: Icons.location_searching_rounded,
                      color: colors.primary,
                      onTap: () => _handlePermission(Permission.location),
                    ),
                    _buildAtelierTile(
                      context,
                      title: 'Sanat Fısıltıları',
                      subtitle: 'Yeni bir eser doğduğunda haberin olsun.',
                      icon: Icons.vibration_rounded,
                      color: colors.secondary,
                      onTap: () => _handlePermission(Permission.notification),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'GALERİ YAYILIMI'),
                    const SizedBox(height: 16),

                    _buildCreativeAction(
                      context,
                      title: 'Atölyeyi Puanla',
                      desc: 'Bu koleksiyonu yıldızlarla parlat.',
                      icon: Icons.auto_awesome_rounded,
                      gradient: [colors.primary, colors.primaryContainer],
                      onTap: () => UrlLauncherService.launchUrl(
                          AppConstants.playStoreUrl),
                    ),
                    const SizedBox(height: 16),
                    _buildCreativeAction(
                      context,
                      title: 'İlhamı Paylaş',
                      desc: 'Sanatı bir dostunun kalbine bırak.',
                      icon: Icons.send_rounded,
                      gradient: [colors.secondary, colors.secondaryContainer],
                      onTap: _shareApp,
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Versiyon 1.0.4 - Sanatla Tasarlandı',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.3),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bilet sayfanla uyumlu dikey sidebar'lı liste elemanı
  Widget _buildAtelierTile(
    final BuildContext context, {
    required final String title,
    required final String subtitle,
    required final IconData icon,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Sanatçı fırçası darbesi gibi dikey bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.outline),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreativeAction(
    final BuildContext context, {
    required final String title,
    required final String desc,
    required final IconData icon,
    required final List<Color> gradient,
    required final VoidCallback onTap,
  }) =>InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(desc,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );

  Widget _buildSectionTitle(final BuildContext context, final String title) =>
      Text(
        title,
        style: context.theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          color: context.colors.primary.withOpacity(0.7),
        ),
      );
}
