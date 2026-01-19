import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/enum/enums.dart';
import '../ads_manager.dart';
import '../ads_remote_config.dart';

class AdNativeWidget extends StatefulWidget {
  final double height;

  const AdNativeWidget({super.key, this.height = 110});

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Web'de Native reklam desteği olmadığı için sadece mobilde yükle
    if (!kIsWeb) _load();
  }

  void _load() => _ad = NativeAd(
        adUnitId: AdManager.getAdUnitId(AdUnitType.native),
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (final _) => setState(() => _loaded = true),
          onAdFailedToLoad: (final ad, final error) {
            debugPrint('Native Reklam Hatası: ${error.message}');
            ad.dispose();
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          cornerRadius: 16,
          mainBackgroundColor: Colors.white,
        ),
      )..load();

  @override
  Widget build(final BuildContext context) => ReactiveAdWrapper(
        child: Builder(
          builder: (final context) {
            if (kIsWeb || !_loaded || _ad == null)
              return const SizedBox.shrink();

            return SizedBox(
              height: widget.height,
              child: AdWidget(ad: _ad!),
            );
          },
        ),
      );

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }
}
