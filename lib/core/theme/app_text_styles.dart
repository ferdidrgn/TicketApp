import 'package:flutter/material.dart';

/// WEB UYGULAMASI TEXT STYLES
class WebTextStyles {
  static const String fontFamily = 'PlayfairDisplay';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57.0,
    fontWeight: FontWeight.w300,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    height: 1.22,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32.0,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}

mixin AppTextStyles {
  static const String fontFamily = 'PlayfairDisplay';

  static const baseLightTextStyle =
      TextStyle(fontFamily: fontFamily, color: Colors.black);

  static const baseDarkTextStyle =
      TextStyle(fontFamily: fontFamily, color: Colors.white);

  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: baseLightTextStyle.copyWith(
        fontSize: 96.0, fontWeight: FontWeight.w300),
    displayMedium: baseLightTextStyle.copyWith(
        fontSize: 60.0, fontWeight: FontWeight.w300),
    displaySmall: baseLightTextStyle.copyWith(
        fontSize: 44.0, fontWeight: FontWeight.w400),
    headlineLarge: baseLightTextStyle.copyWith(
        fontSize: 30.0, fontWeight: FontWeight.w400),
    headlineMedium: baseLightTextStyle.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w400),
    headlineSmall: baseLightTextStyle.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w500),
    titleLarge: baseLightTextStyle.copyWith(
        fontSize: 18.0, fontWeight: FontWeight.w400),
    titleMedium: baseLightTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w500),
    titleSmall: baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodyLarge: baseLightTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    bodyMedium: baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodySmall: baseLightTextStyle.copyWith(
        fontSize: 13.0, fontWeight: FontWeight.w400),
    labelLarge: baseLightTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: baseLightTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelSmall: baseLightTextStyle.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w400),
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge:
        baseDarkTextStyle.copyWith(fontSize: 96.0, fontWeight: FontWeight.w300),
    displayMedium:
        baseDarkTextStyle.copyWith(fontSize: 60.0, fontWeight: FontWeight.w300),
    displaySmall:
        baseDarkTextStyle.copyWith(fontSize: 44.0, fontWeight: FontWeight.w400),
    headlineLarge:
        baseDarkTextStyle.copyWith(fontSize: 30.0, fontWeight: FontWeight.w400),
    headlineMedium:
        baseDarkTextStyle.copyWith(fontSize: 24.0, fontWeight: FontWeight.w400),
    headlineSmall:
        baseDarkTextStyle.copyWith(fontSize: 20.0, fontWeight: FontWeight.w500),
    titleLarge:
        baseDarkTextStyle.copyWith(fontSize: 18.0, fontWeight: FontWeight.w400),
    titleMedium:
        baseDarkTextStyle.copyWith(fontSize: 16.0, fontWeight: FontWeight.w500),
    titleSmall:
        baseDarkTextStyle.copyWith(fontSize: 14.0, fontWeight: FontWeight.w400),
    bodyLarge:
        baseDarkTextStyle.copyWith(fontSize: 16.0, fontWeight: FontWeight.w400),
    bodyMedium:
        baseDarkTextStyle.copyWith(fontSize: 14.0, fontWeight: FontWeight.w400),
    bodySmall:
        baseDarkTextStyle.copyWith(fontSize: 13.0, fontWeight: FontWeight.w400),
    labelLarge:
        baseDarkTextStyle.copyWith(fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium:
        baseDarkTextStyle.copyWith(fontSize: 12.0, fontWeight: FontWeight.w400),
    labelSmall:
        baseDarkTextStyle.copyWith(fontSize: 11.0, fontWeight: FontWeight.w400),
  );
}
