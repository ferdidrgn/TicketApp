import 'package:flutter/material.dart';

import '../../core/common/extentions/app_context_ui_extension.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Arama sayfasını açan sakin "arama kutusu" düğmesi (ana sayfa veya
/// AppBar). Eskiden sürekli nabız atan, parlayan, buzlu camlı bir kutuydu;
/// artık temanın yüzeyinde ince çerçeveli bir alan — hover'da çerçeve
/// koyulaşır, klavye odağında vurgu rengine döner. Genel API aynı.
class CustomSearchbar extends StatefulWidget {
  final VoidCallback onTap;
  final String hintText;
  final bool isCompact;

  const CustomSearchbar({
    super.key,
    required this.onTap,
    this.hintText = "Tiyatro, konser, sanatçı ara...",
    this.isCompact = false,
  });

  @override
  State<CustomSearchbar> createState() => _CustomSearchbarState();
}

class _CustomSearchbarState extends State<CustomSearchbar> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final bool compact = widget.isCompact;
    final double height = compact ? 48 : 56;
    final Color border = _focused
        ? cs.primary
        : (_hovered ? cs.outline : cs.outlineVariant);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : AppSpacing.xl,
        vertical: compact ? 0 : AppSpacing.md,
      ),
      child: Semantics(
        button: true,
        label: widget.hintText,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: border, width: _focused ? 2 : 1),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (final v) => setState(() => _hovered = v),
              onFocusChange: (final v) => setState(() => _focused = v),
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.md : AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: cs.onSurfaceVariant, size: compact ? 20 : 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.hintText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
