import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

mixin WebTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: WebColors.primaryGold,
        scaffoldBackgroundColor: WebColors.darkBlueBackground,
        colorScheme: const ColorScheme.dark(
          primary: WebColors.primaryGold,
          onPrimary: WebColors.whiteText,
          secondary: WebColors.darkBlueSurface,
          onSecondary: WebColors.whiteText,
          surface: WebColors.darkBlueSurface,
          onSurface: WebColors.whiteText,
          background: WebColors.darkBlueBackground,
          onBackground: WebColors.whiteText,
          error: WebColors.error,
          onError: WebColors.whiteText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: WebColors.whiteText),
          titleTextStyle: TextStyle(
            color: WebColors.whiteText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: TextTheme(
          displayLarge:
              WebTextStyles.displayLarge.copyWith(color: WebColors.whiteText),
          displayMedium:
              WebTextStyles.displayMedium.copyWith(color: WebColors.whiteText),
          displaySmall:
              WebTextStyles.displaySmall.copyWith(color: WebColors.whiteText),
          headlineLarge:
              WebTextStyles.headlineLarge.copyWith(color: WebColors.whiteText),
          headlineMedium:
              WebTextStyles.headlineMedium.copyWith(color: WebColors.whiteText),
          headlineSmall:
              WebTextStyles.headlineSmall.copyWith(color: WebColors.whiteText),
          titleLarge:
              WebTextStyles.titleLarge.copyWith(color: WebColors.whiteText),
          titleMedium:
              WebTextStyles.titleMedium.copyWith(color: WebColors.whiteText),
          titleSmall:
              WebTextStyles.titleSmall.copyWith(color: WebColors.whiteText),
          bodyLarge:
              WebTextStyles.bodyLarge.copyWith(color: WebColors.lightWhite),
          bodyMedium:
              WebTextStyles.bodyMedium.copyWith(color: WebColors.lightWhite),
          bodySmall:
              WebTextStyles.bodySmall.copyWith(color: WebColors.textSecondary),
          labelLarge:
              WebTextStyles.labelLarge.copyWith(color: WebColors.whiteText),
          labelMedium:
              WebTextStyles.labelMedium.copyWith(color: WebColors.whiteText),
          labelSmall:
              WebTextStyles.labelSmall.copyWith(color: WebColors.textSecondary),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: WebColors.darkBlueSurface,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: WebColors.darkBlueSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: WebColors.primaryGold),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        buttonTheme: const ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: WebColors.primaryGold,
          foregroundColor: WebColors.darkBlueBackground,
        ),
      );
}
