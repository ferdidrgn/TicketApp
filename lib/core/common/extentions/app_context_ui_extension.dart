import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../util/responsive_utils.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension ThemeContextExtension on BuildContext {
  // --- Temel Tema Erişimleri ---
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colors => theme.colorScheme;

  bool get isDarkMode => theme.brightness == Brightness.dark;

  // --- Sık Kullanılan Renkler (Kısayollar) ---
  Color get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;

  Color get primaryColor => theme.primaryColor;

  Color get primaryColorLight => theme.primaryColorLight;

  Color get primaryColorDark => theme.primaryColorDark;

  Color get secondaryHeaderColor => theme.secondaryHeaderColor;

  Color get cardColor => theme.cardColor;

  Color get canvasColor => theme.canvasColor;

  Color get shadowColor => theme.shadowColor;

  Color get dividerColor => theme.dividerColor;

  Color get splashColor => theme.splashColor;

  Color get focusColor => theme.focusColor;

  Color get hintColor => theme.hintColor;

  Color get highlightColor => theme.highlightColor;

  BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      theme.bottomNavigationBarTheme;

  // --- Özel Gradient Mantığın ---
  /// [isActive]: Eğer true ise temanın aktif renklerini (Kırmızı veya Mor),
  /// false ise pasif gri renkleri döndürür.
  List<Color> appGradient({final bool isActive = true}) {
    if (!isActive) return [Colors.grey[500]!, Colors.grey[800]!];

    return isDarkMode
        ? [Colors.pink[500]!, Colors.purple[600]!] // Dark Mode Gradient
        : [Colors.red.shade300, Colors.red.shade900]; // Light Mode Gradient
  }

  // --- Opacity / Overlay Gradient ---
  List<Color> get overlayGradient => [
        Colors.transparent,
        Colors.black.withOpacity(0.3),
      ];
}

// ═══════════════════════════════════════════════════════════
// EXTENSION (En Temiz Kullanım İçin)
// ═══════════════════════════════════════════════════════════

/// BuildContext extension - En kolay kullanım şekli
///
/// Kullanım:
/// ```dart
/// Widget build(BuildContext context) {
///   return Container(
///     padding: context.paddingAll,
///     child: Text(
///       'Başlık',
///       style: TextStyle(fontSize: context.titleSize),
///     ),
///   );
/// }
/// ```
extension ResponsiveExtension on BuildContext {
  // Cihaz tipleri
  bool get isMobile => ResponsiveUtils.isMobile(this);

  bool get isTablet => ResponsiveUtils.isTablet(this);

  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);

  // Ekran boyutları
  double get screenWidth => ResponsiveUtils.screenWidth(this);

  double get screenHeight => ResponsiveUtils.screenHeight(this);

  // Padding
  EdgeInsets get paddingAll => ResponsiveUtils.paddingAll(this);

  EdgeInsets get paddingHorizontal => ResponsiveUtils.paddingHorizontal(this);

  EdgeInsets get paddingVertical => ResponsiveUtils.paddingVertical(this);

  // Padding (Web spacing)
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: responsive(
            mobile: 16.0, tablet: 32.0, desktop: 48.0, largeDesktop: 64.0),
        vertical: responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0),
      );

  EdgeInsets get sectionPadding => EdgeInsets.symmetric(
        horizontal: responsive(mobile: 16.0, tablet: 24.0, desktop: 40.0),
        vertical: responsive(mobile: 24.0, tablet: 32.0, desktop: 48.0),
      );

  EdgeInsets get cardPadding =>
      EdgeInsets.all(responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0));

  // Font sizes (Web typography)
  double get heroSize =>
      responsive(mobile: 32.0, tablet: 48.0, desktop: 64.0, largeDesktop: 72.0);

  double get h1Size => responsive(mobile: 28.0, tablet: 36.0, desktop: 48.0);

  double get h2Size => responsive(mobile: 24.0, tablet: 32.0, desktop: 40.0);

  double get h3Size => responsive(mobile: 20.0, tablet: 24.0, desktop: 32.0);

  double get h4Size => responsive(mobile: 18.0, tablet: 20.0, desktop: 24.0);

  double get titleSize => isMobile ? 24.0 : 32.0;

  double get subtitleSize => isMobile ? 16.0 : 20.0;

  double get bodySize => responsive(mobile: 14.0, tablet: 15.0, desktop: 16.0);

  double get captionSize =>
      responsive(mobile: 12.0, tablet: 13.0, desktop: 14.0);

  double get priceSize => isMobile ? 14.0 : 16.0;

  // Icon sizes
  double get iconSmall => responsive(mobile: 20.0, desktop: 24.0);

  double get iconMedium => responsive(mobile: 28.0, desktop: 32.0);

  double get iconLarge => responsive(mobile: 40.0, desktop: 48.0);

  // Spacing
  double get spacing =>
      responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0, largeDesktop: 24.0);

  double get spacingLarge =>
      responsive(mobile: 24.0, tablet: 32.0, desktop: 48.0);

  // Border radius
  double borderRadius([final double scale = 1.0]) =>
      responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0) * scale;

  // Layout - Grid
  int gridColumns([final int desktop = 4]) =>
      isMobile ? 2 : (isTablet ? 3 : desktop);

  int gridColumnsManuel([final int? max]) =>
      ResponsiveUtils.gridColumns(this, maxColumns: max);

  double get gridSpacing =>
      responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0, largeDesktop: 24.0);

  // Card aspect ratio (web optimized)
  double cardAspectRatio() =>
      responsive(mobile: 0.65, tablet: 0.75, desktop: 0.85, largeDesktop: 0.90);

  // Max width wrapper
  Widget maxWidth({required final Widget child, final double? width}) =>
      ResponsiveUtils.maxWidthContainer(
          maxWidth: width, padding: pagePadding, child: child);

  // Yüzdelik hesaplamalar
  double wp(final double percent) => screenWidth * (percent / 100);

  double hp(final double percent) => screenHeight * (percent / 100);

  // Generic value selector
  // Responsive value selector
  T responsive<T>({
    required final T mobile,
    final T? tablet,
    required final T desktop,
    final T? largeDesktop,
  }) {
    if (isLargeDesktop) return largeDesktop ?? desktop;
    if (isDesktop) return desktop;
    if (isTablet) return tablet ?? desktop;
    return mobile;
  }
}

// ═══════════════════════════════════════════════════════════
// KULLANIM ÖRNEKLERİ
// ═══════════════════════════════════════════════════════════

/// Örnek 1: Mixin ile kullanım
class ExampleWidget1 extends StatelessWidget with ResponsiveUtils {
  const ExampleWidget1({super.key});

  @override
  Widget build(final BuildContext context) => Container(
        padding: getScreenPadding(context),
        child: Column(
          children: [
            Text(
              'Başlık',
              style: TextStyle(
                fontSize: getTitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getGridCrossAxisCount(context),
                crossAxisSpacing: getGridSpacing(context),
                mainAxisSpacing: getGridSpacing(context),
              ),
              itemCount: 10,
              itemBuilder: (final context, final index) => Container(),
            ),
          ],
        ),
      );
}

/// Örnek 2: Static metotlarla kullanım
class ExampleWidget2 extends StatelessWidget {
  const ExampleWidget2({super.key});

  @override
  Widget build(final BuildContext context) => ResponsiveUtils.adaptive(context,
      mobile: _MobileLayout(), desktop: _DesktopLayout());
}

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(final BuildContext context) => Padding(
        padding: ResponsiveUtils.paddingAll(context),
        child: const Column(
          children: [
            Text('Mobil Layout'),
          ],
        ),
      );
}

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(final BuildContext context) => Padding(
        padding: ResponsiveUtils.paddingAll(context),
        child: const Row(
          children: [
            Text('Desktop Layout'),
          ],
        ),
      );
}

/// Örnek 3: Extension ile kullanım (EN KOLAY!)
class ExampleWidget3 extends StatelessWidget {
  const ExampleWidget3({super.key});

  @override
  Widget build(final BuildContext context) => Container(
        padding: context.paddingAll,
        margin: EdgeInsets.all(context.borderRadius()),
        child: Column(
          children: [
            Text(
              'Modern Başlık',
              style: TextStyle(
                fontSize: context.titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Responsive widget seçimi
            if (context.isMobile)
              const Text('Mobil görünüm')
            else
              const Text('Desktop görünüm'),
            const SizedBox(height: 16),
            // Generic responsive değer
            Container(
              height: context.responsive(
                mobile: 100.0,
                tablet: 150.0,
                desktop: 200.0,
              ),
            ),
          ],
        ),
      );
}
