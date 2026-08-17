import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tasarım Sistemi 2.0 tipografisi: Plus Jakarta Sans.
/// Önceki sürüm `fontFamily: 'PlayfairDisplay'` string'ini pubspec'te
/// hiçbir font asset'i tanımlamadan kullanıyordu — yani hiçbir zaman
/// gerçekten Playfair Display render edilmiyordu, sessizce sistem
/// fontuna düşüyordu. `google_fonts` paketi zaten bir bağımlılık olduğu
/// için burada onun `TextTheme` üretici API'si kullanılıyor; bu, fontu
/// gerçekten indirip önbelleğe alan tek doğru yol.
abstract final class AppTextStyles {
  static const String fontFamily = 'PlusJakartaSans';

  static final TextTheme _base = GoogleFonts.plusJakartaSansTextTheme();

  // MOBİL TİPOGRAFİ
  // ---------------------------------------------------------------------------
  static final TextTheme mobileTextTheme = _base.copyWith(
    displayLarge: _base.displayLarge?.copyWith(
        fontSize: 48.0, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1),
    displayMedium: _base.displayMedium?.copyWith(
        fontSize: 38.0, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.14),
    displaySmall: _base.displaySmall?.copyWith(
        fontSize: 32.0, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
    headlineLarge: _base.headlineLarge?.copyWith(
        fontSize: 28.0, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2),
    headlineMedium: _base.headlineMedium?.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25),
    headlineSmall: _base.headlineSmall?.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3),
    titleLarge: _base.titleLarge?.copyWith(
        fontSize: 18.0, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: _base.titleMedium?.copyWith(
        fontSize: 15.0, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
    titleSmall: _base.titleSmall?.copyWith(
        fontSize: 13.0, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
    bodyLarge: _base.bodyLarge?.copyWith(
        fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.5),
    bodyMedium: _base.bodyMedium?.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.45),
    bodySmall: _base.bodySmall?.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.4),
    labelLarge: _base.labelLarge?.copyWith(
        fontSize: 14.0, fontWeight: FontWeight.w700, letterSpacing: 0.2, height: 1.3),
    labelMedium: _base.labelMedium?.copyWith(
        fontSize: 12.0, fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.3),
    labelSmall: _base.labelSmall?.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.3),
  );

  // WEB TİPOGRAFİ (Daha Büyük Ekranlar İçin Optimize Edilmiş)
  // ---------------------------------------------------------------------------
  static final TextTheme webTextTheme = _base.copyWith(
    displayLarge: _base.displayLarge?.copyWith(
        fontSize: 72.0, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.05),
    displayMedium: _base.displayMedium?.copyWith(
        fontSize: 56.0, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1),
    displaySmall: _base.displaySmall?.copyWith(
        fontSize: 44.0, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
    headlineLarge: _base.headlineLarge?.copyWith(
        fontSize: 36.0, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
    headlineMedium: _base.headlineMedium?.copyWith(
        fontSize: 30.0, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25),
    headlineSmall: _base.headlineSmall?.copyWith(
        fontSize: 24.0, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3),
    titleLarge: _base.titleLarge?.copyWith(
        fontSize: 20.0, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: _base.titleMedium?.copyWith(
        fontSize: 17.0, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
    titleSmall: _base.titleSmall?.copyWith(
        fontSize: 15.0, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
    bodyLarge: _base.bodyLarge?.copyWith(
        fontSize: 17.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.55),
    bodyMedium: _base.bodyMedium?.copyWith(
        fontSize: 15.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.5),
    bodySmall: _base.bodySmall?.copyWith(
        fontSize: 13.0, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.4),
    labelLarge: _base.labelLarge?.copyWith(
        fontSize: 15.0, fontWeight: FontWeight.w700, letterSpacing: 0.2, height: 1.3),
    labelMedium: _base.labelMedium?.copyWith(
        fontSize: 13.0, fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.3),
    labelSmall: _base.labelSmall?.copyWith(
        fontSize: 11.0, fontWeight: FontWeight.w700, letterSpacing: 0.4, height: 1.3),
  );
}
