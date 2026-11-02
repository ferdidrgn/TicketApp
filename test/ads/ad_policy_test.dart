// Reklam politikası testleri (geçersiz trafik önlemi). Bkz. docs/REKLAM-POLITIKASI.md.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/ads/ads_manager.dart';
import 'package:ticketapp/core/common/enum/enums.dart';
import 'package:ticketapp/core/services/remote_config_service.dart';

const _googleTestPub = 'ca-app-pub-3940256099942544';

void main() {
  group('Reklam birimleri', () {
    test('mağaza dışı derlemede (varsayılan) GERÇEK birim kullanılmaz', () {
      expect(AdManager.usesProductionUnits, isFalse);
      expect(AdManager.getAdUnitId(AdUnitType.banner),
          startsWith(_googleTestPub));
      expect(AdManager.getAdUnitId(AdUnitType.native),
          startsWith(_googleTestPub));
    });

    test('birim kimliği doğrulaması: yer tutucu/boş değer reklam isteği atmaz', () {
      expect(AdManager.isValidUnitId('ca-app-pub-3940256099942544/6300978111'),
          isTrue);
      expect(AdManager.isValidUnitId(''), isFalse);
      expect(AdManager.isValidUnitId('IOS_BANNER_ID'), isFalse);
      expect(AdManager.isValidUnitId('ca-app-pub-5779807348211992'), isFalse);
      expect(AdManager.isValidUnitId('ca-app-pub-5779807348211992/IOS_X'),
          isFalse);
    });
  });

  group('Açma/kapama anahtarı', () {
    test('varsayılan KAPALI (Remote Config okunamazsa reklam yok)', () {
      expect(RemoteConfigService.adsEnabledNotifier.value, isFalse);
      expect(RemoteConfigService.adsEnabled, isFalse);
    });

    test('kapalıyken hiçbir tür için reklam isteği atılmaz', () {
      RemoteConfigService.adsEnabledNotifier.value = false;
      expect(AdManager.canServe(AdUnitType.banner), isFalse);
      expect(AdManager.canServe(AdUnitType.native), isFalse);
    });

    test('açıkken test birimleriyle istek atılabilir', () {
      RemoteConfigService.adsEnabledNotifier.value = true;
      addTearDown(() => RemoteConfigService.adsEnabledNotifier.value = false);
      expect(AdManager.canServe(AdUnitType.banner), isTrue);
    });
  });

  group('Yerleşim kuralları (kaynak taraması)', () {
    // Reklam bileşenleri bu ekranlarda ASLA kullanılmaz: yanlışlıkla tıklama/geçersiz trafik riski.
    const yasakDizinler = [
      'lib/features/purchase',
      'lib/features/seat',
      'lib/features/auth',
      'lib/features/settings',
      'lib/features/tickets',
    ];
    final desen = RegExp(r'AdBannerWidget|AdNativeWidget|AdsenseBanner|InterstitialAd|RewardedAd|AppOpenAd');

    for (final d in yasakDizinler) {
      test('$d içinde reklam bileşeni yok', () {
        final dir = Directory(d);
        if (!dir.existsSync()) return;
        final bulunan = <String>[];
        for (final f in dir.listSync(recursive: true)) {
          if (f is File && f.path.endsWith('.dart')) {
            if (desen.hasMatch(f.readAsStringSync())) bulunan.add(f.path);
          }
        }
        expect(bulunan, isEmpty, reason: 'Hassas ekranda reklam: $bulunan');
      });
    }

    test('web/index.html içinde AdSense betiği yok (Flutter web reklam yüklemesin)', () {
      final f = File('web/index.html');
      if (!f.existsSync()) return;
      expect(f.readAsStringSync().contains('adsbygoogle.js'), isFalse);
    });
  });
}
