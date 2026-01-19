import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../core/common/enum/enums.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentStyle = ref.watch(themeProvider);
    final isDark = context.isDarkMode;

    // Sistemden gelen dinamik renk (Yoksa varsayılan tema rengi)
    final systemColor = context.colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Başlığı sola alır
      children: [
        // --- BAŞLIK ---
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          child: Text(
            "ATÖLYE IŞIĞI",
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),

        // --- TUVAL (KAPSAYICI) ---
        Center(
          child: Container(
            height: 75,
            // 5 buton için hafif yükseklik artışı
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            // Tablette aşırı uzamasın
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.black.withOpacity(0.4) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50), // Daha modern oval
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. KATMAN: GLOW (SEÇİM IŞIĞI)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack, // Elastik geçiş
                  alignment: currentStyle.alignment,
                  child: Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentStyle
                              .getGlowColor(systemColor)
                              .withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 1,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          currentStyle
                              .getGlowColor(systemColor)
                              .withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. KATMAN: BUTONLAR (5 ADET)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AppThemeStyle.values.map((final style) {
                    return _ArtisticButton(
                      style: style,
                      isSelected: currentStyle == style,
                      activeColor: style.getGlowColor(systemColor),
                      onTap: () =>
                          ref.read(themeProvider.notifier).setTheme(style),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// --- CODE REFACTORING: EXTENSION MANTIĞI ---
/// UI Lojiğini Widget'tan ayırıp Veri Tipine (Enum) yüklüyoruz.
extension AppThemeStyleUI on AppThemeStyle {
  // 1. Hizalama Pozisyonu (5 Buton için matematiksel dağılım)
  Alignment get alignment {
    switch (this) {
      case AppThemeStyle.appLight:
        return const Alignment(-0.95, 0);
      case AppThemeStyle.appDark:
        return const Alignment(-0.5, 0);
      case AppThemeStyle.system:
        return const Alignment(0.0, 0);
      case AppThemeStyle.materialLight:
        return const Alignment(0.5, 0);
      case AppThemeStyle.materialDark:
        return const Alignment(0.95, 0);
    }
  }

  // 2. İkon Seçimi
  IconData get icon {
    switch (this) {
      case AppThemeStyle.appLight:
        return Icons.wb_sunny_rounded;
      case AppThemeStyle.appDark:
        return Icons.nights_stay_rounded;
      case AppThemeStyle.system:
        return Icons.auto_mode_rounded;
      case AppThemeStyle.materialLight:
        return Icons.palette_outlined; // Monet Light
      case AppThemeStyle.materialDark:
        return Icons.blur_on_rounded; // Atmosferik
    }
  }

  // 3. Etiket
  String get label {
    switch (this) {
      case AppThemeStyle.appLight:
        return 'Gündüz';
      case AppThemeStyle.appDark:
        return 'Gece';
      case AppThemeStyle.system:
        return 'Oto';
      case AppThemeStyle.materialLight:
        return 'Doğa';
      case AppThemeStyle.materialDark:
        return 'Ahenk';
    }
  }

  // 4. Renk (Glow Rengi)
  Color getGlowColor(final Color systemDynamicColor) {
    switch (this) {
      case AppThemeStyle.appLight:
        return Colors.orangeAccent;
      case AppThemeStyle.appDark:
        return Colors.purpleAccent.shade100;
      case AppThemeStyle.system:
        return Colors.blueGrey;
      case AppThemeStyle.materialLight:
        return systemDynamicColor; // Duvar kağıdı
      case AppThemeStyle.materialDark:
        return systemDynamicColor; // Duvar kağıdı
    }
  }
}

/// --- ALT BİLEŞEN: BUTON ---
class _ArtisticButton extends StatelessWidget {
  final AppThemeStyle style;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ArtisticButton({
    required this.style,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white24 : Colors.black26;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Tıklama alanını genişletir
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        // Seçili ikon yukarı doğru hafifçe süzülür
        transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon Kutusu
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.1) // Hafif renkli background
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                style.icon,
                size: isSelected ? 22 : 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),

            // Etiket Animasyonu
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
