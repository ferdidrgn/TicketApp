import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

mixin AppTheme {
  static final lightTheme = ThemeData(
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
    ),
    appBarTheme: _appBarTheme(AppLightColors.primary),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppLightColors.background,
      selectedItemColor: AppLightColors.primary,
      unselectedItemColor: AppLightColors.textSecondary,
    ),
    textTheme: AppTextStyles.lightTextTheme,
  );

  static final darkTheme = ThemeData(
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
    ),
    appBarTheme: _appBarTheme(AppDarkColors.primary),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.grey,
      selectedItemColor: AppDarkColors.primary,
      unselectedItemColor: Colors.white,
    ),
    textTheme: AppTextStyles.darkTextTheme,
  );

  static AppBarTheme _appBarTheme(final Color backgroundColor) => AppBarTheme(
        centerTitle: true,
        iconTheme:
            const IconThemeData(color: AppDarkColors.onPrimary, size: 30),
        backgroundColor: backgroundColor,
        titleTextStyle: const TextStyle(
            color: AppDarkColors.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      );
}

List<Color> gradientColors(final BuildContext context, final isTrue) => isTrue
    ? (Theme.of(context).brightness == Brightness.light
        ? [Colors.red.shade300, Colors.red.shade900]
        : [Colors.pink[500]!, Colors.purple[600]!])
    : [Colors.grey[500]!, Colors.grey[800]!];

List<Color> gradientOpacityColors() =>
    [Colors.transparent, Colors.black.withOpacity(0.3)];
