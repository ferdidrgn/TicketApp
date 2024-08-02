import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    colorScheme: ColorScheme.light(
      primary: Colors.red,
      primaryContainer: Colors.red.shade200,
      secondary: Colors.amber,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.red,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
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
    colorScheme: ColorScheme.dark(
      primary: Colors.redAccent,
      primaryContainer: Colors.grey.shade800,
      secondary: Colors.redAccent,
      surface: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.grey,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: _darkTextTheme,
  );

  static final _baseLightTextStyle = const TextStyle(
    fontFamily: 'Roboto',
    color: Colors.black,
  );

  static final _baseDarkTextStyle = const TextStyle(
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
