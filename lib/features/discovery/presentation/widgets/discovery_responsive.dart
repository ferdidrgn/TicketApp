import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/responsive_utils.dart';

/// Keşfet / Yakınımdakiler — [ResponsiveUtils] kırılımları (768 / 1024 / 1440).
enum DiscoveryBrowseLayout { mobile, tablet, desktop, largeDesktop }

/// Sayfa düzeni, boşluk, ızgara ve harita yüksekliği — tek kaynak.
abstract final class DiscoveryResponsive {
  static DiscoveryBrowseLayout layout(final BuildContext context) {
    if (ResponsiveUtils.isLargeDesktop(context)) {
      return DiscoveryBrowseLayout.largeDesktop;
    }
    if (ResponsiveUtils.isDesktop(context)) {
      return DiscoveryBrowseLayout.desktop;
    }
    if (ResponsiveUtils.isTablet(context)) {
      return DiscoveryBrowseLayout.tablet;
    }
    return DiscoveryBrowseLayout.mobile;
  }

  /// ≥1024: yan panel + [Scaffold]; altında kompakt kaydırma.
  static bool useSidebar(final BuildContext context) {
    final l = layout(context);
    return l == DiscoveryBrowseLayout.desktop ||
        l == DiscoveryBrowseLayout.largeDesktop;
  }

  static double pageGutter(final BuildContext context) {
    switch (layout(context)) {
      case DiscoveryBrowseLayout.mobile:
        return AppSpacing.lg;
      case DiscoveryBrowseLayout.tablet:
        return AppSpacing.xxl;
      case DiscoveryBrowseLayout.desktop:
        return AppSpacing.huge;
      case DiscoveryBrowseLayout.largeDesktop:
        return AppSpacing.massive;
    }
  }

  static int posterGridColumns(final BuildContext context) =>
      ResponsiveUtils.gridColumns(context, maxColumns: 5);

  /// Kompakt düzende (mobil/tablet) harita yüksekliği — masaüstünde esnek.
  static double nearbyMapHeight(final BuildContext context) {
    switch (layout(context)) {
      case DiscoveryBrowseLayout.mobile:
        return 256;
      case DiscoveryBrowseLayout.tablet:
        return 368;
      case DiscoveryBrowseLayout.desktop:
      case DiscoveryBrowseLayout.largeDesktop:
        return 420;
    }
  }

  static double sidebarWidth(final BuildContext context) =>
      layout(context) == DiscoveryBrowseLayout.largeDesktop ? 288 : 260;

  /// Mobil: yatay tür şeridi; tablet: mozaik; masaüstü: kenar çubuğu.
  static bool showCategoryRail(final BuildContext context) =>
      layout(context) == DiscoveryBrowseLayout.mobile;

  static bool showCategoryMosaic(final BuildContext context) =>
      layout(context) == DiscoveryBrowseLayout.tablet;

  static int categoryMosaicColumns(final BuildContext context) {
    final double w = ResponsiveUtils.screenWidth(context);
    if (w >= ResponsiveUtils.tabletBreakpoint - 80) return 4;
    return 3;
  }
}
