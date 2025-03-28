import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_styles.dart';

class AppDarkColors {
  static const Color primary = Color(0xFF343541);
  static const Color primaryVariant = Color(0xFF3C3E4A);
  static const Color secondary = Color(0xFF444653);
  static const Color secondaryVariant = Color(0xFF565864);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFF000000);
}

mixin AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    colorScheme: ColorScheme.light(
      primary: Colors.red,
      primaryContainer: Colors.redAccent,
      secondary: Colors.red.shade200,
      secondaryContainer: Colors.red.shade100,
      surface: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onError: Colors.black,
    ),
    appBarTheme: _appBarTheme(Colors.red),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
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
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        backgroundColor: backgroundColor,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
