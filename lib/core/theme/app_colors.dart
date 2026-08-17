import 'package:flutter/material.dart';
import '../common/extentions/app_context_ui_extension.dart';

/// ══════════════════════════════════════════════════════════════════════
/// TASARIM SİSTEMİ 2.0 — Slate/Zinc tabanlı derin dark mod + Indigo/Emerald
/// aksan. `WebColors` ve `AppLightColors`/`AppDarkColors` isimleri (geriye
/// dönük uyumluluk ve tek noktadan değişim için) korundu, ama TÜM değerler
/// yeni tasarım diline göre baştan tanımlandı. Bu sayede bu sabitleri
/// referans alan onlarca ekran, dosyalar tek tek düzenlenmeden otomatik
/// olarak yeni palete geçer.
/// ══════════════════════════════════════════════════════════════════════

/// WEB UYGULAMASI RENKLERİ (Slate/Zinc + Indigo)
class WebColors {
  // Ana Aksan (eskiden "Gold" — artık Elektrik Indigo)
  static const Color primaryGold = Color(0xFF6366F1); // Indigo 500
  static const Color primaryGoldDark = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryGoldLight = Color(0xFF818CF8); // Indigo 400

  // İkincil Aksan
  static const Color accentEmerald = Color(0xFF10B981);

  // Arkaplan Katmanları (Zinc/Slate)
  static const Color darkBlueBackground = Color(0xFF09090B); // Canvas
  static const Color darkBlueSurface = Color(0xFF18181B); // Kart
  static const Color darkBlueAccent = Color(0xFF27272A); // Highlight yüzey

  // Ekstra Arkaplan Tonları
  static const Color veryDarkBlue = Color(0xFF000000);
  static const Color mediumDarkBlue = Color(0xFF141417);

  // Metin Renkleri
  static const Color whiteText = Colors.white;
  static const Color lightWhite = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textTertiary = Color(0xFF71717A); // Zinc 500

  // Aksan Renkler
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Mikro Kenarlık (Bento kartlar için)
  static const Color microBorder = Color(0x14FFFFFF); // ~%8 beyaz

  // Gradient'ler
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

/// MOBIL UYGULAMA - AÇIK TEMA RENKLERİ (Slate + Indigo)
class AppLightColors {
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryVariant = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFFE0E7FF); // Indigo 100
  static const Color secondaryVariant = Color(0xFFC7D2FE); // Indigo 200

  static const Color surface = Color(0xFFFAFAFA); // Zinc 50
  static const Color error = Color(0xFFEF4444);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF3730A3);
  static const Color onSurface = Color(0xFF18181B);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFFA1A1AA);

  static const Color border = Color(0xFFE4E4E7);
  static const Color divider = Color(0xFFF4F4F5);
}

/// MOBIL UYGULAMA - KARANLIK TEMA RENKLERİ (Zinc canvas + Indigo aksan)
class AppDarkColors {
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryVariant = Color(0xFF818CF8); // Indigo 400
  static const Color secondary = Color(0xFF27272A); // Zinc 800
  static const Color secondaryVariant = Color(0xFF3F3F46); // Zinc 700

  static const Color surface = Color(0xFF18181B); // Zinc 900
  static const Color error = Color(0xFFF87171);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFAFAFA);
  static const Color onError = Color(0xFF000000);

  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textDisabled = Color(0xFF52525B); // Zinc 600

  static const Color border = Color(0x14FFFFFF); // ~%8 beyaz mikro kenarlık
  static const Color divider = Color(0x0FFFFFFF);
}

/// Canvas/kart/highlight katman renkleri — Bento bileşenlerinde doğrudan
/// kullanılan, tema seed'inden bağımsız sabit tonlar.
abstract final class BentoColors {
  static const Color canvas = Color(0xFF09090B);
  static const Color card = Color(0xFF18181B);
  static const Color highlight = Color(0xFF27272A);
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoDark = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF818CF8);
  static const Color emerald = Color(0xFF10B981);
  static const Color microBorder = Color(0x14FFFFFF);
  static const Color microBorderStrong = Color(0x26FFFFFF); // ~%15 beyaz
}

List<Color> gradientColors(final BuildContext context, final isTrue) => isTrue
    ? (context.theme.brightness == Brightness.light
        ? [Colors.red.shade300, Colors.red.shade900]
        : [Colors.pink[500]!, Colors.purple[600]!])
    : [Colors.grey[500]!, Colors.grey[800]!];

List<Color> gradientOpacityColors() =>
    [Colors.transparent, Colors.black.withOpacity(0.3)];
