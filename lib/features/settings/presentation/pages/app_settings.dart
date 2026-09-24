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

  // 🎨 Tema Rengi seçicide sunulan hazır vurgu renkleri. `WebColors`/
  // `AppLightColors`/`AppDarkColors` sabitlerine hiç dokunulmaz — bunlar
  // `ColorScheme.fromSeed()`'e girecek tamamen ayrı, kullanıcı tercihi
  // renk seçenekleridir (materialLight/materialDark'ın duvar kağıdından
  // seed üretme tekniğiyle aynı mantık).
  static const List<Color> _accentColorPresets = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.deepOrange,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
  ];

  // 🔥 DÜZELTME: Önceden `request()`'ten SONRA koşulsuz `openAppSettings()`
  // çağrılıyordu — yani izin zaten verilmişse ya da uygulama içi istek
  // az önce normal şekilde onaylanmışsa bile, "Mekansal Rezonans"
  // (konum) veya "Sanat Fısıltıları" (bildirim) satırına her dokunuşta
  // kullanıcı uygulamadan atılıp OS Ayarları'na fırlatılıyordu. Artık
  // sadece GERÇEKTEN kalıcı olarak reddedilmiş (bir daha uygulama içi
  // sorulamayan) izinlerde Ayarlar'a yönlendiriliyor; aksi halde normal
  // uygulama içi izin isteği yeterli.
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
      AppLocalizations.of(context)!
          .settingsShareMessage(AppConstants.shareUrl),
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
        title: Text(AppLocalizations.of(context)!.settingsAccentColorPickerTitle),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: _accentColorPresets.map((final swatch) {
              final isSelected = currentColor?.value == swatch.value;
              return Semantics(
                button: true,
                label:
                    AppLocalizations.of(context)!.settingsAccentColorSemanticLabel,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.onSurface : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: AppShadows.level1(swatch),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.settingsCancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 🖥️ Masaüstü/web: BasePageWrapper'ın mobil zırhı (gradient başlık, FAB,
    // parçacık arkaplanı) yerine kendi sade web kabuğunu kullanır. Tema
    // rengi seçimi bilinçli olarak sadece mobil/app tarafında — web renkleri
    // (`WebColors`) sabit kalmaya devam eder.
    if (context.isDesktop) return _buildDesktopPage(context, ref);

    final theme = context.theme;
    final colors = context.colors;
    final currentThemeStyle = ref.watch(themeProvider);
    final currentAccentColor = ref.watch(customAccentColorProvider);

    final l10n = AppLocalizations.of(context)!;

    return BasePageWrapper(
      // 🔥 DÜZELTME: Kullanıcı bu sayfanın "en üst tasarımı"nı açıkça
      // iğrenç buldu — sorumlusu `BasePageWrapper`'ın title/subtitle
      // verilince çizdiği PAYLAŞILAN, jenerik `TopHeaderWithBackButton`
      // (her redesign edilmemiş sayfada birebir aynı ShaderMask serif
      // başlık) idi. `login_screen.dart`/`profile_page.dart` gibi zaten
      // redesign edilmiş sayfalar bu paylaşılan başlığı hiç kullanmıyor,
      // kendi kimliklerini sayfa içeriğinde kuruyor — ayarlar da aynı
      // yolu izliyor: wrapper'a title/subtitle VERİLMEZ (sadece geri
      // butonu kalır), gerçek başlık aşağıda `_SettingsHeroHeader` olarak
      // inşa edilir.
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
          _SettingsHeroHeader(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsSubtitle,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 🕊️ İLHAM KARTI
          InspirationalQuoteView(
            word: l10n.settingsQuoteText,
            author: l10n.settingsQuoteAuthor,
            imageUrl:
                'https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=800&auto=format&fit=crop',
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

  // "Tema Rengi" satırı — seçili özel rengi (varsa) dairesel bir örnekle
  // gösterir, dokununca renk ızgarası diyaloğunu açar.
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
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
            boxShadow: AppShadows.level1(swatchColor),
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
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

  // "Uygulama Dili" satırı — `localeControllerProvider` (gerçek, kalıcı
  // şifreli depolamaya yazan altyapı, bkz. `locale_provider.dart`) ile TR/EN
  // arasında gerçekten geçiş yapan iki seçenekli bir seçici. Diğer atölye
  // satırlarıyla aynı tasarım dili (kart + dikey vurgu barı), ama chevron
  // yerine seçili dili vurgulayan iki pill buton taşıyor.
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
          border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          boxShadow: AppShadows.level1(colors.primary),
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
                child: Icon(Icons.translate_rounded,
                    color: colors.primary, size: 24),
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
                    Text(l10n.settingsLanguageSubtitle,
                        style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 11,
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
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.section),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 DÜZELTME: Önceden burası düz, ikon/rozet/kicker'sız
                      // iki satır metindi — sayfanın geri kalanı (bölüm
                      // etiketleri, gold gradyanlı aksiyon kartları) görsel
                      // kimlik taşırken bu başlık "unutulmuş" duruyordu.
                      // Artık `_buildDesktopSectionLabel`'daki rozet dili
                      // büyütülmüş hâliyle: gold gradyanlı ikon rozeti +
                      // eyebrow + Playfair Display başlık.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: WebColors.goldButtonGradient,
                              borderRadius: AppRadius.asymLg,
                              boxShadow:
                                  AppShadows.level3(WebColors.primaryGold),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                color: WebColors.darkBlueBackground, size: 26),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SAHNE ARKASI',
                                  style: TextStyle(
                                    color: WebColors.primaryGoldLight,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
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
                                      fontSize: 34,
                                      letterSpacing: -0.5,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.settingsSubtitle,
                                  style: const TextStyle(
                                    color: WebColors.textSecondary,
                                    fontSize: 14,
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
                        onTap: () =>
                            _handlePermission(Permission.notification),
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
  }

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

/// Masaüstü "Uygulama Dili" satırı — `_DesktopHoverTile` ile aynı kart
/// dilini taşır ama chevron yerine seçili dili vurgulayan iki pill buton
/// gösterir; dokununca `localeControllerProvider` üzerinden gerçekten dil
/// değiştirir (`onSelect` callback'i `app_settings.dart`'taki
/// `_buildDesktopPage`'den geliyor).
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
            border: Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.translate_rounded,
                  color: WebColors.primaryGold, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: WebColors.whiteText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle,
                        style: const TextStyle(
                            color: WebColors.textSecondary, fontSize: 12)),
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
  State<_DesktopLanguageOption> createState() =>
      _DesktopLanguageOptionState();
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
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: widget.isSelected ? WebColors.goldGradient : null,
                color: widget.isSelected
                    ? null
                    : (_hovered
                        ? WebColors.darkBlueAccent.withOpacity(0.6)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: widget.isSelected
                    ? null
                    : Border.all(color: WebColors.darkBlueAccent, width: 1),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? WebColors.veryDarkBlue
                      : WebColors.whiteText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
}

/// 🔥 DÜZELTME: Mobil sayfanın en tepesi önceden `BasePageWrapper`'ın
/// PAYLAŞILAN, jenerik `TopHeaderWithBackButton`'ıydı — uygulamadaki
/// redesign edilmemiş HER sayfada birebir aynı görünen bir ShaderMask
/// serif başlık. Kullanıcı bunu özellikle "settings ... en üst tasarımı
/// aşırı iğrenç" diye işaretledi. `login_screen.dart`/`profile_page.dart`
/// gibi zaten redesign edilmiş sayfalar bu paylaşılan başlığı hiç
/// kullanmıyor, kendi kimliklerini kuruyor — ayarlar sayfası da aynı yolu
/// izliyor: spot ışığı gölgeli ikon rozeti + küçük harfli "SAHNE ARKASI"
/// kicker'ı (bu sayfanın izin/görünüm/dil kontrollerini bir tiyatronun
/// "sahne arkası" kontrol odası gibi çerçeveleyen, uygulamanın kendi
/// metaforuna sadık bir isimlendirme) + büyük Playfair Display başlık +
/// ince vurgu çizgisi + alt başlık. Aynı tipografi hiyerarşisi
/// `AuthHeadlineBlock`/profil hero kimliğinde de kullanılıyor.
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.14),
              shape: BoxShape.circle,
              boxShadow: AppShadows.level2(colors.primary),
            ),
            child: Icon(Icons.tune_rounded, color: colors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAHNE ARKASI',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
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
                      fontSize: 26,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
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
                    color: colors.onSurface.withOpacity(0.6),
                    fontSize: 13,
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
