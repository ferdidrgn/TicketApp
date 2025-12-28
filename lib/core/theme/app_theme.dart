import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

mixin AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    colorScheme: ColorScheme.light(
      primary: AppLightColors.primary,
      primaryContainer: AppLightColors.primaryVariant,
      secondary: AppLightColors.secondary,
      secondaryContainer: AppLightColors.secondaryVariant,
      surface: AppLightColors.surface,
      error: AppLightColors.error,
      onPrimary: AppLightColors.onPrimary,
      onSecondary: AppLightColors.onSecondary,
      onSurface: AppLightColors.onSurface,
      onError: AppLightColors.onError,
      // Material 3 yeni yüzey renkleri
      surfaceContainerHighest: AppLightColors.surface.withOpacity(0.8),
    ),
    appBarTheme: _appBarTheme(AppLightColors.primary, Brightness.light),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: AppLightColors.background,
      selectedItemColor: AppLightColors.primary,
      unselectedItemColor: AppLightColors.textSecondary,
    ),
    textTheme: AppTextStyles.lightTextTheme,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    colorScheme: const ColorScheme.dark(
      primary: AppDarkColors.error,
      primaryContainer: AppDarkColors.primaryVariant,
      secondary: AppDarkColors.primaryVariant,
      secondaryContainer: AppDarkColors.secondaryVariant,
      surface: AppDarkColors.secondary,
      error: AppDarkColors.error,
      onPrimary: AppDarkColors.onPrimary,
      onSecondary: AppDarkColors.onPrimary,
      onSurface: AppDarkColors.onPrimary,
      onError: AppDarkColors.onError,
      surfaceContainerHighest: Colors.white10,
    ),
    appBarTheme: _appBarTheme(AppDarkColors.primary, Brightness.dark),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.grey,
      selectedItemColor: AppDarkColors.primary,
      unselectedItemColor: Colors.white,
    ),
    textTheme: AppTextStyles.darkTextTheme,
  );

  static AppBarTheme _appBarTheme(
          final Color backgroundColor, final Brightness brightness) =>
      AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        // M3'te yukarı kaydırınca renk değişimini yönetir
        iconTheme: IconThemeData(
            color: brightness == Brightness.light ? Colors.black : Colors.white,
            size: 30),
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: brightness == Brightness.light ? Colors.black : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      );
}

List<Color> gradientColors(final BuildContext context, final isTrue) => isTrue
    ? (context.theme.brightness == Brightness.light
        ? [Colors.red.shade300, Colors.red.shade900]
        : [Colors.pink[500]!, Colors.purple[600]!])
    : [Colors.grey[500]!, Colors.grey[800]!];

List<Color> gradientOpacityColors() =>
    [Colors.transparent, Colors.black.withOpacity(0.3)];
