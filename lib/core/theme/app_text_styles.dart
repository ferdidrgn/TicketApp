import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'PlayfairDisplay';

  // MOBİL TİPOGRAFİ (Material 3 Standartları)
  // ---------------------------------------------------------------------------
  static const TextTheme mobileTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 57.0, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 45.0, fontWeight: FontWeight.w400, height: 1.16),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 36.0, fontWeight: FontWeight.w400, height: 1.22),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32.0, fontWeight: FontWeight.w400, height: 1.25),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 28.0, fontWeight: FontWeight.w400, height: 1.29),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 24.0, fontWeight: FontWeight.w400, height: 1.33),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 22.0, fontWeight: FontWeight.w500, height: 1.27),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.5),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11.0, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45),
  );

  // WEB TİPOGRAFİ (Daha Büyük Ekranlar İçin Optimize Edilmiş)
  // ---------------------------------------------------------------------------
  static const TextTheme webTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 64.0, fontWeight: FontWeight.w300, letterSpacing: -0.25, height: 1.12),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 52.0, fontWeight: FontWeight.w300, height: 1.16),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 44.0, fontWeight: FontWeight.w400, height: 1.22),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 40.0, fontWeight: FontWeight.w400, height: 1.25),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 34.0, fontWeight: FontWeight.w400, height: 1.29),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 28.0, fontWeight: FontWeight.w400, height: 1.33),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 24.0, fontWeight: FontWeight.w500, height: 1.27),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 18.0, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.5),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 18.0, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5), // Okuma kolaylığı için büyütüldü
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45),
  );
}
