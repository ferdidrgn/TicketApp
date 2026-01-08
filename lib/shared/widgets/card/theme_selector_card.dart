import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../core/enum/enums.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentPref = ref.watch(themeProvider);
    final isDark = context.isDarkMode;

    // Ahenk modu için sistemin o anki ana rengini çekiyoruz
    final systemColor = context.colors.primary;

    return Column(
      children: [
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

        // Tuval
        Center(
          child: Container(
            height: 70,
            // 4 Buton olduğu için genişliği biraz artırdık
            width: 360,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade200.withOpacity(0.5),
              borderRadius: BorderRadius.circular(40),
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
                // 1. KATMAN: GLOW (IŞIK)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  alignment: _getAlignment(currentPref),
                  child: Container(
                    width: 80, // 4 tane sığsın diye biraz daralttık
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getGlowColor(currentPref, systemColor)
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          _getGlowColor(currentPref, systemColor)
                              .withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. KATMAN: İKONLAR (4 SEÇENEK)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ArtisticButton(
                      label: 'Gündüz',
                      icon: Icons.wb_sunny_rounded,
                      isSelected: currentPref == AppThemePreference.light,
                      activeColor: Colors.orangeAccent,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemePreference.light),
                    ),
                    _ArtisticButton(
                      label: 'Gece',
                      icon: Icons.nights_stay_rounded,
                      isSelected: currentPref == AppThemePreference.dark,
                      activeColor: Colors.purpleAccent.shade100,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemePreference.dark),
                    ),
                    _ArtisticButton(
                      label: 'Sistem',
                      icon: Icons.smartphone_rounded,
                      isSelected: currentPref == AppThemePreference.system,
                      activeColor: Colors.blueGrey,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemePreference.system),
                    ),
                    _ArtisticButton(
                      label: 'Ahenk',
                      // Monet / Dinamik Renk
                      icon: Icons.graphic_eq_rounded,
                      isSelected: currentPref == AppThemePreference.monet,
                      activeColor: systemColor,
                      // Duvar kağıdı rengi!
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemePreference.monet),
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

  // 4 Seçenek için Alignment Ayarları
  Alignment _getAlignment(final AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return const Alignment(-0.9, 0);
      case AppThemePreference.dark:
        return const Alignment(-0.3, 0);
      case AppThemePreference.system:
        return const Alignment(0.3, 0);
      case AppThemePreference.monet:
        return const Alignment(0.9, 0);
    }
  }

  Color _getGlowColor(final AppThemePreference pref, final Color dynamicColor) {
    switch (pref) {
      case AppThemePreference.light:
        return Colors.orange;
      case AppThemePreference.dark:
        return Colors.purple;
      case AppThemePreference.system:
        return Colors.blueGrey;
      case AppThemePreference.monet:
        return dynamicColor; // Sihir burada
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
  Widget build(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black26;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // Seçili ikon hafifçe yukarı süzülür
        transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isSelected ? 24 : 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
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
