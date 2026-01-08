import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui'; // Blur efekti için gerekli
import '../../../core/theme/theme_context_extension.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Başlık: Sanatsal ve minimal
        Text(
          "ATÖLYE IŞIĞI",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 16),

        // Ana Kapsayıcı (Tuval)
        Center(
          child: Container(
            height: 70,
            width: 320, // Genişlik sınırlaması estetik durur
            decoration: BoxDecoration(
              // Light modda çok hafif gri, Dark modda yarı saydam siyah
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade200.withOpacity(0.5),
              borderRadius: BorderRadius.circular(40),
              // İnce, zarif bir çerçeve
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. KATMAN: SİHİRLİ GEZEN IŞIK (GLOW)
                // Bu parça seçilen modun arkasına kayar
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack, // Hafif taşma efekti (yaylanma)
                  alignment: _getAlignment(currentTheme),
                  child: Container(
                    width: 90,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // Işık topu şeklinde
                      boxShadow: [
                        BoxShadow(
                          // Moduna göre ışığın rengi değişiyor!
                          color: _getGlowColor(currentTheme).withOpacity(0.4),
                          blurRadius: 25, // Çok yumuşak yayılım
                          spreadRadius: 5,
                        ),
                      ],
                      // Işığın merkezi
                      gradient: RadialGradient(
                        colors: [
                          _getGlowColor(currentTheme).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. KATMAN: İKONLAR VE ETKİLEŞİM
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ArtisticButton(
                      label: 'Gündüz',
                      icon: Icons.wb_sunny_rounded,
                      isSelected: currentTheme == ThemeMode.light,
                      activeColor: Colors.orangeAccent,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    _ArtisticButton(
                      label: 'Gece',
                      icon: Icons.nights_stay_rounded,
                      isSelected: currentTheme == ThemeMode.dark,
                      activeColor: Colors.purpleAccent.shade100,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.dark),
                    ),
                    _ArtisticButton(
                      label: 'Sistem',
                      // Sistem yerine daha şiirsel
                      icon: Icons.all_inclusive_rounded,
                      isSelected: currentTheme == ThemeMode.system,
                      activeColor: Colors.blueAccent,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Alignment _getAlignment(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return const Alignment(-0.75, 0);
      case ThemeMode.dark:
        return const Alignment(0, 0);
      case ThemeMode.system:
        return const Alignment(0.75, 0);
    }
  }

  Color _getGlowColor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Colors.orange;
      case ThemeMode.dark:
        return Colors.purple;
      case ThemeMode.system:
        return Colors.blue;
    }
  }
}

class _ArtisticButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ArtisticButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pasif ikon rengi: Light modda gri, Dark modda beyazımsı
    final inactiveColor = isDark ? Colors.white38 : Colors.black26;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent, // Tıklama alanını iyileştirir
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // Seçili olunca hafif yukarı kalksın (Havalanma efekti)
        transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon Animasyonu
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isSelected ? 26 : 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),

            // Yazı Animasyonu (Opaklık geçişi)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
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
