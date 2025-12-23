import 'dart:developer' as dev;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppDebug {
  // Static yaparak her yerden erişimi kolaylaştırdık
  static void log(final Object? message, {final String tag = 'DEBUG'}) {
    if (kDebugMode)
      print('🚀 [$tag] ${DateTime.now().toString().split(' ').last}: $message');
  }

  static void error(final Object e, [final StackTrace? stack]) {
    assert(() {
      print('❌ [ERROR]: $e');
      if (stack != null) print(stack);
      return true;
    }());

    // Canlıda hata takibi için Crashlytics
    FirebaseCrashlytics.instance
        .recordError(e, stack, reason: 'AppDebug Logger', fatal: false);
  }
}

extension DebugLogExtension on Object? {
  void log([final String tag = 'DEBUG']) {
    if (kDebugMode) dev.log(this.toString(), name: tag, time: DateTime.now());
  }
}
