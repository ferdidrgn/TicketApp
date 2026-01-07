import 'package:flutter/material.dart';

import '../navigation/widgets/bottom_nav_bar.dart';
import '../navigation/widgets/web_nav_bar.dart';

abstract final class NavigationKeys {
  static final GlobalKey<NavigatorState> rootNavigator =
      GlobalKey<NavigatorState>();

  static final GlobalKey<BottomNavBarState> mobileNavKey =
      GlobalKey<BottomNavBarState>();

  /// 🔥 WEB BAR STATE’E DOĞRUDAN ERİŞİM
  static final GlobalKey<WebBarState> webBarKey = GlobalKey<WebBarState>();
}
