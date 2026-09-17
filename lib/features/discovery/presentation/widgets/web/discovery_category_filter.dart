import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

/// Masaüstüne özel kategori filtresi: mobildeki yatay kaydırılan çip
/// listesi yerine, geniş ekranda daha "editoryal" duran, kendiliğinden
/// satır atlayan (Wrap) bir hap (pill) grubu kullanır. Kategoriler her
/// zaman gerçek `Show.category` verisinden türetilir.
class DiscoveryCategoryFilter extends StatelessWidget {
  final List<String> categories;

  /// null => "Tümü" seçili demektir.
  final String? selected;
  final ValueChanged<String?> onSelected;

  const DiscoveryCategoryFilter({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _CategoryPill(
            label: 'Tümü',
            isActive: selected == null,
            onTap: () => onSelected(null),
          ),
          ...categories.map(
            (final category) => _CategoryPill(
              label: category,
              isActive: selected == category,
              onTap: () => onSelected(category),
            ),
          ),
        ],
      );
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool highlight = widget.isActive || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            gradient: widget.isActive ? WebColors.goldGradient : null,
            color: widget.isActive
                ? null
                : (_hovered
                    ? WebColors.primaryGold.withOpacity(0.14)
                    : WebColors.darkBlueSurface.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlight
                  ? WebColors.primaryGold.withOpacity(widget.isActive ? 1 : 0.6)
                  : WebColors.primaryGold.withOpacity(0.22),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isActive
                  ? WebColors.darkBlueBackground
                  : WebColors.whiteText,
              fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
