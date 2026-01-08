import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  // --- Temel Tema Erişimleri ---
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colors => theme.colorScheme;

  bool get isDarkMode => theme.brightness == Brightness.dark;

  // --- Sık Kullanılan Renkler (Kısayollar) ---
  Color get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;

  Color get primaryColor => theme.primaryColor;

  Color get primaryColorLight => theme.primaryColorLight;

  Color get primaryColorDark => theme.primaryColorDark;

  Color get secondaryHeaderColor => theme.secondaryHeaderColor;

  Color get cardColor => theme.cardColor;

  Color get canvasColor => theme.canvasColor;

  Color get shadowColor => theme.shadowColor;

  Color get dividerColor => theme.dividerColor;

  Color get splashColor => theme.splashColor;

  Color get focusColor => theme.focusColor;

  Color get hintColor => theme.hintColor;

  Color get highlightColor => theme.highlightColor;

  BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      theme.bottomNavigationBarTheme;

  // --- Özel Gradient Mantığın ---
  /// [isActive]: Eğer true ise temanın aktif renklerini (Kırmızı veya Mor),
  /// false ise pasif gri renkleri döndürür.
  List<Color> appGradient({final bool isActive = true}) {
    if (!isActive) return [Colors.grey[500]!, Colors.grey[800]!];

    return isDarkMode
        ? [Colors.pink[500]!, Colors.purple[600]!] // Dark Mode Gradient
        : [Colors.red.shade300, Colors.red.shade900]; // Light Mode Gradient
  }

  // --- Opacity / Overlay Gradient ---
  List<Color> get overlayGradient => [
        Colors.transparent,
        Colors.black.withOpacity(0.3),
      ];
}
