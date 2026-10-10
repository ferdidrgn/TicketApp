import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/rive/stage_tone_player.dart';
import '../../../../shared/widgets/rive/tiyatrol_rive.dart';

/// Ayarlar → Enstrüman Sahnesi.
/// Family of G + kedi piyanosu Rive animasyonları; dokunuşta ses çıkar.
class InstrumentStagePage extends StatefulWidget {
  const InstrumentStagePage({super.key});

  @override
  State<InstrumentStagePage> createState() => _InstrumentStagePageState();
}

enum _InstrumentTab { family, piano }

class _InstrumentStagePageState extends State<InstrumentStagePage> {
  _InstrumentTab _tab = _InstrumentTab.family;

  static const String _familyAsset = 'assets/9950-18973-family-of-g.riv';
  static const String _pianoAsset =
      'assets/18845-37092-play-piano-with-my-cat.riv';

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = context.colors;
    final bool desk = context.isDesktop;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            desk ? AppSpacing.xxxl : AppSpacing.lg,
            AppSpacing.sm,
            desk ? AppSpacing.xxxl : AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enstrüman sahnesi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Animasyona dokun — notalar çalar. Perde arasını hafif tut.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _TabChip(
                      selected: _tab == _InstrumentTab.family,
                      label: 'Müzik ailesi',
                      icon: Icons.music_note_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _tab = _InstrumentTab.family);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TabChip(
                      selected: _tab == _InstrumentTab.piano,
                      label: 'Kedi piyanosu',
                      icon: Icons.piano_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _tab = _InstrumentTab.piano);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: desk ? AppSpacing.xxxl : AppSpacing.lg,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: _tab == _InstrumentTab.family
                      ? _PlaySurface(
                          key: const ValueKey('family'),
                          asset: _familyAsset,
                          piano: false,
                          hint: 'Enstrümana dokun',
                        )
                      : _PlaySurface(
                          key: const ValueKey('piano'),
                          asset: _pianoAsset,
                          piano: true,
                          hint: 'Tuşlara / kediye dokun',
                        ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            desk ? AppSpacing.xxxl : AppSpacing.lg,
            AppSpacing.lg,
            desk ? AppSpacing.xxxl : AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Row(
            children: [
              LiquidRiveButton(
                label: 'Nota çal',
                icon: Icons.graphic_eq_rounded,
                onTap: () => StageTonePlayer.instance
                    .playNext(piano: _tab == _InstrumentTab.piano),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  _tab == _InstrumentTab.piano
                      ? 'Piyano animasyonu + sentez nota'
                      : 'Müzik ailesi animasyonu + sentez nota',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (desk) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Enstrüman sahnesi'),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
        ),
        body: SafeArea(child: body),
      );
    }

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      title: 'Enstrüman sahnesi',
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: body,
    );
  }
}

class _TabChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TabChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color:
                        selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaySurface extends StatelessWidget {
  final String asset;
  final bool piano;
  final String hint;

  const _PlaySurface({
    super.key,
    required this.asset,
    required this.piano,
    required this.hint,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (final _) =>
              StageTonePlayer.instance.playNext(piano: piano),
          child: TiyatrolRive(
            asset: asset,
            fit: BoxFit.contain,
            hitTest: true,
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
