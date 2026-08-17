import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_text_styles.dart';

mixin AppTheme {
  // --- 1. ATMOSFERİK MOD HESAPLAYICI (İstediğin Kod Burada) ---
  static Color createAtmosphericBackground(final Color sourceColor) {
    final hsl = HSLColor.fromColor(sourceColor);
    // Işığı %7'ye, Doygunluğu %40'a çekerek "Renkli Karanlık" elde ediyoruz
    return hsl.withLightness(0.07).withSaturation(0.3).toColor();
  }

  // --- 2. TEMA FABRİKASI ---
  // ===========================================================================
  /// Bu metot, dışarıdan verilen bir [ColorScheme] (renk paketi) alır
  /// ve tüm butonları, inputları o renge göre boyayıp ThemeData döndürür.
  static ThemeData createTheme({
    required final ColorScheme colors,
    final Color? scaffoldBackgroundOverride,
    // Atmosferik mod için override imkanı
  }) {
    // 1. Web mi Mobil mi karar ver ve ham (renksiz) text temasını al
    final TextTheme baseTextTheme =
        kIsWeb ? AppTextStyles.webTextTheme : AppTextStyles.mobileTextTheme;

    // 2. Ham text temasını, gelen renk paketine (colors) göre boya!
    // NOT: fontFamily kasıtlı olarak override edilmiyor — her TextStyle
    // zaten GoogleFonts.plusJakartaSansTextTheme() tarafından doğru
    // fontFamily/font dosyası referansıyla geliyor; burada tekrar
    // string ile ezmek yanlışlıkla eşleşmeyen bir isimle sistem fontuna
    // sessizce geri düşme riski taşır (eskiden 'PlayfairDisplay' ile
    // yaşanan tam olarak buydu).
    final TextTheme coloredTextTheme = baseTextTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
      decorationColor: colors.onSurface,
    );

    // Arka plan rengi: Override varsa onu kullan, yoksa standart surface
    final bgColor = scaffoldBackgroundOverride ?? colors.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      brightness: colors.brightness,
      scaffoldBackgroundColor: bgColor,
      // Arka plan rengi: Override varsa onu kullan, yoksa standart surface, Background yerine surface daha modern

      // Boyanmış text temasını içeri alıyoruz
      textTheme: coloredTextTheme,

      // Bileşen Temaları (Artık 'colors' değişkenini kullanıyorlar)
      appBarTheme: _appBarTheme(
          colors: colors, textTheme: coloredTextTheme, bgColor: bgColor),

      cardTheme: _cardTheme(colors: colors, bgColor: bgColor),
      elevatedButtonTheme: _elevatedButtonTheme(
          colors: colors, textStyle: coloredTextTheme.labelLarge!),
      outlinedButtonTheme: _outlinedButtonTheme(
          colors: colors, textStyle: coloredTextTheme.labelLarge!),
      textButtonTheme: _textButtonTheme(
          colors: colors, textStyle: coloredTextTheme.labelLarge!),
      inputDecorationTheme: _inputDecorationTheme(colors: colors),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(colors: colors),
      navigationBarTheme: _navigationBarTheme(colors: colors),
    );
  }

  // 2. SABİT TEMALAR (Fallback / Gündüz-Gece Seçenekleri İçin)
  // ===========================================================================
  static final ThemeData lightTheme = createTheme(
    colors: const ColorScheme.light(
      primary: AppLightColors.primary,
      onPrimary: AppLightColors.onPrimary,
      primaryContainer: AppLightColors.primaryVariant,
      secondary: AppLightColors.secondary,
      onSecondary: AppLightColors.onSecondary,
      secondaryContainer: AppLightColors.secondaryVariant,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.onSurface,
      onSurfaceVariant: AppLightColors.textSecondary,
      error: AppLightColors.error,
      onError: AppLightColors.onError,
      // Material 3 yeni yüzey renkleri
      surfaceContainerHighest: AppLightColors.surface,
      outline: AppLightColors.border,
      shadow: Colors.black12,
    ),
  );

  // DARK THEME -- Fabrikayı kullanarak Dark Tema üretiyoruz
  // ------------------------------------------------------------
  static final ThemeData darkTheme = createTheme(
    colors: const ColorScheme.dark(
      primary: AppDarkColors.primary,
      onPrimary: AppDarkColors.onPrimary,
      primaryContainer: AppDarkColors.primaryVariant,
      secondary: AppDarkColors.secondary,
      onSecondary: AppDarkColors.onSecondary,
      secondaryContainer: AppDarkColors.secondaryVariant,
      surface: AppDarkColors.surface,
      onSurface: AppDarkColors.onSurface,
      error: AppDarkColors.error,
      onError: AppDarkColors.onError,
      surfaceContainerHighest: AppDarkColors.surface,
      outline: AppDarkColors.border,
      shadow: Colors.white12,
    ),
  );

  // ------------------------------------------------------------
  // COMPONENT THEMES
  // ------------------------------------------------------------

  static AppBarTheme _appBarTheme({
    required final ColorScheme colors,
    required final TextTheme textTheme,
    required final Color bgColor,
  }) =>
      AppBarTheme(
        backgroundColor: bgColor,
        // Atmosferik modda Appbar da renkli olsun
        //backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.onSurface, size: 28),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        systemOverlayStyle: colors.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      );

  // 🎯 BENTO KART: Elevation/gölge yerine düz zemin + mikro kenarlık
  // (Border.all(color: Colors.white.withOpacity(0.08)) diliyle birebir).
  static CardThemeData _cardTheme(
      {required final ColorScheme colors, required final Color bgColor}) {
    final cardColor = colors.brightness == Brightness.dark
        ? BentoColors.card
        : colors.surfaceContainerHighest;
    return CardThemeData(
      color: cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(
          color: colors.brightness == Brightness.dark
              ? BentoColors.microBorder
              : colors.outlineVariant,
        ),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required final ColorScheme colors,
    required final TextStyle textStyle,
  }) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          textStyle: textStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required final ColorScheme colors,
    required final TextStyle textStyle,
  }) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          textStyle: textStyle,
          side: BorderSide(
            color: colors.brightness == Brightness.dark
                ? BentoColors.microBorderStrong
                : colors.outline,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static TextButtonThemeData _textButtonTheme({
    required final ColorScheme colors,
    required final TextStyle textStyle,
  }) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: textStyle,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(
          {required final ColorScheme colors}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colors.brightness == Brightness.dark
            ? BentoColors.card
            : colors.surfaceContainerHighest.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.brightness == Brightness.dark
                ? BentoColors.microBorder
                : colors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.brightness == Brightness.dark
                ? BentoColors.microBorder
                : colors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error),
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
      );

  static BottomNavigationBarThemeData _bottomNavigationBarTheme(
          {required final ColorScheme colors}) =>
      BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      );

  static NavigationBarThemeData _navigationBarTheme(
          {required final ColorScheme colors}) =>
      NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.secondaryContainer,
        labelTextStyle:
            MaterialStateProperty.resolveWith((final states) => TextStyle(
                  color: states.contains(MaterialState.selected)
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                )),
      );
}
