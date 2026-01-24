import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/web_nav_bar.dart';
import '../../../../../shared/navigation/providers/navigation_keys.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../../shared/widgets/global_error_widget.dart';
import '../../../../shows/presentation/providers/show_provider.dart';
import '../../providers/home_asset_video_provider.dart';

class AppHomePage extends ConsumerStatefulWidget {
  final bool startAnimations;

  const AppHomePage({super.key, this.startAnimations = false});

  @override
  ConsumerState<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends ConsumerState<AppHomePage> {
  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showsProvider(isLimit: false));
    final videoState = ref.watch(homeAssetsProvider);

    // Eğer veri çekme işlemi tamamen çöktüyse (Network hatası vb.)
    if (showState.hasError)
      return GlobalErrorWidget(
        message: "Sunucuya bağlanılamadı.",
        onRetry: () => ref.invalidate(showsProvider),
      );

    return Scaffold(
      body: WebBar(
          key: NavigationKeys.webBarKey,
          startAnimations: widget.startAnimations),
    );
  }
}
