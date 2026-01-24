import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/web_nav_bar.dart';
import '../../../../../shared/navigation/providers/navigation_keys.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../providers/home_asset_video_provider.dart';

class AppHomePage extends ConsumerStatefulWidget {
  final bool startAnimations;

  const AppHomePage({super.key, this.startAnimations = false});

  @override
  ConsumerState<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends ConsumerState<AppHomePage> {
  bool _animationsStarted = false;

  @override
  Widget build(final BuildContext context) {
    // 1. Sadece video provider'ını izliyoruz
    final videoState = ref.watch(homeAssetsProvider);

    if (videoState.isLoading) return const Scaffold(body: ArtisticWebShimmer());

    // 3. HATA DURUMU
    if (videoState.hasError)
      return Scaffold(body: _buildSimpleError(context, ref));

    // 4. ANIMASYON TETİKLEYİCİ
    if (videoState.hasValue &&
        videoState.value != null &&
        !_animationsStarted) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _animationsStarted = true);
      });
    }

    return Scaffold(
        body: WebBar(
            key: NavigationKeys.webBarKey,
            startAnimations: _animationsStarted));
  }

  Widget _buildSimpleError(final BuildContext context, final WidgetRef ref) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text("Video yüklenirken bir hata oluştu"),
            TextButton(
                onPressed: () => ref.invalidate(homeAssetsProvider),
                child: const Text("Tekrar Dene")),
          ],
        ),
      );
}
