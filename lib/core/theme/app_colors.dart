import 'package:flutter/material.dart';
import '../common/extentions/app_context_ui_extension.dart';

/// WEB UYGULAMASI RENKLERİ
/// "SPOTLIGHT" PALETİ — eski lacivert/altın kimliğin tamamen yerine geçer.
/// Sahne arkası, is1 karanlık kulis + tek bir sıcak reflektör rengi fikri.
class WebColors {
  // Ana Renkler — reflektör turuncusu (eski "altın"ın yerine)
  static const Color primaryGold = Color(0xFFE8823C);
  static const Color primaryGoldDark = Color(0xFFC4652A);
  static const Color primaryGoldLight = Color(0xFFF2A868);

  // İkincil vurgu — soğuk gece mavisi-yeşili (yeni, eskisinde yoktu)
  static const Color secondaryAccent = Color(0xFF6E96A0);
  static const Color secondaryAccentLight = Color(0xFF95BAC2);

  // Arkaplan Renkleri — sıcak kömür/kulis siyahı (eski laciverdin yerine)
  static const Color darkBlueBackground = Color(0xFF15110E);
  static const Color darkBlueSurface = Color(0xFF211A15);
  static const Color darkBlueAccent = Color(0xFF2E241D);

  // Ekstra Arkaplan Tonları
  static const Color veryDarkBlue = Color(0xFF0B0806); // En koyu ton
  static const Color mediumDarkBlue = Color(0xFF362A21); // Orta ton

  // Metin Renkleri
  static const Color whiteText = Colors.white;
  static const Color lightWhite = Color(0xFFF4ECE1);
  static const Color textSecondary = Color(0xFFC7B7A6);
  static const Color textTertiary = Color(0xFF93816E); // Ek ton

  // Aksan Renkler
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient'ler - Güncellendi
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      veryDarkBlue,
      darkBlueBackground,
      darkBlueSurface,
      darkBlueAccent,
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGoldLight, primaryGold, primaryGoldDark],
  );

  // Altın Buton Gradient
  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryGold, primaryGoldLight],
  );

  // Kart/Kutu Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlueSurface, darkBlueAccent],
  );
}

/// MOBIL UYGULAMA - AÇIK TEMA RENKLERİ
class AppLightColors {
  static const Color primary = Color(0xFFDC2626); // Kırmızı
  static const Color primaryVariant = Color(0xFFB91C1C);
  static const Color secondary = Color(0xFFFECACA);
  static const Color secondaryVariant = Color(0xFFFCA5A5);

  static const Color surface = Color(0xFFF8FAFC);
  static const Color error = Color(0xFFDC2626);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFF731818);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

/// MOBIL UYGULAMA - KARANLIK TEMA RENKLERİ
class AppDarkColors {
  static const Color primary = Color(0xFF343541);
  static const Color primaryVariant = Color(0xFF3C3E4A);
  static const Color secondary = Color(0xFF444653);
  static const Color secondaryVariant = Color(0xFF565864);

  static const Color surface = Color(0xFF2D2D2D);
  static const Color error = Color(0xFFCF6679);

  static const Color onPrimary = Color(0xFF1A1A1A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFF000000);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF666666);

  static const Color border = Color(0xFF000000);
  static const Color divider = Color(0xFF000000);
}

List<Color> gradientColors(final BuildContext context, final isTrue) => isTrue
    ? (context.theme.brightness == Brightness.light
        ? [Colors.red.shade300, Colors.red.shade900]
        : [Colors.pink[500]!, Colors.purple[600]!])
    : [Colors.grey[500]!, Colors.grey[800]!];

List<Color> gradientOpacityColors() =>
    [Colors.transparent, Colors.black.withOpacity(0.3)];
