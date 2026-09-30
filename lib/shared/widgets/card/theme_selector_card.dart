import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/common/enum/enums.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_notifier.dart';

/// Tema seçici (Profil sayfası). 6 seçenek (5 hazır stil + Özel renk) —
/// hepsi AYNI anda etiketleriyle görünür; seçili olan, bilet dilindeki gibi
/// temanın vurgusuyla çerçevelenmiş bir "damga" kutusu. Eski parlayan
/// hale (glow) ve sadece seçilince beliren etiketler kaldırıldı. Seçim
/// mantığı (`themeProvider.setTheme`) aynı.
class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentStyle = ref.watch(themeProvider);
    final cs = context.colors;

    // Sistemden gelen dinamik renk (Yoksa varsayılan tema rengi)
    final systemColor = cs.primary;
    // Kullanıcının Ayarlar > Tema Rengi'nden seçtiği özel renk (henüz
    // seçilmediyse null — bu durumda systemColor'a düşer)
    final customColor = ref.watch(customAccentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- BAŞLIK ---
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.lg, bottom: AppSpacing.md),
          child: Semantics(
            header: true,
            child: Text(
              "TEMA",
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),

        // --- SEÇENEKLER ---
        Center(
          child: ConstrainedBox(
            // Tablette aşırı uzamasın
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: AppThemeStyle.values.map((final style) {
                  return Expanded(
                    child: _ArtisticButton(
                      style: style,
                      isSelected: currentStyle == style,
                      activeColor: style.getGlowColor(systemColor,
                          customColor: customColor),
                      onTap: () =>
                          ref.read(themeProvider.notifier).setTheme(style),
                    ),
                  );
                }).toList(),
              ),
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
  // 1. Hizalama Pozisyonu (6 Buton için matematiksel dağılım)
  Alignment get alignment {
    switch (this) {
      case AppThemeStyle.appLight:
        return const Alignment(-1.0, 0);
      case AppThemeStyle.appDark:
        return const Alignment(-0.6, 0);
      case AppThemeStyle.system:
        return const Alignment(-0.2, 0);
      case AppThemeStyle.materialLight:
        return const Alignment(0.2, 0);
      case AppThemeStyle.materialDark:
        return const Alignment(0.6, 0);
      case AppThemeStyle.custom:
        return const Alignment(1.0, 0);
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
      case AppThemeStyle.custom:
        return Icons.colorize_rounded; // Kullanıcının kendi seçtiği renk
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
      case AppThemeStyle.custom:
        return 'Özel';
    }
  }

  // 4. Renk (Glow Rengi). `customColor`, kullanıcının Ayarlar > Tema
  // Rengi'nden seçtiği renktir; sadece `custom` stili için kullanılır.
  Color getGlowColor(final Color systemDynamicColor, {final Color? customColor}) {
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
      case AppThemeStyle.custom:
        return customColor ?? systemDynamicColor;
    }
  }
}

/// --- ALT BİLEŞEN: BUTON ---
/// Renk örneği (seçeneğin kendi rengi — bilgi taşır) + her zaman görünen
/// etiket. Seçiliyse temanın vurgusuyla 2px çerçeve.
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
    final cs = context.colors;
    final Color onSwatch =
        ThemeData.estimateBrightnessForColor(activeColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Tema: ${style.label}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            side: BorderSide(
              color: isSelected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            focusColor: cs.primary.withOpacity(0.16),
            hoverColor: cs.onSurface.withOpacity(0.05),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(style.icon, size: 16, color: onSwatch),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      style.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color:
                            isSelected ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
