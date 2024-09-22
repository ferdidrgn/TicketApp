import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppDarkColors {
  static const Color primary = Color(0xFF343541);
  static const Color primaryVariant = Color(0xFF3C3E4A);
  static const Color secondary = Color(0xFF444653);
  static const Color secondaryVariant = Color(0xFF565864);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFF000000);
}

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    colorScheme: ColorScheme.light(
      primary: Colors.red,
      primaryContainer: Colors.redAccent,
      secondary: Colors.red.shade200,
      secondaryContainer: Colors.red.shade100,
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white, size: 30),
      backgroundColor: Colors.red,
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.red,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.red,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: _lightTextTheme,
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    colorScheme: const ColorScheme.dark(
      primary: AppDarkColors.secondary,
      primaryContainer: AppDarkColors.primaryVariant,
      secondary: AppDarkColors.primaryVariant,
      secondaryContainer: AppDarkColors.secondaryVariant,
      surface: AppDarkColors.secondary,
      background: AppDarkColors.primaryVariant,
      error: AppDarkColors.error,
      onPrimary: AppDarkColors.onPrimary,
      onSecondary: AppDarkColors.onPrimary,
      onSurface: AppDarkColors.onPrimary,
      onBackground: AppDarkColors.onPrimary,
      onError: AppDarkColors.onError,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white, size: 30),
      backgroundColor: AppDarkColors.primary,
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppDarkColors.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppDarkColors.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.grey,
      selectedItemColor: AppDarkColors.primary,
      unselectedItemColor: Colors.white,
    ),
    textTheme: _darkTextTheme,
  );

  static const _baseLightTextStyle = TextStyle(
    fontFamily: 'Roboto',
    color: Colors.black,
  );

  static const _baseDarkTextStyle = TextStyle(
    fontFamily: 'Roboto',
    color: Colors.white,
  );

  static final _lightTextTheme = TextTheme(
    displayLarge: _baseLightTextStyle.copyWith(
        fontSize: 96.0, fontWeight: FontWeight.w300),
    displayMedium: _baseLightTextStyle.copyWith(
        fontSize: 60.0, fontWeight: FontWeight.w300),
    displaySmall: _baseLightTextStyle.copyWith(
        fontSize: 48.0, fontWeight: FontWeight.w400),
    headlineLarge: _baseLightTextStyle.copyWith(
        fontSize: 34.0, fontWeight: FontWeight.w400),
    headlineMedium: _baseLightTextStyle.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w400),
    headlineSmall: _baseLightTextStyle.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w500),
    titleLarge: _baseLightTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    titleMedium: _baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    titleSmall: _baseLightTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    bodyLarge: _baseLightTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    bodyMedium: _baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodySmall: _baseLightTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelLarge: _baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: _baseLightTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelSmall: _baseLightTextStyle.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w400),
  );

  static final _darkTextTheme = TextTheme(
    displayLarge: _baseDarkTextStyle.copyWith(
        fontSize: 96.0, fontWeight: FontWeight.w300),
    displayMedium: _baseDarkTextStyle.copyWith(
        fontSize: 60.0, fontWeight: FontWeight.w300),
    displaySmall: _baseDarkTextStyle.copyWith(
        fontSize: 48.0, fontWeight: FontWeight.w400),
    headlineLarge: _baseDarkTextStyle.copyWith(
        fontSize: 34.0, fontWeight: FontWeight.w400),
    headlineMedium: _baseDarkTextStyle.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w400),
    headlineSmall: _baseDarkTextStyle.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w500),
    titleLarge: _baseDarkTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    titleMedium: _baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    titleSmall: _baseDarkTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    bodyLarge: _baseDarkTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    bodyMedium: _baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodySmall: _baseDarkTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelLarge: _baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: _baseDarkTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelSmall: _baseDarkTextStyle.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w400),
  );
}

List<Color> gradientColors(BuildContext context, bool isTrue) {
  return isTrue
      ? (Theme.of(context).brightness == Brightness.light
          ? [Colors.red.shade300, Colors.red.shade900]
          : [Colors.pink[500]!, Colors.purple[600]!])
      : [Colors.grey[500]!, Colors.grey[800]!];
}

List<Color> gradientOpacityColors() {
  return [Colors.transparent, Colors.black.withOpacity(0.3)];
}
