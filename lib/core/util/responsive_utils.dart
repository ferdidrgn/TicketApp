import 'package:flutter/material.dart';

/// Responsive tasarım için merkezi utility sınıfı
/// Clean Architecture ve SOLID prensipleriyle tasarlanmış
///
/// Kullanım Örnekleri:
/// ```dart
/// // 1. Mixin olarak kullanım (Widget içinde)
/// class MyWidget extends StatelessWidget with ResponsiveUtils {
///   Widget build(BuildContext context) {
///     return Container(
///       padding: getScreenPadding(context),
///       child: Text(
///         'Başlık',
///         style: TextStyle(fontSize: getTitleFontSize(context)),
///       ),
///     );
///   }
/// }
///
/// // 2. Static metotlarla kullanım (her yerden)
/// Widget build(BuildContext context) {
///   return Container(
///     padding: ResponsiveUtils.paddingAll(context),
///     child: ResponsiveUtils.isMobile(context)
///         ? MobileLayout()
///         : DesktopLayout(),
///   );
/// }
///
/// // 3. Extension ile kullanım (en temiz)
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
mixin ResponsiveUtils {
  // ═══════════════════════════════════════════════════════════
  // BREAKPOINT SABİTLERİ
  // ═══════════════════════════════════════════════════════════

  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1100;

  // ═══════════════════════════════════════════════════════════
  // CİHAZ TİPİ KONTROLLERI (Static - her yerden erişilebilir)
  // ═══════════════════════════════════════════════════════════

  /// Mobil cihaz kontrolü
  static bool isMobile(final BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Tablet kontrolü
  static bool isTablet(final BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Desktop kontrolü
  static bool isDesktop(final BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // ═══════════════════════════════════════════════════════════
  // GENERİK VALUE SELECTOR (Ana Metot)
  // ═══════════════════════════════════════════════════════════

  /// Cihaz tipine göre değer döndüren generic metot
  ///
  /// Örnek:
  /// ```dart
  /// final padding = getValueForDevice(
  ///   context,
  ///   mobile: 16.0,
  ///   tablet: 20.0,  // opsiyonel
  ///   desktop: 24.0,
  /// );
  /// ```
  T getValueForDevice<T>(
    final BuildContext context, {
    required final T mobile,
    final T? tablet,
    required final T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  // ═══════════════════════════════════════════════════════════
  // PADDING & MARGIN (Hazır Yardımcı Metotlar)
  // ═══════════════════════════════════════════════════════════

  /// Ekran kenar boşluğu (tüm sayfa için)
  EdgeInsets getScreenPadding(final BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getValueForDevice(context, mobile: 16.0, desktop: 24.0),
      vertical: getValueForDevice(context, mobile: 12.0, desktop: 20.0),
    );
  }

  /// Tüm yönlere eşit padding
  static EdgeInsets paddingAll(final BuildContext context,
      {final double? mobile, final double? desktop}) {
    final m = mobile ?? 16.0;
    final d = desktop ?? 24.0;
    return EdgeInsets.all(
      isDesktop(context) ? d : m,
    );
  }

  /// Yatay padding
  static EdgeInsets paddingHorizontal(final BuildContext context,
      {final double? mobile, final double? desktop}) {
    final m = mobile ?? 16.0;
    final d = desktop ?? 24.0;
    return EdgeInsets.symmetric(
      horizontal: isDesktop(context) ? d : m,
    );
  }

  /// Dikey padding
  static EdgeInsets paddingVertical(final BuildContext context,
      {final double? mobile, final double? desktop}) {
    final m = mobile ?? 12.0;
    final d = desktop ?? 20.0;
    return EdgeInsets.symmetric(
      vertical: isDesktop(context) ? d : m,
    );
  }

  /// Card içi padding
  EdgeInsets getCardPadding(final BuildContext context) {
    return EdgeInsets.all(
      getValueForDevice(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
    );
  }

  /// Badge padding
  EdgeInsets getBadgePadding(final BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getValueForDevice(context, mobile: 6.0, desktop: 8.0),
      vertical: 4.0,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FONT SIZES (Hazır Yardımcı Metotlar)
  // ═══════════════════════════════════════════════════════════

  /// Başlık font boyutu
  double getTitleFontSize(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 16.0, tablet: 18.0, desktop: 18.0);
  }

  /// Body/İçerik font boyutu
  double getBodyFontSize(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 13.0, tablet: 14.0, desktop: 14.0);
  }

  /// Alt yazı/Caption font boyutu
  double getCaptionFontSize(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 10.0, tablet: 11.0, desktop: 11.0);
  }

  /// Fiyat font boyutu
  double getPriceFontSize(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 14.0, tablet: 16.0, desktop: 16.0);
  }

  /// Generic font boyutu
  double getFontSize(
      final BuildContext context, final double mobile, final double desktop) {
    return getValueForDevice(context, mobile: mobile, desktop: desktop);
  }

  // ═══════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════

  /// Küçük icon boyutu
  double getIconSizeSmall(final BuildContext context) {
    return getValueForDevice(context, mobile: 18.0, desktop: 20.0);
  }

  /// Orta icon boyutu
  double getIconSizeMedium(final BuildContext context) {
    return getValueForDevice(context, mobile: 24.0, desktop: 24.0);
  }

  /// Generic icon boyutu (scale ile)
  double getIconSize(final BuildContext context, {final double scale = 1.0}) {
    return getValueForDevice(
      context,
      mobile: 20.0 * scale,
      desktop: 24.0 * scale,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRID & LAYOUT
  // ═══════════════════════════════════════════════════════════

  /// Grid sütun sayısı
  int getGridCrossAxisCount(final BuildContext context,
      {final int desktopCount = 4}) {
    return getValueForDevice(
      context,
      mobile: 2,
      tablet: 3,
      desktop: desktopCount,
    );
  }

  /// Grid boşlukları
  double getGridSpacing(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 12.0, tablet: 16.0, desktop: 20.0);
  }

  /// Card aspect ratio (yükseklik/genişlik oranı)
  double getCardAspectRatio(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 0.72, tablet: 0.78, desktop: 0.80);
  }

  /// Card görsel yüksekliği
  double getCardImageHeight(final BuildContext context) {
    return getValueForDevice(context,
        mobile: 140.0, tablet: 160.0, desktop: 180.0);
  }

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════

  /// Border radius (scale ile özelleştirilebilir)
  double getBorderRadius(final BuildContext context,
      {final double scale = 1.0}) {
    return getValueForDevice(
      context,
      mobile: 12.0 * scale,
      desktop: 16.0 * scale,
    );
  }

  /// Card margin
  EdgeInsets getCardMargin(final BuildContext context) {
    return EdgeInsets.all(
      getValueForDevice(context, mobile: 4.0, desktop: 6.0),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LAYOUT HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Mobil/Desktop için farklı widget döndür
  static Widget adaptive(
    final BuildContext context, {
    required final Widget mobile,
    final Widget? tablet,
    required final Widget desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  /// Ekran boyutuna göre child sayısı ayarla (Column/Row için)
  static List<Widget> adaptiveChildren(
    final BuildContext context, {
    required final List<Widget> children,
    final int? mobileLimit,
    final int? desktopLimit,
  }) {
    final limit = isDesktop(context)
        ? (desktopLimit ?? children.length)
        : (mobileLimit ?? children.length);

    return children.take(limit).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // YARDIMCI HESAPLAMALAR
  // ═══════════════════════════════════════════════════════════

  /// Ekran genişliği
  static double screenWidth(final BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Ekran yüksekliği
  static double screenHeight(final BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Yüzdelik genişlik hesapla
  static double widthPercent(
          final BuildContext context, final double percent) =>
      screenWidth(context) * (percent / 100);

  /// Yüzdelik yükseklik hesapla
  static double heightPercent(
          final BuildContext context, final double percent) =>
      screenHeight(context) * (percent / 100);
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

  // Ekran boyutları
  double get screenWidth => ResponsiveUtils.screenWidth(this);

  double get screenHeight => ResponsiveUtils.screenHeight(this);

  // Padding
  EdgeInsets get paddingAll => ResponsiveUtils.paddingAll(this);

  EdgeInsets get paddingHorizontal => ResponsiveUtils.paddingHorizontal(this);

  EdgeInsets get paddingVertical => ResponsiveUtils.paddingVertical(this);

  // Font boyutları (kısa isimler)
  double get titleSize => isMobile ? 16.0 : 18.0;

  double get bodySize => isMobile ? 13.0 : 14.0;

  double get captionSize => isMobile ? 10.0 : 11.0;

  double get priceSize => isMobile ? 14.0 : 16.0;

  // Icon boyutları
  double get iconSmall => isMobile ? 18.0 : 20.0;

  double get iconMedium => isMobile ? 24.0 : 24.0;

  double get iconLarge => isMobile ? 32.0 : 40.0;

  // Layout
  int gridColumns([final int desktop = 4]) =>
      isMobile ? 2 : (isTablet ? 3 : desktop);

  double cardAspectRatio() =>
      responsive(mobile: 0.55, tablet: 0.75, desktop: 0.90);

  double get gridSpacing => isMobile ? 12.0 : 20.0;

  // Border
  double borderRadius([final double scale = 1.0]) =>
      (isMobile ? 12.0 : 16.0) * scale;

  // Yüzdelik hesaplamalar
  double wp(final double percent) => screenWidth * (percent / 100);

  double hp(final double percent) => screenHeight * (percent / 100);

  // Generic value selector
  T responsive<T>({
    required final T mobile,
    final T? tablet,
    required final T desktop,
  }) {
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
  Widget build(final BuildContext context) {
    return Container(
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
}

/// Örnek 2: Static metotlarla kullanım
class ExampleWidget2 extends StatelessWidget {
  const ExampleWidget2({super.key});

  @override
  Widget build(final BuildContext context) {
    return ResponsiveUtils.adaptive(
      context,
      mobile: _MobileLayout(),
      desktop: _DesktopLayout(),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.paddingAll(context),
      child: const Column(
        children: [
          Text('Mobil Layout'),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.paddingAll(context),
      child: const Row(
        children: [
          Text('Desktop Layout'),
        ],
      ),
    );
  }
}

/// Örnek 3: Extension ile kullanım (EN KOLAY!)
class ExampleWidget3 extends StatelessWidget {
  const ExampleWidget3({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
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
}
