import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Projede GERÇEKTEN duran Rive dosyaları (`assets/rive/`).
///
/// Çoğu animasyon Rive gerektirmez — `stage_moments.dart` (gül, üç gong),
/// `sahne_kit.dart` (Reveal, PressScale), `confetti`, `AuthWipeReveal`
/// Flutter ile çalışır. Rive yalnızca hazır vektör sahne istediğimizde.
///
/// Marketplace `.riv` (like/bell/clock…) henüz indirilmedi; sabitleri
/// eklemeden önce dosyayı `assets/rive/` altına koy.
abstract final class TiyatrolRiveAssets {
  static const String loader = 'assets/rive/loader.riv';
  static const String vehicles = 'assets/rive/vehicles.riv';
  static const String avatar = 'assets/rive/2195-4346-avatar-pack-use-case.riv';
}

/// Temaya uyumlu, azaltılmış harekette duran küçük Rive yüzeyi.
class TiyatrolRive extends StatefulWidget {
  final String asset;
  final double? width;
  final double? height;
  final Fit fit;

  const TiyatrolRive({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = Fit.contain,
  });

  @override
  State<TiyatrolRive> createState() => _TiyatrolRiveState();
}

class _TiyatrolRiveState extends State<TiyatrolRive> {
  @override
  Widget build(final BuildContext context) {
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: reduce
          ? Icon(Icons.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary, size: 28)
          : RiveWidgetBuilder(
              fileLoader: FileLoader.fromAsset(
                widget.asset,
                riveFactory: Factory.rive,
              ),
              builder: (final context, final state) => switch (state) {
                RiveLoading() => const SizedBox.shrink(),
                RiveFailed() => Icon(Icons.motion_photos_off_outlined,
                    color: Theme.of(context).colorScheme.outline, size: 22),
                RiveLoaded(:final controller) => RiveWidget(
                    controller: controller,
                    fit: widget.fit,
                  ),
              },
            ),
    );
  }
}

/// Kart köşesine / başlık yanına konan küçük Rive rozeti.
class TiyatrolRiveBadge extends StatelessWidget {
  final String asset;
  final double size;
  final String? semanticLabel;

  const TiyatrolRiveBadge({
    super.key,
    required this.asset,
    this.size = 36,
    this.semanticLabel,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: size + 12,
        height: size + 12,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: TiyatrolRive(asset: asset, width: size, height: size),
      ),
    );
  }
}

/// Yükleme / bekleyiş — `loader.riv` (yoksa / hata → sade ikon).
class TiyatrolRiveLoader extends StatelessWidget {
  final double size;
  final String? caption;

  const TiyatrolRiveLoader({super.key, this.size = 72, this.caption});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TiyatrolRive(
            asset: TiyatrolRiveAssets.loader,
            width: size,
            height: size,
          ),
          if (caption != null) ...[
            const SizedBox(height: 10),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
