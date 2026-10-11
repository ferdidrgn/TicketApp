import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'browse_controls.dart';

/// Sol kenarda dikey (90°) tür şeridi — program kenarlığı metaforu.
/// Seçim animasyonlu; seçili satırda vurgu çizgisi kayar.
class DiscoverySpine extends StatelessWidget {
  final List<BrowseCategory> categories;
  final String? selectedKey;
  final int totalCount;
  final ValueChanged<String?> onPick;
  final double width;

  const DiscoverySpine({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.totalCount,
    required this.onPick,
    this.width = 52,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final items = <({String? key, String label, int count})>[
      (key: null, label: 'Tümü', count: totalCount),
      for (final c in categories)
        (key: c.key, label: c.label, count: c.count),
    ];

    return Semantics(
      label: 'Türler',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
          ),
        ),
        child: SizedBox(
          width: width,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (final context, final i) {
              final item = items[i];
              final bool selected = item.key == selectedKey;
              return _SpineCell(
                label: item.label,
                count: item.count,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPick(item.key);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SpineCell extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SpineCell({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color ink = selected ? cs.primary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count oyun',
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          height: 92,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              right: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: Curves.easeOutCubic,
                style: GoogleFonts.playfairDisplay(
                  color: ink,
                  fontSize: selected ? 14 : 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: selected ? 0.2 : 0,
                  height: 1.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// İnce zaman / sıralama şeridi — kocaman chip yok.
class DiscoveryPulseBar extends StatelessWidget {
  final BrowseWhen when;
  final Map<BrowseWhen, int> whenCounts;
  final ValueChanged<BrowseWhen> onWhen;
  final int sortIndex;
  final List<String> sortLabels;
  final ValueChanged<int> onSort;
  final bool showWhen;

  const DiscoveryPulseBar({
    super.key,
    required this.when,
    required this.whenCounts,
    required this.onWhen,
    required this.sortIndex,
    required this.sortLabels,
    required this.onSort,
    this.showWhen = true,
  });

  static const Map<BrowseWhen, IconData> _icons = {
    BrowseWhen.any: Icons.all_inclusive_rounded,
    BrowseWhen.tonight: Icons.nights_stay_rounded,
    BrowseWhen.tomorrow: Icons.wb_sunny_rounded,
    BrowseWhen.weekend: Icons.weekend_rounded,
    BrowseWhen.week: Icons.date_range_rounded,
  };

  static const Map<BrowseWhen, String> _labels = {
    BrowseWhen.any: 'Tümü',
    BrowseWhen.tonight: 'Akşam',
    BrowseWhen.tomorrow: 'Yarın',
    BrowseWhen.weekend: 'Hafta sonu',
    BrowseWhen.week: 'Hafta',
  };

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (showWhen)
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: BrowseWhen.values.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(width: 6),
                itemBuilder: (final context, final i) {
                  final BrowseWhen w = BrowseWhen.values[i];
                  final bool on = when == w;
                  final int? n = whenCounts[w];
                  return _PulseChip(
                    icon: _icons[w]!,
                    label: _labels[w]!,
                    count: w == BrowseWhen.any ? null : n,
                    selected: on,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onWhen(w);
                    },
                  );
                },
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () {
                HapticFeedback.selectionClick();
                onSort((sortIndex + 1) % sortLabels.length);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        sortLabels[sortIndex],
                        key: ValueKey(sortIndex),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _PulseChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label, $count',
      child: Material(
        color: selected ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 15,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected
                          ? cs.onPrimary.withValues(alpha: 0.85)
                          : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sahnede / Geçmiş — referanstaki segment gibi ince hap.
class DiscoveryModeSegment extends StatelessWidget {
  final bool showPast;
  final ValueChanged<bool> onChanged;

  const DiscoveryModeSegment({
    super.key,
    required this.showPast,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: 'Sahnede',
              selected: !showPast,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Seg(
              label: 'Geçmiş',
              selected: showPast,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
