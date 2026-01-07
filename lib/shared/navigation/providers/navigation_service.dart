import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_keys.dart';

abstract final class NavigationService {
  // ROOT (modal, dialog vs.)
  static NavigatorState? get _nav => NavigationKeys.rootNavigator.currentState;

  static Future<T?> push<T>(Route<T> route) => _nav!.push(route);

  static void pop<T extends Object?>([T? result]) => _nav?.pop(result);

  // ✅ MOBİL TAB NAVIGATION (ROUTER)
  static void goToDiscoverWithCategory(BuildContext context, String category) =>
      context.go('/discover?category=$category');

  // ✅ WEB SCROLL (UI-ONLY → GlobalKey OK)
  static void scrollToWebSection(String section) =>
      NavigationKeys.webBarKey.currentState?.scrollToSection(section);
}
