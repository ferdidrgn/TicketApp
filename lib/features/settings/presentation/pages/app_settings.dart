import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/services/deeplink/deeplink_service.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/package_info_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/custom_art_inspirational_quote_view.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  Future<void> _handlePermission(final Permission permission) async {
    if (await permission.isDenied) await permission.request();
    await openAppSettings();
  }

  void _shareApp() => Share.share(
      'Ruhunu sanatla besleyecek bu serüvene sen de katıl: ${AppConstants.shareUrl}',
      subject: 'Sanat Serüveni');

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = context.theme;
    final colors = context.colors;
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      // 🎯 Header Parametreleri (Artık Wrapper tarafından otomatik yönetiliyor)
      title: 'ATÖLYE PANELİ',
      subtitle: 'Serüvenin teknik detaylarını restore et...',
      rightIcon: Icons.handyman_rounded,
      showBackButton: true,
      showFab: false,
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        safeAreaTop: true,
      ),
      // 💡 İçerik artık doğrudan ListView veya SingleChildScrollView olabilir
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isLargeScreen ? 760 : double.infinity),
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
              _buildSectionTitle(context, 'BİLDİRİMLER'),
              const SizedBox(height: 16),

              _buildAtelierTile(
                context,
                title: 'Bildirim Merkezi',
                subtitle: unreadCount > 0
                    ? '$unreadCount okunmamış bildirimin var'
                    : 'Kampanya, oyun ve bilet güncellemelerin burada.',
                icon: Icons.notifications_rounded,
                color: colors.tertiary,
                badgeCount: unreadCount,
                onTap: () => NavigationHandler.goToNotifications(context),
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
              _buildSectionTitle(context, 'DESTEK VE HUKUK'),
              const SizedBox(height: 16),

              _buildAtelierTile(
                context,
                title: 'Yardım ve Destek',
                subtitle: 'Sorularının cevabı burada.',
                icon: Icons.support_agent_rounded,
                color: colors.primary,
                onTap: () => NavigationHandler.goToHelpSupport(context),
              ),
              _buildAtelierTile(
                context,
                title: 'Sözleşmeler',
                subtitle: 'Kullanım koşulları ve gizlilik politikası.',
                icon: Icons.gavel_rounded,
                color: colors.secondary,
                onTap: () => NavigationHandler.goToContracts(context),
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
                onTap: () => TiyatrolDeeplinkService.rateApp(),
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
                  packageInfo.when(
                    data: (final info) =>
                        'Versiyon ${info.version} (${info.buildNumber}) - Sanatla Tasarlandı',
                    loading: () => 'Sanatla Tasarlandı',
                    error: (final _, final __) => 'Sanatla Tasarlandı',
                  ),
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
    final int badgeCount = 0,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BentoColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BentoColors.microBorder),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                if (badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                Icon(Icons.chevron_right_rounded, color: colors.outline),
                const SizedBox(width: 12),
              ],
            ),
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
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
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
