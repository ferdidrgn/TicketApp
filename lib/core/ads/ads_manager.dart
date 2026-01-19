import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../common/enum/enums.dart';
import '../services/remote_config_service.dart';
import '../util/platform_checker.dart';

final class AdManager {
  AdManager._internal();

  static final AdManager instance = AdManager._internal();

  static bool _initialized = false;

  /// 🔹 SADECE MOBİL
  static Future<void> initialize() async {
    if (_initialized) return;
    if (PlatformChecker.isMobile && RemoteConfigService.adsEnabled)
      await MobileAds.instance.initialize();

    _initialized = true;
  }

  /// 🔹 PUBLIC API
  static String getAdUnitId(final AdUnitType type) {
    if (kIsWeb) return _web(type);
    return _mobile(type);
  }

  // =====================
  // MOBILE
  // =====================

  static String _mobile(final AdUnitType type) =>
      kDebugMode ? _debugMobile(type) : _prodMobile(type);

  static String _debugMobile(final AdUnitType type) {
    switch (type) {
      case AdUnitType.banner:
        return PlatformChecker.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716';

      case AdUnitType.native:
        return 'ca-app-pub-3940256099942544/2247696110';

      default:
        return '';
    }
  }

  static String _prodMobile(final AdUnitType type) {
    switch (type) {
      case AdUnitType.banner:
        return PlatformChecker.isAndroid
            ? 'ca-app-pub-5779807348211992/6454721883'
            : 'IOS_BANNER_ID';

      case AdUnitType.native:
        return PlatformChecker.isAndroid
            ? 'ca-app-pub-5779807348211992/2655077678'
            : 'IOS_NATIVE_ID';

      default:
        return '';
    }
  }

  // =====================
  // WEB
  // =====================

  static String _web(final AdUnitType type) =>
      kDebugMode ? _debugWeb(type) : _prodWeb(type);

  static String _debugWeb(final AdUnitType type) {
    switch (type) {
      case AdUnitType.display:
        return 'TEST_DISPLAY';
      case AdUnitType.inArticle:
        return 'TEST_IN_ARTICLE';
      case AdUnitType.multiplex:
        return 'TEST_MULTIPLEX';
      default:
        return '';
    }
  }

  static String _prodWeb(final AdUnitType type) {
    switch (type) {
      case AdUnitType.display:
        return '1670983275'; // display
      case AdUnitType.inArticle:
        return '3810061450'; // in-article
      case AdUnitType.multiplex:
        return '4929919042'; // multiplex
      default:
        return '';
    }
  }
}
