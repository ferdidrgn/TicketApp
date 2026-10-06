import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticketapp/core/services/deeplink/deeplink_service.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/app_version_provider.dart';
import '../widgets/preference_widgets.dart';
import '../../../../shared/widgets/admin_test_entry.dart';

/// AYARLAR — sade bir "tercihler" sayfası. Sahibinin en sevdiği özellik
/// (5 tema + özel vurgu rengi) en üstte ve artık her seçenek o temanın
/// gerçek renkleriyle önizleniyor; renk paleti diyalogda saklı değil,
/// sayfada tek dokunuşla seçiliyor.
///
/// - Mobil (<768): tek sütun, BasePageWrapper (geri butonu, SafeArea).
/// - Tablet (768–1023): aynı akış, ~720px okuma sütununda, tema 3 sütun.
/// - Masaüstü (≥1024): kendi Scaffold'u; solda geniş "Görünüm", sağda dar
///   sütunda dil / izinler / paylaş. Altta versiyon + Footer.
///
/// Versiyon metnine UZUN BASMA gizli admin girişidir — davranış aynen
/// korunuyor (bkz. [_handleVersionFooterLongPress]).
class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  Future<void> _handlePermission(
    final BuildContext context,
    final Permission permission,
  ) async {
    HapticFeedback.lightImpact();
    final status = await permission.status;
    if (status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              prefText(context, 'Bu izin zaten açık.', 'This permission is already on.'),
            ),
          ),
        );
      }
      return;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    final result = await permission.request();
    if (!context.mounted) return;
    final String message = result.isGranted
        ? prefText(context, 'İzin verildi.', 'Permission granted.')
        : prefText(
            context,
            'İzin verilmedi. Ayarlardan açabilirsin.',
            'Permission denied. You can turn it on in Settings.',
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  // 🕵️ GİZLİ ADMİN GİRİŞİ: versiyon metnine uzun basma. Güvenlik sınırı
  // DEĞİL, sadece bir "keşif kolaylığı" — gerçek sınır Firestore `isAdmin()`
  // kuralları. Release derlemesinde sadece admin/küratör hesabı girer,
  // diğerleri için hiçbir iz bırakmaz. Geliştirme derlemesinde (`flutter
  // run`) giriş/rol ayarlamadan test edebilmek için herkes girer;
  // `AdminGuard(allowDebugBypass: true)` üstte "TEST MODU" şeridi gösterir.
  void _handleVersionFooterLongPress(
      final BuildContext context, final WidgetRef ref) {
    if (!ref.read(isUserPrivilegedProvider) && !AdminTestAccess.enabled) return;
    HapticFeedback.mediumImpact();
    context.push('/admin');
  }

  void _shareApp(final BuildContext context) => Share.share(
      AppLocalizations.of(context)!.settingsShareMessage(AppConstants.shareUrl),
      subject: AppLocalizations.of(context)!.settingsShareSubject);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (context.isDesktop) return _buildDesktopPage(context, ref);
    if (context.isTablet) return _buildTabletPage(context, ref);
    return _buildMobilePage(context, ref);
  }

  BasePageLayoutConfig _layoutConfig(final BuildContext context) =>
      BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      );

  /// Telefon: tek sütun; alt güvenli alan + başparmak bölgesi boşluğu.
  Widget _buildMobilePage(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: _layoutConfig(context),
      child: SafeArea(
        top: false,
        child: Center(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              context.pagePadding.left,
              AppSpacing.sm,
              context.pagePadding.right,
              AppSpacing.xxl + bottomInset,
            ),
            children: [
              PreferencePageHeading(
                title: l10n.settingsTitle,
                lede: prefText(
                    context,
                    'Görünüm, dil ve izin tercihlerin.',
                    'Your appearance, language and permission preferences.'),
              ),
              const SizedBox(height: AppSpacing.huge),
              ..._appearance(context),
              const SizedBox(height: AppSpacing.huge),
              ..._language(context),
              const SizedBox(height: AppSpacing.huge),
              ..._permissions(context),
              const SizedBox(height: AppSpacing.huge),
              ..._share(context),
              const SizedBox(height: AppSpacing.huge),
              _versionFooter(context, ref),
              if (kIsWeb) ...[
                const SizedBox(height: AppSpacing.xxl),
                const Footer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tablet: görünüm tam genişlik; dil/izinler ile paylaş yan yana.
  Widget _buildTabletPage(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: _layoutConfig(context),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: context.pagePadding,
              children: [
                PreferencePageHeading(
                  title: l10n.settingsTitle,
                  lede: prefText(
                      context,
                      'Görünüm, dil ve izin tercihlerin.',
                      'Your appearance, language and permission preferences.'),
                ),
                const SizedBox(height: AppSpacing.section),
                ..._appearance(context),
                const SizedBox(height: AppSpacing.section),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._language(context),
                          const SizedBox(height: AppSpacing.huge),
                          ..._permissions(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxxl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _share(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                _versionFooter(context, ref),
                if (kIsWeb) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const Footer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Bölümler (mobil, tablet ve masaüstü aynı parçaları farklı dizer)
  // ─────────────────────────────────────────────────────────────────────

  List<Widget> _appearance(final BuildContext context) => [
        PreferenceSectionTitle(
          prefText(context, 'Görünüm', 'Appearance'),
          caption: prefText(
              context,
              'Uygulamanın renklerini seç. Değişiklik hemen uygulanır.',
              'Choose the app colours. Changes apply instantly.'),
        ),
        const ThemeStylePicker(),
        const SizedBox(height: AppSpacing.xxl),
        const AccentColorPalette(),
      ];

  List<Widget> _language(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PreferenceSectionTitle(
        prefText(context, 'Dil', 'Language'),
        caption: l10n.settingsLanguageSubtitle,
      ),
      Semantics(
        label: l10n.settingsLanguageTitle,
        container: true,
        child: const LanguageSwitch(),
      ),
    ];
  }

  List<Widget> _permissions(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PreferenceSectionTitle(prefText(context, 'İzinler', 'Permissions')),
      PreferenceGroup(
        children: [
          PreferenceRow(
            icon: Icons.location_on_outlined,
            title: l10n.settingsLocationPermissionTitle,
            subtitle: l10n.settingsLocationPermissionSubtitle,
            onTap: () => _handlePermission(context, Permission.location),
          ),
          PreferenceRow(
            icon: Icons.notifications_none_rounded,
            title: l10n.settingsNotificationsPermissionTitle,
            subtitle: l10n.settingsNotificationsPermissionSubtitle,
            onTap: () => _handlePermission(context, Permission.notification),
          ),
        ],
      ),
    ];
  }

  List<Widget> _share(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PreferenceSectionTitle(
          prefText(context, 'TiyatRol\'ü paylaş', 'Share TiyatRol')),
      PreferenceGroup(
        children: [
          PreferenceRow(
            icon: Icons.storefront_outlined,
            title: l10n.settingsRecommendAppTitle,
            subtitle: l10n.settingsRecommendAppDesc,
            onTap: () => TiyatrolDeeplinkService.shareApp(),
          ),
          PreferenceRow(
            icon: Icons.ios_share_rounded,
            title: l10n.settingsShareWithFriendsTitle,
            subtitle: l10n.settingsShareWithFriendsDesc,
            onTap: () => _shareApp(context),
          ),
        ],
      ),
    ];
  }

  /// Dinamik versiyon (`appVersionLabelProvider`) + uzun basınca /admin.
  Widget _versionFooter(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final versionLabel = ref.watch(appVersionLabelProvider).value;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _handleVersionFooterLongPress(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Text(
            l10n.settingsVersionFooter(versionLabel ?? '…'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü / web
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDesktopPage(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ColorScheme cs = context.colors;

    // Rota kabuğun (shell) dışında → Material atası için kendi Scaffold'u.
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl,
                      AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.section),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PreferencePageHeading(
                        title: l10n.settingsTitle,
                        lede: prefText(
                            context,
                            'Görünüm, dil ve izin tercihlerin.',
                            'Your appearance, language and permission preferences.'),
                        onBack: () => NavigationHandler.smartGoBack(context),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _appearance(context),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.section),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._language(context),
                                const SizedBox(height: AppSpacing.huge),
                                ..._permissions(context),
                                const SizedBox(height: AppSpacing.huge),
                                ..._share(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.section),
                      _versionFooter(context, ref),
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
