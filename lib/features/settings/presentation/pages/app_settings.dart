import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/services/deeplink/deeplink_service.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_art_inspirational_quote_view.dart';
import '../../../../shared/widgets/footers/footer.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        children: [
          // 🕊️ İLHAM KARTI
          const InspirationalQuoteView(
            word: "Sanat, ruhun üzerindeki günlük yaşamın tozunu siler.",
            author: "Pablo Picasso",
            imageUrl:
                'https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=800&auto=format&fit=crop',
          ),

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, 'DUYUSAL AYARLAR'),
          const SizedBox(height: AppSpacing.lg),

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

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, 'GALERİ YAYILIMI'),
          const SizedBox(height: AppSpacing.lg),

          _buildCreativeAction(
            context,
            title: 'Atölyeyi Puanla',
            desc: 'Bu koleksiyonu yıldızlarla parlat.',
            icon: Icons.auto_awesome_rounded,
            gradient: [colors.primary, colors.primaryContainer],
            textColor: colors.onPrimary,
            onTap: () => TiyatrolDeeplinkService.shareApp(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCreativeAction(
            context,
            title: 'İlhamı Paylaş',
            desc: 'Sanatı bir dostunun kalbine bırak.',
            icon: Icons.send_rounded,
            gradient: [colors.secondary, colors.secondaryContainer],
            textColor: colors.onSecondary,
            onTap: _shareApp,
          ),

          const SizedBox(height: AppSpacing.huge),
          Center(
            child: Text(
              'Versiyon 1.0.4 - Sanatla Tasarlandı',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withOpacity(0.3),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
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
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
            boxShadow: AppShadows.level1(color),
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
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
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
                const SizedBox(width: AppSpacing.md),
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
    required final Color textColor,
    required final VoidCallback onTap,
  }) =>
      Semantics(
        button: true,
        label: '$title. $desc',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(desc,
                          style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    color: textColor.withOpacity(0.7), size: 18),
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

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Mobil sohbet chrome'undan (TopHeaderWithBackButton, FAB, parçacıklar)
  // bağımsız, sade, ortalanmış ve dar bir sütun. Aynı ayarlar/aksiyonlar,
  // aynı callback'ler; sadece görsel kabuk değişiyor. Sayfanın en altına,
  // sitenin diğer masaüstü sayfalarıyla aynı tam genişlikte paylaşılan
  // `Footer` eklenir.
  Widget _buildDesktopPage(final BuildContext context) => ColoredBox(
        color: WebColors.darkBlueBackground,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.section),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Serüvenin teknik detaylarını restore et...',
                        style: TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.huge),
                      _buildDesktopSectionTitle('DUYUSAL AYARLAR'),
                      const SizedBox(height: AppSpacing.lg),
                      _DesktopHoverTile(
                        icon: Icons.location_searching_rounded,
                        title: 'Mekansal Rezonans',
                        subtitle: 'Çevrendeki sanat duraklarını hisset.',
                        onTap: () => _handlePermission(Permission.location),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DesktopHoverTile(
                        icon: Icons.vibration_rounded,
                        title: 'Sanat Fısıltıları',
                        subtitle: 'Yeni bir eser doğduğunda haberin olsun.',
                        onTap: () =>
                            _handlePermission(Permission.notification),
                      ),
                      const SizedBox(height: AppSpacing.huge),
                      _buildDesktopSectionTitle('GALERİ YAYILIMI'),
                      const SizedBox(height: AppSpacing.lg),
                      _DesktopHoverAction(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Atölyeyi Puanla',
                        desc: 'Bu koleksiyonu yıldızlarla parlat.',
                        onTap: () => TiyatrolDeeplinkService.shareApp(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DesktopHoverAction(
                        icon: Icons.send_rounded,
                        title: 'İlhamı Paylaş',
                        desc: 'Sanatı bir dostunun kalbine bırak.',
                        onTap: _shareApp,
                      ),
                      const SizedBox(height: AppSpacing.massive),
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
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
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
}

/// Masaüstü ayar satırı — fareyle üzerine gelindiğinde ("Sahne Köşesi"
/// imzası `AppRadius.asymSm` ile) hafifçe parlar. `TheatreShowCard`'daki
/// aynı hover diliyle (`AppMotion.fast` + `AppShadows`) tutarlı.
class _DesktopHoverTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DesktopHoverTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DesktopHoverTile> createState() => _DesktopHoverTileState();
}

class _DesktopHoverTileState extends State<_DesktopHoverTile> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: '${widget.title}. ${widget.subtitle}',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (final _) => setState(() => _hovered = true),
          onExit: (final _) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface,
                borderRadius: AppRadius.asymSm,
                border: Border.all(
                  color: _hovered
                      ? WebColors.primaryGold.withOpacity(0.8)
                      : WebColors.darkBlueAccent.withOpacity(0.8),
                  width: 1,
                ),
                boxShadow: _hovered
                    ? AppShadows.level2(WebColors.primaryGold)
                    : AppShadows.level0,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: WebColors.primaryGold, size: 22),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: TextStyle(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(widget.subtitle,
                            style: TextStyle(
                                color: WebColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: WebColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Masaüstü "önerilen aksiyon" kartı — büyük ölçekli "Sahne Köşesi"
/// (`AppRadius.asymLg`) ve hover'da `AppShadows.level3` ile yükselir.
class _DesktopHoverAction extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _DesktopHoverAction({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  State<_DesktopHoverAction> createState() => _DesktopHoverActionState();
}

class _DesktopHoverActionState extends State<_DesktopHoverAction> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: '${widget.title}. ${widget.desc}',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (final _) => setState(() => _hovered = true),
          onExit: (final _) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                borderRadius: AppRadius.asymLg,
                boxShadow: _hovered
                    ? AppShadows.level3(WebColors.primaryGold)
                    : AppShadows.level1(WebColors.primaryGold),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: WebColors.whiteText, size: 26),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: TextStyle(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(widget.desc,
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
          ),
        ),
      );
}
