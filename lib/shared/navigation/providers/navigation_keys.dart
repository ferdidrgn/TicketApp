import 'package:flutter/material.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import '../widgets/web_nav_bar.dart';

abstract final class NavigationKeys {
  static final GlobalKey<NavigatorState> rootNavigator =
      GlobalKey<NavigatorState>();

  static final GlobalKey<MobileBottomNavBarState> mobileNavKey =
      GlobalKey<MobileBottomNavBarState>();

  static final homeShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'homeShell');
  static final nearByShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'nearByShellKey');
  static final discoveryShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'discoveryShellKey');
  static final settingsShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'settingsShellKey');

  /// 🔥 WEB BAR STATE’E DOĞRUDAN ERİŞİM
  static final GlobalKey<WebBarState> webBarKey = GlobalKey<WebBarState>();
}
