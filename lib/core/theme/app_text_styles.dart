import 'package:flutter/material.dart';

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
    displayLarge: baseDarkTextStyle.copyWith(
        fontSize: 96.0, fontWeight: FontWeight.w300),
    displayMedium: baseDarkTextStyle.copyWith(
        fontSize: 60.0, fontWeight: FontWeight.w300),
    displaySmall: baseDarkTextStyle.copyWith(
        fontSize: 44.0, fontWeight: FontWeight.w400),
    headlineLarge: baseDarkTextStyle.copyWith(
        fontSize: 30.0, fontWeight: FontWeight.w400),
    headlineMedium: baseDarkTextStyle.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w400),
    headlineSmall: baseDarkTextStyle.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w500),
    titleLarge: baseDarkTextStyle.copyWith(
        fontSize: 18.0, fontWeight: FontWeight.w400),
    titleMedium: baseDarkTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w500),
    titleSmall: baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodyLarge: baseDarkTextStyle.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400),
    bodyMedium: baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400),
    bodySmall: baseDarkTextStyle.copyWith(
        fontSize: 13.0, fontWeight: FontWeight.w400),
    labelLarge: baseDarkTextStyle.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: baseDarkTextStyle.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400),
    labelSmall: baseDarkTextStyle.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w400),
  );
}
