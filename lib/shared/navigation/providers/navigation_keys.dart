import 'package:flutter/material.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import '../widgets/web_top_navigation_bar.dart';

/// 🧭 Global Navigation Keys
/// Merkezi navigator referansları - global erişim için
abstract final class NavigationKeys {
  // 🎯 ANA NAVIGATOR (GoRouter root)
  static final GlobalKey<NavigatorState> rootNavigator =
      GlobalKey<NavigatorState>();

  // 📱 MOBILE NAV BAR (Dışardan kontrol için)
  static final GlobalKey<MobileBottomNavBarState> mobileNavKey =
      GlobalKey<MobileBottomNavBarState>();

  // 💻 WEB NAV BAR (Dışardan kontrol için)
  static final GlobalKey<WebTopNavigationBarState> webNavKey =
      GlobalKey<WebTopNavigationBarState>();

// ℹ️ NOT: Shell navigator key'leri artık app_router.dart içinde lokal olarak tanımlanıyor
// Bu daha temiz ve StatefulShellRoute ile uyumlu
}
