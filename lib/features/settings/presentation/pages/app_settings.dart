import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/services/deeplink/deeplink_service.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_art_inspirational_quote_view.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  Future<void> _handlePermission(final Permission permission) async {
    if (await permission.isDenied) await permission.request();
    await openAppSettings();
  }

  void _shareApp() => Share.share(
      'Ruhunu sanatla besleyecek bu serüvene sen de katıl: ${AppConstants.shareUrl}',
      subject: 'Sanat Serüveni');

  @override
  Widget build(final BuildContext context) {
    // 🖥️ Masaüstü/web: BasePageWrapper'ın mobil zırhı (gradient başlık, FAB,
    // parçacık arkaplanı) yerine kendi sade web kabuğunu kullanır.
    if (context.isDesktop) return _buildDesktopPage(context);

    final theme = context.theme;
    final colors = context.colors;

    return BasePageWrapper(
      // 🎯 Header Parametreleri (Artık Wrapper tarafından otomatik yönetiliyor)
      title: 'ATÖLYE PANELİ',
      subtitle: 'Serüvenin teknik detaylarını restore et...',
      rightIcon: Icons.handyman_rounded,
      showBackButton: true,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        safeAreaTop: true,
      ),
      // 💡 İçerik artık doğrudan ListView veya SingleChildScrollView olabilir
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          // 🕊️ İLHAM KARTI
          const InspirationalQuoteView(
            word: "Sanat, ruhun üzerindeki günlük yaşamın tozunu siler.",
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
            onTap: () => TiyatrolDeeplinkService.shareApp(),
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
  }) =>
      InkWell(
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
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12)),
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

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Mobil sohbet chrome'undan (TopHeaderWithBackButton, FAB, parçacıklar)
  // bağımsız, sade, ortalanmış ve dar bir sütun. Aynı ayarlar/aksiyonlar,
  // aynı callback'ler; sadece görsel kabuk değişiyor.
  Widget _buildDesktopPage(final BuildContext context) => ColoredBox(
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  'ATÖLYE PANELİ',
                  style: TextStyle(
                    color: WebColors.whiteText,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Serüvenin teknik detaylarını restore et...',
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                _buildDesktopSectionTitle('DUYUSAL AYARLAR'),
                const SizedBox(height: 16),
                _buildDesktopTile(
                  title: 'Mekansal Rezonans',
                  subtitle: 'Çevrendeki sanat duraklarını hisset.',
                  icon: Icons.location_searching_rounded,
                  onTap: () => _handlePermission(Permission.location),
                ),
                const SizedBox(height: 12),
                _buildDesktopTile(
                  title: 'Sanat Fısıltıları',
                  subtitle: 'Yeni bir eser doğduğunda haberin olsun.',
                  icon: Icons.vibration_rounded,
                  onTap: () => _handlePermission(Permission.notification),
                ),
                const SizedBox(height: 40),
                _buildDesktopSectionTitle('GALERİ YAYILIMI'),
                const SizedBox(height: 16),
                _buildDesktopAction(
                  title: 'Atölyeyi Puanla',
                  desc: 'Bu koleksiyonu yıldızlarla parlat.',
                  icon: Icons.auto_awesome_rounded,
                  onTap: () => TiyatrolDeeplinkService.shareApp(),
                ),
                const SizedBox(height: 12),
                _buildDesktopAction(
                  title: 'İlhamı Paylaş',
                  desc: 'Sanatı bir dostunun kalbine bırak.',
                  icon: Icons.send_rounded,
                  onTap: _shareApp,
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Versiyon 1.0.4 - Sanatla Tasarlandı',
                    style: TextStyle(
                      color: WebColors.textTertiary,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

  Widget _buildDesktopSectionTitle(final String title) => Text(
        title,
        style: TextStyle(
          color: WebColors.primaryGoldLight,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      );

  Widget _buildDesktopTile({
    required final String title,
    required final String subtitle,
    required final IconData icon,
    required final VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(6),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            border: Border.all(
                color: WebColors.darkBlueAccent.withOpacity(0.8), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: WebColors.primaryGold, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: WebColors.whiteText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: WebColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: WebColors.textTertiary, size: 20),
            ],
          ),
        ),
      );

  Widget _buildDesktopAction({
    required final String title,
    required final String desc,
    required final IconData icon,
    required final VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: WebColors.goldGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: WebColors.whiteText, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: WebColors.whiteText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(desc,
                        style: TextStyle(
                            color: WebColors.whiteText.withOpacity(0.85),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: WebColors.whiteText.withOpacity(0.7), size: 18),
            ],
          ),
        ),
      );
}
