import 'dart:developer' as dev;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppDebug {
  // Static yaparak her yerden erişimi kolaylaştırdık
  static void log(final Object? message, {final String tag = 'DEBUG'}) {
    if (kDebugMode)
      print('🚀 [$tag] ${DateTime.now().toString().split(' ').last}: $message');
  }

  static void logError(final Object e,
      [final StackTrace? stack, final String tag = 'ERROR']) {
    assert(() {
      print('❌ [$tag] - $e'); // tag parametresini buraya ekledik
      if (stack != null) print(stack);
      return true;
    }());

    FirebaseCrashlytics.instance.recordError(
      e,
      stack,
      reason: tag, // Firebase'e hata nedeni olarak gönderiyoruz
      fatal: false,
    );
  }
}

extension DebugLogExtension on Object? {
  void log([final String tag = 'DEBUG']) {
    if (kDebugMode) dev.log(this.toString(), name: tag, time: DateTime.now());
  }
}
