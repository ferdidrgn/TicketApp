import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Riverpod Eklendi

import '../data/providers/home_web/home_asset_video_provider.dart';
import '../presentation/web/navigation/widgets/main_scaffold.dart';

// ✅ StatefulWidget -> ConsumerStatefulWidget dönüşümü
class AppHomePage extends ConsumerStatefulWidget {
  final bool startAnimations;

  const AppHomePage({
    super.key,
    this.startAnimations = false,
  });

  @override
  ConsumerState<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends ConsumerState<AppHomePage> {
  // Başlangıçta animasyonlar KAPALI
  bool _animationsStarted = false;

  @override
  void initState() {
    super.initState();
    // Eğer dışarıdan (Router'dan) özel bir istek gelmediyse,
    // animasyon kontrolünü provider dinleyerek yapacağız.
  }

  @override
  Widget build(final BuildContext context) {
    // 1. Videonun (veya sayfanın) yüklenme durumunu izle
    final videoState = ref.watch(homeAssetsProvider);

    // 2. Logic: Video Hazırsa + Animasyon henüz başlamadıysa
    if (videoState.isVideoReady && !_animationsStarted) {
      // Splash'in fade-out (kaybolma) süresi yaklaşık 800ms'dir.
      // Animasyonların tam splash bittikten sonra, temiz bir şekilde başlaması için
      // süreyi 500ms'den 900ms'ye çıkardık. Böylece perde tamamen kalkmış olur.
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _animationsStarted = true;
          });
        }
      });
    }

    return Scaffold(
      // 🚀 ARTIK SENKRONİZE:
      // MainScaffold (ve içindeki HomePage), veriler yüklenip Splash
      // kalkana kadar "false" sinyali alacak.
      // Splash kalktığı an "true" sinyali gidecek ve animasyonlar GÖZÜNÜN ÖNÜNDE başlayacak.
      body: MainScaffold(
        startAnimations: _animationsStarted,
      ),
    );
  }
}
