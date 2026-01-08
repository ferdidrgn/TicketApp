import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_text_styles.dart';

mixin AppTheme {
  // 1. TEMA FABRİKASI (En Önemli Kısım)
  // ===========================================================================
  /// Bu metot, dışarıdan verilen bir [ColorScheme] (renk paketi) alır
  /// ve tüm butonları, inputları o renge göre boyayıp ThemeData döndürür.
  static ThemeData createTheme(final ColorScheme colors) {
    // 1. Web mi Mobil mi karar ver ve ham (renksiz) text temasını al
    final TextTheme baseTextTheme =
        kIsWeb ? AppTextStyles.webTextTheme : AppTextStyles.mobileTextTheme;

    // 2. Ham text temasını, gelen renk paketine (colors) göre boya!
    // Bu sayede "Monet" rengi neyse, yazılar da o tonda olur.
    final TextTheme coloredTextTheme = baseTextTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
      decorationColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      brightness: colors.brightness,
      scaffoldBackgroundColor: colors.surface,
      // Background yerine surface daha modern

      // Boyanmış text temasını içeri alıyoruz
      textTheme: coloredTextTheme,

      // Bileşen Temaları (Artık 'colors' değişkenini kullanıyorlar)
      appBarTheme: _appBarTheme(colors: colors, textTheme: coloredTextTheme),
      cardTheme: _cardTheme(colors: colors),
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
    const ColorScheme.light(
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
    const ColorScheme.dark(
      primary: AppDarkColors.primary,
      primaryContainer: AppDarkColors.primaryVariant,
      secondary: AppDarkColors.secondary,
      secondaryContainer: AppDarkColors.secondaryVariant,
      surface: AppDarkColors.surface,
      error: AppDarkColors.error,
      onPrimary: AppDarkColors.onPrimary,
      onSecondary: AppDarkColors.onSecondary,
      onSurface: AppDarkColors.onSurface,
      onError: AppDarkColors.onError,
    ),
  );

  // ------------------------------------------------------------
  // COMPONENT THEMES
  // ------------------------------------------------------------

  static AppBarTheme _appBarTheme({
    required final ColorScheme colors,
    required final TextTheme textTheme,
  }) =>
      AppBarTheme(
        backgroundColor: Colors.transparent,
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

  static CardThemeData _cardTheme({required final ColorScheme colors}) =>
      CardThemeData(
        // M3'te surfaceContainerHighest önerilir, yoksa surface kullanır
        color: colors.surfaceContainerHighest,
        elevation: 2,
        shadowColor: colors.shadow.withOpacity(0.35),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      );

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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required final ColorScheme colors,
    required final TextStyle textStyle,
  }) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: textStyle,
          side: BorderSide(color: colors.primary), // Outline rengi primary
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(
          {required final ColorScheme colors}) =>
      InputDecorationTheme(
        filled: true,
        // Hafif opaklık vererek arka plandan ayırıyoruz
        fillColor: colors.surfaceContainerHighest.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
