import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

mixin WebTheme {
  // 1. WEB TEMA FABRİKASI
  // ===========================================================================
  static ThemeData createTheme(final ColorScheme colors) {
    // Web için özel tipografiyi çağırıyoruz
    final TextTheme baseTextTheme = AppTextStyles.webTextTheme;

    // Yazı tiplerini gelen rengin "onSurface" (yüzey üzerindeki renk) tonuna boyuyoruz
    // Genelde bu beyaz veya kırık beyaz olur.
    final TextTheme coloredTextTheme = baseTextTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
      decorationColor: colors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      // Web'de genelde background kullanılır
      colorScheme: colors,

      // Boyanmış text teması
      textTheme: coloredTextTheme,

      // --- BİLEŞEN AYARLARI ---
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        // Web'de başlık genelde solda olur
        iconTheme: IconThemeData(color: colors.onSurface),
        titleTextStyle: coloredTextTheme.titleLarge
            ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: colors.surface, // WebColors.darkBlueSurface buraya denk gelecek
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        // Inputlar kartlarla aynı renk
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: WebColors.primaryGold), // Veya colors.primary
        ),
      ),

      buttonTheme: const ButtonThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      // Scrollbar Web için önemlidir
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(colors.primary.withOpacity(0.5)),
        trackColor: MaterialStateProperty.all(colors.surface.withOpacity(0.5)),
      ),

      // --- SİTENİN GENELİNDE TUTARLI "PREMİUM" BİLEŞENLER ---
      // Bu bölüm, tek tek her sayfayı elle boyamak yerine, tüm standart
      // Material bileşenlerinin (buton, sekme, chip, dialog vb.) otomatik
      // olarak lacivert/altın temayla uyumlu görünmesini sağlar.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withOpacity(0.6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurface.withOpacity(0.4),
        indicatorColor: colors.primary,
        dividerColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withOpacity(0.2),
        labelStyle: TextStyle(color: colors.onSurface),
        side: BorderSide(color: colors.primary.withOpacity(0.25)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100)),
      ),
      dividerTheme: DividerThemeData(
        color: colors.primary.withOpacity(0.15),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.primary.withOpacity(0.25)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle: TextStyle(color: colors.onSurface),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===========================================================================
  // 2. VARSAYILAN WEB KOYU TEMASI (Dark Theme)
  // ===========================================================================

  // Burada senin özel WebColors renklerini ColorScheme paketine sarıp fabrikaya yolluyoruz.
  static ThemeData get darkTheme => createTheme(
        const ColorScheme.dark(
          // Ana Renk (Gold)
          primary: WebColors.primaryGold,
          onPrimary: WebColors.darkBlueBackground,
          // Gold üstüne koyu yazı okunur

          // İkincil Renk (Surface ile aynı yaptık ama istersen değiştirebilirsin)
          secondary: WebColors.darkBlueSurface,
          onSecondary: WebColors.whiteText,

          // Arka Planlar
          background: WebColors.darkBlueBackground,
          onBackground: WebColors.whiteText,

          // Kartlar ve Yüzeyler
          surface: WebColors.darkBlueSurface,
          onSurface: WebColors.whiteText,

          // Hata
          error: WebColors.error,
          onError: WebColors.whiteText,

          // Outline ve diğer detaylar
          outline: WebColors.textSecondary,
        ),
      );
}
