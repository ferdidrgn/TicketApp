import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/services/deeplink/deeplink_service.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/custom_art_inspirational_quote_view.dart';
import '../../../../shared/widgets/footers/footer.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  // 🎨 Tiyatro Kulisi Hazır Vurgu Renkleri (Monet / Özel Palet)
  static const List<Color> _accentColorPresets = [
    Color(0xFFC50337), // Crimson Noir Ana Kırmızı
    Color(0xFF9C27B0), // Kadife Mor
    Color(0xFF3F51B5), // Sahne Mavisi
    Color(0xFF009688), // Kulis Yeşili
    Color(0xFFFF9800), // Sahne Işığı Amber
    Color(0xFFE91E63), // Perde Pembesi
    Color(0xFF795548), // Tahta Sahne Kahvesi
    Color(0xFF607D8B), // Fırtına Gri
    Color(0xFFFF5722), // Kırmızı Turuncu
    Color(0xFF673AB7), // Derin Gece Moru
  ];

  Future<void> _handlePermission(final Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    await permission.request();
  }

  void _shareApp(final BuildContext context) => Share.share(
      AppLocalizations.of(context)!.settingsShareMessage(AppConstants.shareUrl),
      subject: AppLocalizations.of(context)!.settingsShareSubject);

  Future<void> _showAccentColorPicker(
      final BuildContext context, final WidgetRef ref) async {
    final colors = context.colors;
    final currentColor = ref.read(customAccentColorProvider);

    await showDialog<void>(
      context: context,
      builder: (final dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(Icons.palette_rounded, color: colors.primary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.settingsAccentColorPickerTitle,
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sahne atmosferinizi kişiselleştirmek için bir renk fırça darbesi seçin:',
                style: TextStyle(
                  color: colors.onSurface.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: _accentColorPresets.map((final swatch) {
                  final isSelected = currentColor?.value == swatch.value;
                  return Semantics(
                    button: true,
                    label: AppLocalizations.of(context)!
                        .settingsAccentColorSemanticLabel,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(themeProvider.notifier)
                            .setCustomAccentColor(swatch);
                        Navigator.of(dialogContext).pop();
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.standard,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colors.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: AppShadows.level2(swatch),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.of(context)!.settingsCancel,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (context.isDesktop) return _buildDesktopPage(context, ref);

    final theme = context.theme;
    final colors = context.colors;
    final currentThemeStyle = ref.watch(themeProvider);
    final currentAccentColor = ref.watch(customAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        safeAreaTop: true,
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        children: [
          _SettingsHeroHeader(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsSubtitle,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 🎭 İLHAM VERİCİ SANAT KARTI
          InspirationalQuoteView(
            word: l10n.settingsQuoteText,
            author: l10n.settingsQuoteAuthor,
            imageUrl:
                'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?q=80&w=800&auto=format&fit=crop',
          ),

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, l10n.settingsSectionPermissions),
          const SizedBox(height: AppSpacing.lg),

          _buildAtelierTile(
            context,
            title: l10n.settingsLocationPermissionTitle,
            subtitle: l10n.settingsLocationPermissionSubtitle,
            icon: Icons.location_searching_rounded,
            color: colors.primary,
            onTap: () => _handlePermission(Permission.location),
          ),
          _buildAtelierTile(
            context,
            title: l10n.settingsNotificationsPermissionTitle,
            subtitle: l10n.settingsNotificationsPermissionSubtitle,
            icon: Icons.vibration_rounded,
            color: colors.secondary,
            onTap: () => _handlePermission(Permission.notification),
          ),

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, l10n.settingsSectionAppearance),
          const SizedBox(height: AppSpacing.lg),

          _buildAccentColorTile(
            context,
            currentThemeStyle: currentThemeStyle,
            currentAccentColor: currentAccentColor,
            onTap: () => _showAccentColorPicker(context, ref),
          ),

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, l10n.settingsSectionLanguage),
          const SizedBox(height: AppSpacing.lg),

          _buildLanguageTile(context, ref),

          const SizedBox(height: AppSpacing.xxxl),
          _buildSectionTitle(context, l10n.settingsSectionSupport),
          const SizedBox(height: AppSpacing.lg),

          _buildCreativeAction(
            context,
            title: l10n.settingsRecommendAppTitle,
            desc: l10n.settingsRecommendAppDesc,
            icon: Icons.auto_awesome_rounded,
            gradient: [colors.primary, colors.primaryContainer],
            textColor: colors.onPrimary,
            onTap: () => TiyatrolDeeplinkService.shareApp(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCreativeAction(
            context,
            title: l10n.settingsShareWithFriendsTitle,
            desc: l10n.settingsShareWithFriendsDesc,
            icon: Icons.send_rounded,
            gradient: [colors.secondary, colors.secondaryContainer],
            textColor: colors.onSecondary,
            onTap: () => _shareApp(context),
          ),

          const SizedBox(height: AppSpacing.huge),
          Center(
            child: Text(
              l10n.settingsVersionFooter,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withOpacity(0.35),
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

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
            border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
            boxShadow: AppShadows.level2(color.withOpacity(0.15)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
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
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
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
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: colors.onSurface.withOpacity(0.55),
                              fontSize: 12,
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

  Widget _buildAccentColorTile(
    final BuildContext context, {
    required final AppThemeStyle currentThemeStyle,
    required final Color? currentAccentColor,
    required final VoidCallback onTap,
  }) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isCustomActive = currentThemeStyle == AppThemeStyle.custom;
    final swatchColor = currentAccentColor ?? colors.primary;
    final subtitle = isCustomActive && currentAccentColor != null
        ? l10n.settingsAccentColorCustomSubtitle
        : l10n.settingsAccentColorDefaultSubtitle;

    return Semantics(
      button: true,
      label: '${l10n.settingsAccentColorTitle}. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
            boxShadow: AppShadows.level2(swatchColor.withOpacity(0.15)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: swatchColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: colors.outlineVariant, width: 2),
                      boxShadow: AppShadows.level1(swatchColor),
                    ),
                    child: const Icon(Icons.color_lens_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settingsAccentColorTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: colors.onSurface.withOpacity(0.55),
                              fontSize: 12,
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

  Widget _buildLanguageTile(final BuildContext context, final WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final localeAsync = ref.watch(localeControllerProvider);
    final currentLanguageCode = localeAsync.value?.languageCode ?? 'tr';

    return Semantics(
      label: '${l10n.settingsLanguageTitle}. ${l10n.settingsLanguageSubtitle}',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
          boxShadow: AppShadows.level2(colors.primary.withOpacity(0.15)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.translate_rounded,
                      color: colors.primary, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsLanguageTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(l10n.settingsLanguageSubtitle,
                        style: TextStyle(
                            color: colors.onSurface.withOpacity(0.55),
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              _buildLanguageOption(
                context,
                ref: ref,
                label: l10n.settingsLanguageTurkish,
                languageCode: 'tr',
                isSelected: currentLanguageCode == 'tr',
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildLanguageOption(
                context,
                ref: ref,
                label: l10n.settingsLanguageEnglish,
                languageCode: 'en',
                isSelected: currentLanguageCode == 'en',
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    final BuildContext context, {
    required final WidgetRef ref,
    required final String label,
    required final String languageCode,
    required final bool isSelected,
  }) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () => ref
            .read(localeControllerProvider.notifier)
            .setLocale(Locale(languageCode)),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: isSelected ? AppShadows.level1(colors.primary) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
              boxShadow: AppShadows.level2(gradient.first),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: textColor, size: 24),
                ),
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
                      const SizedBox(height: 2),
                      Text(desc,
                          style: TextStyle(
                              color: textColor.withOpacity(0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    color: textColor.withOpacity(0.8), size: 18),
              ],
            ),
          ),
        ),
      );

  Widget _buildSectionTitle(final BuildContext context, final String title) =>
      Text(
        title,
        style: context.theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 2.5,
          fontWeight: FontWeight.w900,
          color: context.colors.primary.withOpacity(0.8),
        ),
      );

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU (Crimson Noir & Velvet Gold Tiyatro Sahnesi) ---
  Widget _buildDesktopPage(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguageCode =
        ref.watch(localeControllerProvider).value?.languageCode ?? 'tr';

    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl, vertical: AppSpacing.section),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mükemmel Tiyatro Sahne Başlığı
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: WebColors.goldButtonGradient,
                            borderRadius: AppRadius.asymLg,
                            boxShadow: AppShadows.level3(WebColors.primaryGold),
                          ),
                          child: const Icon(Icons.theater_comedy_rounded,
                              color: WebColors.darkBlueBackground, size: 30),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAHNE KULİSİ & YÖNETİM MERKEZİ',
                                style: TextStyle(
                                  color: WebColors.primaryGoldLight,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.5,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.settingsTitle,
                                style: GoogleFonts.playfairDisplay(
                                  textStyle: const TextStyle(
                                    color: WebColors.whiteText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 38,
                                    letterSpacing: -0.5,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.settingsSubtitle,
                                style: const TextStyle(
                                  color: WebColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.huge),
                    _buildDesktopSectionTitle(l10n.settingsSectionPermissions),
                    const SizedBox(height: AppSpacing.lg),
                    _DesktopHoverTile(
                      icon: Icons.location_searching_rounded,
                      title: l10n.settingsLocationPermissionTitle,
                      subtitle: l10n.settingsLocationPermissionSubtitle,
                      onTap: () => _handlePermission(Permission.location),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DesktopHoverTile(
                      icon: Icons.vibration_rounded,
                      title: l10n.settingsNotificationsPermissionTitle,
                      subtitle: l10n.settingsNotificationsPermissionSubtitle,
                      onTap: () => _handlePermission(Permission.notification),
                    ),

                    const SizedBox(height: AppSpacing.huge),
                    _buildDesktopSectionTitle(l10n.settingsSectionLanguage),
                    const SizedBox(height: AppSpacing.lg),
                    _DesktopLanguageTile(
                      title: l10n.settingsLanguageTitle,
                      subtitle: l10n.settingsLanguageSubtitle,
                      turkishLabel: l10n.settingsLanguageTurkish,
                      englishLabel: l10n.settingsLanguageEnglish,
                      currentLanguageCode: currentLanguageCode,
                      onSelect: (final code) => ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(Locale(code)),
                    ),

                    const SizedBox(height: AppSpacing.huge),
                    _buildDesktopSectionTitle(l10n.settingsSectionSupport),
                    const SizedBox(height: AppSpacing.lg),
                    _DesktopHoverAction(
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.settingsRecommendAppTitle,
                      desc: l10n.settingsRecommendAppDesc,
                      onTap: () => TiyatrolDeeplinkService.shareApp(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DesktopHoverAction(
                      icon: Icons.send_rounded,
                      title: l10n.settingsShareWithFriendsTitle,
                      desc: l10n.settingsShareWithFriendsDesc,
                      onTap: () => _shareApp(context),
                    ),

                    const SizedBox(height: AppSpacing.massive),
                    Center(
                      child: Text(
                        l10n.settingsVersionFooter,
                        style: const TextStyle(
                          color: WebColors.textTertiary,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
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
  }

  Widget _buildDesktopSectionTitle(final String title) => Text(
        title,
        style: const TextStyle(
          color: WebColors.primaryGoldLight,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      );
}

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
                      ? WebColors.primaryGold.withOpacity(0.9)
                      : WebColors.darkBlueAccent.withOpacity(0.9),
                  width: 1.5,
                ),
                boxShadow: _hovered
                    ? AppShadows.level3(WebColors.primaryGold)
                    : AppShadows.level1(WebColors.darkBlueBackground),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: WebColors.primaryGold.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon,
                        color: WebColors.primaryGold, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(widget.subtitle,
                            style: const TextStyle(
                                color: WebColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: _hovered
                          ? WebColors.primaryGold
                          : WebColors.textTertiary,
                      size: 22),
                ],
              ),
            ),
          ),
        ),
      );
}

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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(widget.icon, color: WebColors.whiteText, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(widget.desc,
                            style: TextStyle(
                                color: WebColors.whiteText.withOpacity(0.85),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded,
                      color: WebColors.whiteText.withOpacity(0.8), size: 18),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DesktopLanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String turkishLabel;
  final String englishLabel;
  final String currentLanguageCode;
  final ValueChanged<String> onSelect;

  const _DesktopLanguageTile({
    required this.title,
    required this.subtitle,
    required this.turkishLabel,
    required this.englishLabel,
    required this.currentLanguageCode,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
        label: '$title. $subtitle',
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: AppRadius.asymSm,
            border:
                Border.all(color: WebColors.darkBlueAccent.withOpacity(0.9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WebColors.primaryGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.translate_rounded,
                    color: WebColors.primaryGold, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: WebColors.whiteText,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: WebColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              _DesktopLanguageOption(
                label: turkishLabel,
                isSelected: currentLanguageCode == 'tr',
                onTap: () => onSelect('tr'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DesktopLanguageOption(
                label: englishLabel,
                isSelected: currentLanguageCode == 'en',
                onTap: () => onSelect('en'),
              ),
            ],
          ),
        ),
      );
}

class _DesktopLanguageOption extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopLanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DesktopLanguageOption> createState() => _DesktopLanguageOptionState();
}

class _DesktopLanguageOptionState extends State<_DesktopLanguageOption> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.label,
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
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: widget.isSelected ? WebColors.goldGradient : null,
                color: widget.isSelected
                    ? null
                    : (_hovered
                        ? WebColors.darkBlueAccent.withOpacity(0.8)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: widget.isSelected
                    ? null
                    : Border.all(color: WebColors.darkBlueAccent, width: 1.5),
                boxShadow: widget.isSelected
                    ? AppShadows.level2(WebColors.primaryGold)
                    : null,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? WebColors.veryDarkBlue
                      : WebColors.whiteText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
}

class _SettingsHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsHeroHeader({required this.title, required this.subtitle});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.14),
              shape: BoxShape.circle,
              boxShadow: AppShadows.level2(colors.primary),
            ),
            child: Icon(Icons.theater_comedy_rounded,
                color: colors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAHNE KULİSİ & YÖNETİM MERKEZİ',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    textStyle: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.65),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
