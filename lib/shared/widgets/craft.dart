import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Skill: 48dp hedef, basınca ölçek + haptiği, azaltılmış harekette durur.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.label,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(final BuildContext context) {
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final Widget scaled = AnimatedScale(
      scale: _down && !reduce ? 0.98 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: widget.child,
    );
    if (widget.onTap == null) return scaled;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: widget.label != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (final _) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (final _) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: scaled,
      ),
    );
  }
}

/// Arama türleri: ikon + ad, en az 48×72, seçili yüzey temadan.
class CraftFacetRail extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const CraftFacetRail({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (final context, final i) {
          final bool on = i == selectedIndex;
          return Semantics(
            button: true,
            selected: on,
            label: labels[i],
            child: Material(
              color: on ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(i);
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 22,
                          color: on ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          labels[i],
                          style: TextStyle(
                            color: on ? cs.onPrimary : cs.onSurface,
                            fontSize: 11,
                            fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
