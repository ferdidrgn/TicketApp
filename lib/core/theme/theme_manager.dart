import 'package:flutter/material.dart';
import '../enum/enums.dart';
import 'app_colors.dart';
import 'app_theme.dart';

class ThemeManager {
  final AppThemeStyle style;

  ThemeManager(this.style);

  ThemeData getLightTheme(final ColorScheme? lightDynamic) {
    const fixedSeedColor = AppLightColors.primary;

    switch (style) {
      case AppThemeStyle.appLight:
        return AppTheme.createTheme(
          colors: ColorScheme.fromSeed(
            seedColor: fixedSeedColor,
            brightness: Brightness.light,
          ),
        );

      case AppThemeStyle.system:
      case AppThemeStyle.appDark:
        // AppDark seçili olsa bile Light modda standart light rengi döner
        return AppTheme.createTheme(
          colors: ColorScheme.fromSeed(
            seedColor: fixedSeedColor,
            brightness: Brightness.light,
          ),
        );

      case AppThemeStyle.materialLight:
      case AppThemeStyle.materialDark:
        final seed = lightDynamic?.primary ?? fixedSeedColor;
        return AppTheme.createTheme(
          colors: lightDynamic ??
              ColorScheme.fromSeed(
                  seedColor: seed, brightness: Brightness.light),
        );
    }
  }

  ThemeData getDarkTheme(final ColorScheme? darkDynamic) {
    // 1. Genel varsayılan renk (Light ve System için)
    const defaultSeed = AppLightColors.primary;

    // 2. ÖZEL DURUM: Sadece 'AppDark' modu için kullanacağın renk
    const myDarkSpecificSeed = AppDarkColors.primary;

    switch (style) {
      // DURUM 1 & 3: App Light ve System
      // Bunlar dark moda geçince varsayılan renkten (defaultSeed) türesin.
      // -------------------------------------------------------------
      case AppThemeStyle.appLight:
      case AppThemeStyle.system:
        return AppTheme.createTheme(
          colors: ColorScheme.fromSeed(
            seedColor: defaultSeed,
            brightness: Brightness.dark,
          ),
        );

      // DURUM 2: APP DARK (SENİN İSTEDİĞİN YER)
      // Burayı ayırdık. Artık burası 'myDarkSpecificSeed' kullanıyor.
      // -------------------------------------------------------------
      case AppThemeStyle.appDark:
        return AppTheme.createTheme(
          colors: ColorScheme.fromSeed(
            seedColor: myDarkSpecificSeed, // <-- Kendi özel rengin burada!
            brightness: Brightness.dark,
          ),
        );

      // DURUM 4: Material Light (Fallback olarak darkDynamic kullanır)
      // -------------------------------------------------------------
      case AppThemeStyle.materialLight:
        final seed = darkDynamic?.primary ?? defaultSeed;
        return AppTheme.createTheme(
          colors: darkDynamic ??
              ColorScheme.fromSeed(
                  seedColor: seed, brightness: Brightness.dark),
        );

      // DURUM 5: Material Dark (Atmosferik Mod)
      // -------------------------------------------------------------
      case AppThemeStyle.materialDark:
        final seed = darkDynamic?.primary ?? defaultSeed;
        final atmosphericColor = AppTheme.createAtmosphericBackground(seed);

        return AppTheme.createTheme(
          scaffoldBackgroundOverride: atmosphericColor,
          colors: (darkDynamic ??
                  ColorScheme.fromSeed(
                      seedColor: seed, brightness: Brightness.dark))
              .copyWith(
            surface: atmosphericColor,
            onSurface: Colors.white,
          ),
        );
    }
  }
}
