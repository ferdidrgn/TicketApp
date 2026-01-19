import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleController extends _$LocaleController {
  // Şifreli depolama birimi
  final _storage = const FlutterSecureStorage();
  static const _prefKey = 'app_locale';

  @override
  FutureOr<Locale> build() async {
    // Şifreli alandan dili oku
    final languageCode = await _storage.read(key: _prefKey);

    // Kayıt yoksa varsayılan 'tr'
    return Locale(languageCode ?? 'tr');
  }

  Future<void> setLocale(final Locale locale) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Dili şifreli olarak kaydet
      await _storage.write(key: _prefKey, value: locale.languageCode);
      return locale;
    });
  }

  Future<void> toggleLocale() async {
    final current = state.value ?? const Locale('tr');
    final next =
        current.languageCode == 'tr' ? const Locale('en') : const Locale('tr');
    await setLocale(next);
  }
}
