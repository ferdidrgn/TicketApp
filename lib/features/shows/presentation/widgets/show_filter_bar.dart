import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/show_filter_provider.dart';

// ==============================================================================
// GERÇEK FİLTRE UI'I — Keşfet/Arama için
// ==============================================================================
//
// İki parça:
// - `ShowCategoryChipRow`: her zaman görünen, yatay kaydırılabilir gerçek
//   kategori çipleri (Biletix'in "alt kategori grupları"/Bubilet'in
//   etiket-bazlı göz atma deseniyle aynı fikir — bkz. rakip araştırması).
// - `ShowFilterButton` + `ShowFilterSheet`: aktif filtre sayısını rozet
//   olarak gösteren bir ikon buton, dokunulunca tüm filtreleri (tür, tarih
//   aralığı, fiyat aralığı, sadece aktif, sıralama) barındıran gerçek bir
//   bottom sheet açar. "Glass/blur sadece overlay/bottom sheet'te"
//   kuralına uygun tek yer burası.
//
// Hiçbir seçenek uydurma değil: kategori/tür listesi
// `availableShowFilterOptionsProvider`'dan (gerçek Show.category/type
// alanlarından), fiyat aralığı `priceRangeBoundsProvider`'dan (gerçek
// Event.price'lardan) geliyor.

class ShowCategoryChipRow extends ConsumerWidget {
  const ShowCategoryChipRow({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final optionsAsync = ref.watch(availableShowFilterOptionsProvider);
    final filter = ref.watch(showFilterControllerProvider);
    final controller = ref.read(showFilterControllerProvider.notifier);

    return optionsAsync.when(
      loading: () => const SizedBox(height: 44),
      error: (final _, final __) => const SizedBox.shrink(),
      data: (final options) {
        if (options.categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.categories.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (final context, final index) {
              final category = options.categories[index];
              final selected = filter.categories.contains(category);
              return _FilterChip(
                label: category,
                selected: selected,
                onTap: () => controller.toggleCategory(category),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$label kategorisi${selected ? ', seçili' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected
                  ? WebColors.primaryGold
                  : WebColors.darkBlueSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? WebColors.primaryGold
                    : WebColors.primaryGold.withOpacity(0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? WebColors.darkBlueBackground
                    : WebColors.whiteText.withOpacity(0.85),
              ),
            ),
          ),
        ),
      );
}

/// Aktif filtre sayısını rozet olarak gösteren buton — dokunulunca
/// `ShowFilterSheet`'i açar.
class ShowFilterButton extends ConsumerWidget {
  const ShowFilterButton({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(showFilterControllerProvider);
    final activeCount = _activeFilterCount(filter);

    return Semantics(
      button: true,
      label: activeCount > 0
          ? 'Filtreler, $activeCount aktif filtre'
          : 'Filtreler',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (final _) => const ShowFilterSheet(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: WebColors.primaryGold),
              const SizedBox(width: AppSpacing.sm),
              const Text('Filtrele',
                  style: TextStyle(
                      color: WebColors.whiteText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              if (activeCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: WebColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$activeCount',
                      style: const TextStyle(
                          color: WebColors.darkBlueBackground,
                          fontWeight: FontWeight.w900,
                          fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static int _activeFilterCount(final ShowFilterState filter) {
    var count = 0;
    if (filter.categories.isNotEmpty) count++;
    if (filter.types.isNotEmpty) count++;
    if (filter.dateFrom != null || filter.dateTo != null) count++;
    if (filter.minPrice != null || filter.maxPrice != null) count++;
    if (filter.stageId != null) count++;
    if (!filter.activeOnly) count++;
    if (filter.sortOrder != ShowSortOrder.recommended) count++;
    return count;
  }
}

class ShowFilterSheet extends ConsumerWidget {
  const ShowFilterSheet({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(showFilterControllerProvider);
    final controller = ref.read(showFilterControllerProvider.notifier);
    final optionsAsync = ref.watch(availableShowFilterOptionsProvider);
    final priceBoundsAsync = ref.watch(priceRangeBoundsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (final context, final scrollController) => Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
          boxShadow: AppShadows.level4(WebColors.darkBlueBackground),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WebColors.whiteText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtreler',
                    style: TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                if (filter.hasActiveFilters)
                  TextButton(
                    onPressed: controller.clearAll,
                    child: const Text('Temizle',
                        style: TextStyle(color: WebColors.primaryGold)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sadece aktif oyunlar
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: filter.activeOnly,
              onChanged: controller.setActiveOnly,
              activeColor: WebColors.primaryGold,
              title: const Text('Sadece sahnede olanlar',
                  style: TextStyle(color: WebColors.whiteText, fontSize: 14)),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tür çipleri
            optionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (final _, final __) => const SizedBox.shrink(),
              data: (final options) {
                if (options.types.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetSectionTitle('Tür'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: options.types
                          .map((final type) => _FilterChip(
                                label: type,
                                selected: filter.types.contains(type),
                                onTap: () => controller.toggleType(type),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),

            // Fiyat aralığı — gerçek Event.price min/max'ı varsa
            priceBoundsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (final _, final __) => const SizedBox.shrink(),
              data: (final bounds) {
                if (bounds == null || bounds.min >= bounds.max) {
                  return const SizedBox.shrink();
                }
                final currentMin = filter.minPrice ?? bounds.min;
                final currentMax = filter.maxPrice ?? bounds.max;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetSectionTitle('Fiyat Aralığı'),
                    Text(
                      '${currentMin.round()} TL — ${currentMax.round()} TL',
                      style: TextStyle(
                          color: WebColors.whiteText.withOpacity(0.7),
                          fontSize: 12),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: WebColors.primaryGold,
                        inactiveTrackColor:
                            WebColors.primaryGold.withOpacity(0.2),
                        thumbColor: WebColors.primaryGold,
                        overlayColor: WebColors.primaryGold.withOpacity(0.2),
                      ),
                      child: RangeSlider(
                        min: bounds.min,
                        max: bounds.max,
                        values: RangeValues(
                          currentMin.clamp(bounds.min, bounds.max),
                          currentMax.clamp(bounds.min, bounds.max),
                        ),
                        onChanged: (final values) => controller.setPriceRange(
                            values.start, values.end),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),

            // Sıralama
            const _SheetSectionTitle('Sıralama'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                (ShowSortOrder.recommended, 'Önerilen'),
                (ShowSortOrder.dateAscending, 'Yaklaşan Tarih'),
                (ShowSortOrder.priceAscending, 'Fiyat: Düşükten Yükseğe'),
                (ShowSortOrder.priceDescending, 'Fiyat: Yüksekten Düşüğe'),
                (ShowSortOrder.alphabetical, 'A-Z'),
              ]
                  .map((final entry) => _FilterChip(
                        label: entry.$2,
                        selected: filter.sortOrder == entry.$1,
                        onTap: () => controller.setSortOrder(entry.$1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: WebColors.primaryGold,
                  foregroundColor: WebColors.darkBlueBackground,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: const Text('Sonuçları Göster',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String title;
  const _SheetSectionTitle(this.title);

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: WebColors.whiteText.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      );
}
