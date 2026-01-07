import 'package:flutter/material.dart';
import 'navigation_keys.dart';

abstract final class NavigationService {
  // ------------------------
  // ROOT NAVIGATION
  // ------------------------
  static NavigatorState? get _nav =>
      NavigationKeys.rootNavigator.currentState;

  static Future<T?> push<T>(Route<T> route) =>
      _nav!.push(route);

  static void pop<T extends Object?>([T? result]) =>
      _nav?.pop(result);

  // ------------------------
  // MOBILE TAB
  // ------------------------
  static void changeMobileTab(int index, {String? category}) {
    NavigationKeys.mobileNavKey.currentState
        ?.changeTabWithCategory(index, category);
  }

  // ------------------------
  // WEB SECTION ✅ ÇALIŞIR
  // ------------------------
  static void scrollToWebSection(String section) {
    NavigationKeys.webBarKey.currentState
        ?.scrollToSection(section);
  }
}
