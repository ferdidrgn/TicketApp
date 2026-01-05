import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/app_text_styles.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

mixin AppTheme {
  // ------------------------------------------------------------
  // LIGHT THEME
  // ------------------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppLightColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppLightColors.primary,
      onPrimary: AppLightColors.onPrimary,
      primaryContainer: AppLightColors.primaryVariant,
      secondary: AppLightColors.secondary,
      onSecondary: AppLightColors.onSecondary,
      secondaryContainer: AppLightColors.secondaryVariant,
      background: AppLightColors.background,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.onSurface,
      surfaceVariant: AppLightColors.background,
      onSurfaceVariant: AppLightColors.textSecondary,
      error: AppLightColors.error,
      onBackground: AppLightColors.onBackground,
      onError: AppLightColors.onError,
      // Material 3 yeni yüzey renkleri
      surfaceContainerHighest: AppLightColors.surface,
      outline: AppLightColors.border,
      shadow: Colors.black12,
    ),
    textTheme: AppTextStyles.lightTextTheme,
    appBarTheme: _appBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      brightness: Brightness.light,
    ),
    cardTheme: _cardTheme(
      color: AppLightColors.surface,
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      background: AppLightColors.primary,
      foreground: Colors.white,
      textStyle: AppTextStyles.lightTextTheme.labelLarge!,
    ),
    outlinedButtonTheme: _outlinedButtonTheme(
      color: AppLightColors.primary,
      textStyle: AppTextStyles.lightTextTheme.labelLarge!,
    ),
    textButtonTheme: _textButtonTheme(
      color: AppLightColors.primary,
      textStyle: AppTextStyles.lightTextTheme.labelLarge!,
    ),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: AppLightColors.surface,
      borderColor: AppLightColors.border,
      focusColor: AppLightColors.primary,
      errorColor: AppLightColors.error,
      hintColor: AppLightColors.textSecondary,
    ),
    bottomNavigationBarTheme: _bottomNavigationBarTheme(
      background: AppLightColors.background,
      selected: AppLightColors.primary,
      unselected: AppLightColors.textSecondary,
    ),
    navigationBarTheme: _navigationBarTheme(
      background: AppLightColors.surface,
      indicator: AppLightColors.primary.withOpacity(0.12),
      selected: AppLightColors.primary,
      unselected: AppLightColors.textSecondary,
    ),
  );

  // ------------------------------------------------------------
  // DARK THEME
  // ------------------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppDarkColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppDarkColors.primary,
      primaryContainer: AppDarkColors.primaryVariant,
      secondary: AppDarkColors.secondary,
      secondaryContainer: AppDarkColors.secondaryVariant,
      background: AppDarkColors.background,
      surface: AppDarkColors.surface,
      error: AppDarkColors.error,
      onPrimary: AppDarkColors.onPrimary,
      onSecondary: AppDarkColors.onSecondary,
      onBackground: AppDarkColors.onBackground,
      onSurface: AppDarkColors.onSurface,
      onError: AppDarkColors.onError,
    ),
    textTheme: AppTextStyles.darkTextTheme,
    appBarTheme: _appBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      brightness: Brightness.dark,
    ),
    cardTheme: _cardTheme(
      color: AppDarkColors.surface,
      shadowColor: Colors.black45,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      background: AppDarkColors.primary,
      foreground: Colors.white,
      textStyle: AppTextStyles.darkTextTheme.labelLarge!,
    ),
    outlinedButtonTheme: _outlinedButtonTheme(
      color: Colors.white,
      textStyle: AppTextStyles.darkTextTheme.labelLarge!,
    ),
    textButtonTheme: _textButtonTheme(
      color: Colors.white,
      textStyle: AppTextStyles.darkTextTheme.labelLarge!,
    ),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: AppDarkColors.surface,
      borderColor: AppDarkColors.secondaryVariant,
      focusColor: AppDarkColors.primary,
      errorColor: AppDarkColors.error,
      hintColor: AppDarkColors.textSecondary,
    ),
    bottomNavigationBarTheme: _bottomNavigationBarTheme(
      background: AppDarkColors.surface,
      selected: Colors.white,
      unselected: AppDarkColors.textSecondary,
    ),
    navigationBarTheme: _navigationBarTheme(
      background: AppDarkColors.surface,
      indicator: Colors.white10,
      selected: Colors.white,
      unselected: AppDarkColors.textSecondary,
    ),
  );

  // ------------------------------------------------------------
  // COMPONENT THEMES
  // ------------------------------------------------------------
  static AppBarTheme _appBarTheme({
    required final Color backgroundColor,
    required final Color foregroundColor,
    required final Brightness brightness,
  }) =>
      AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: foregroundColor, size: 28),
        titleTextStyle: TextStyle(
          color: foregroundColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      );

  static CardThemeData _cardTheme({
    required final Color color,
    required final Color shadowColor,
  }) =>
      CardThemeData(
        color: color,
        elevation: 2,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      );

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required final Color background,
    required final Color foreground,
    required final TextStyle textStyle,
  }) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          textStyle: textStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required final Color color,
    required final TextStyle textStyle,
  }) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          textStyle: textStyle,
          side: BorderSide(color: color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static TextButtonThemeData _textButtonTheme({
    required final Color color,
    required final TextStyle textStyle,
  }) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: color,
          textStyle: textStyle,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({
    required final Color fillColor,
    required final Color borderColor,
    required final Color focusColor,
    required final Color errorColor,
    required final Color hintColor,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        hintStyle: TextStyle(color: hintColor),
      );

  static BottomNavigationBarThemeData _bottomNavigationBarTheme({
    required final Color background,
    required final Color selected,
    required final Color unselected,
  }) =>
      BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: selected,
        unselectedItemColor: unselected,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      );

  static NavigationBarThemeData _navigationBarTheme({
    required final Color background,
    required final Color indicator,
    required final Color selected,
    required final Color unselected,
  }) =>
      NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: indicator,
        labelTextStyle:
            MaterialStateProperty.resolveWith((final states) => TextStyle(
                  color: states.contains(MaterialState.selected)
                      ? selected
                      : unselected,
                  fontWeight: FontWeight.w500,
                )),
      );
}
