import 'package:flutter/material.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import '../widgets/web_nav_bar.dart';

abstract final class NavigationKeys {
  static final GlobalKey<NavigatorState> rootNavigator =
      GlobalKey<NavigatorState>();

  static final GlobalKey<MobileBottomNavBarState> mobileNavKey =
      GlobalKey<MobileBottomNavBarState>();

  /// 🔥 WEB BAR STATE’E DOĞRUDAN ERİŞİM
  static final GlobalKey<WebBarState> webBarKey = GlobalKey<WebBarState>();
}
