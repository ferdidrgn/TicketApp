import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
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
        'Ruhunu sanatla besleyecek bu serüvene sen de katıl:'
        ' ${AppConstants.shareUrl}',
        subject: 'Sanat Serüveni',
      );

  @override
  Widget build(final BuildContext context) {
    final theme = context.theme;
    final colors = context.colors;

    return Scaffold(
      // AppBar'ı şeffaf yaparak arka planın yukarı kadar uzamasını sağlıyoruz
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'ATÖLYE PANELİ',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // --- İŞTE BURADA KULLANIYORUZ ---
      body: CustomAppBackground(
        // İstersen buraya özel renkler geçebilirsin, boş bırakırsan default temayı kullanır
        ambientColor: colors.primary.withOpacity(0.1),
        particleColor: colors.secondary.withOpacity(0.2),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vizyon Bölümü
                const InspirationalQuoteView(
                  word: "Sanat, görünmeyeni görünür kılar.",
                  author: "Paul Klee",
                  imageUrl:
                      'https://images.unsplash.com/photo-1549490349-8643362247b5?q=80&w=800&auto=format&fit=crop',
                ),

                const SizedBox(height: 40),
                _buildModernHeader(theme, 'SİSTEMLE SENKRONİZASYON'),
                const SizedBox(height: 16),

                _buildGlassTile(
                  context,
                  title: 'Mekansal Farkındalık',
                  subtitle: 'Yakınındaki sanat duraklarını keşfet.',
                  icon: Icons.explore_outlined,
                  color: colors.primary,
                  onTap: () => _handlePermission(Permission.location),
                ),
                _buildGlassTile(
                  context,
                  title: 'Fısıltılar (Bildirimler)',
                  subtitle: 'Yeni bir eser doğduğunda ilk sen duy.',
                  icon: Icons.auto_awesome_outlined,
                  color: colors.secondary,
                  onTap: () => _handlePermission(Permission.notification),
                ),

                const SizedBox(height: 40),
                _buildModernHeader(theme, 'ESTETİK PAYLAŞIM'),
                const SizedBox(height: 16),

                _buildHeroAction(
                  context,
                  title: 'Galerimizi Yıldızla',
                  desc: 'Bu serüvene senin yorumun yön versin.',
                  icon: Icons.star_rounded,
                  gradient: [colors.primary, colors.primary.withOpacity(0.7)],
                  onTap: () =>
                      UrlLauncherService.launchUrl(AppConstants.playStoreUrl),
                ),
                const SizedBox(height: 20),
                _buildHeroAction(
                  context,
                  title: 'İlhamı Dalgalandır',
                  desc: 'Sanatı bir dostuna hediye et.',
                  icon: Icons.ios_share_rounded,
                  gradient: [
                    colors.secondary,
                    colors.secondary.withOpacity(0.7)
                  ],
                  onTap: _shareApp,
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAction(
    final BuildContext context, {
    required final String title,
    required final String desc,
    required final IconData icon,
    required final List<Color> gradient,
    required final VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: gradient.first.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Stack(
          children: [
            // Arka plan dekoratif büyük ikon
            Positioned(
              right: -20,
              bottom: -20,
              child:
                  Icon(icon, size: 120, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 36),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        Text(desc,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(final ThemeData theme, final String title) {
    return Row(
      children: [
        Text(title,
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: theme.colorScheme.primary.withOpacity(0.5))),
        const SizedBox(width: 12),
        Expanded(
            child: Divider(
                color: theme.colorScheme.primary.withOpacity(0.1),
                thickness: 2)),
      ],
    );
  }

  Widget _buildGlassTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;

    // Dark modda renkleri daha "neon" ve canlı göstermek için ayarlama
    final effectiveColor =
        isDark ? Color.lerp(color, Colors.white, 0.2)! : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Dark modda zemini biraz daha belirgin yapıyoruz
          color: isDark
              ? effectiveColor.withOpacity(0.08)
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            // Çerçeveyi dark modda daha parlak yapıyoruz
            color: effectiveColor.withOpacity(isDark ? 0.3 : 0.12),
            width: 1.5, // Biraz daha kalınlaştırdık
          ),
          // Dark modda hafif bir parlama (Glow) efekti ekleyelim
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                // İkon kutusu dark modda daha yoğun bir renk
                color: effectiveColor.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: effectiveColor, // Daha parlak renk
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white.withOpacity(0.9) : null,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      // Alt metin dark modda çok sönmesin diye opaklığı artırdık
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : context.colors.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: effectiveColor.withOpacity(isDark ? 0.6 : 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
