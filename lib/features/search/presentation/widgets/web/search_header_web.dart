import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

// =============================================================================
// MASAÜSTÜ ARAMA GİRİŞ (HERO) BÖLÜMÜ
// =============================================================================

/// Sayfanın en üstünde, "Apple/Spotlight" tarzı büyük ve editoryal bir
/// giriş bloğu. Pinned arama çubuğunun üstünde yer alır, aşağı kaydırıldıkça
/// sahneden çıkar.
class SearchHeroIntro extends StatelessWidget {
  const SearchHeroIntro({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 48, bottom: 44),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 2, width: 36, color: WebColors.primaryGold),
                    const SizedBox(width: 16),
                    const Text(
                      'KEŞFET',
                      style: TextStyle(
                        color: WebColors.primaryGold,
                        fontSize: 13,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 2, width: 36, color: WebColors.primaryGold),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Sanat Serüvenine\nBaşla',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 56,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: WebColors.whiteText,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Oyunları, sanatçıları, mekanları ve ekipleri tek bir sahneden keşfet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: WebColors.textSecondary,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// =============================================================================
// MASAÜSTÜ ARAMA KUTUSU
// =============================================================================

/// Büyük, ortalanmış, "gerçek bir web sitesi" hissi veren arama alanı.
/// Odaklanınca mercan (coral) rengiyle parlayan ince bir çerçeve/gölge alır.
class DesktopSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onSubmitted;
  final String hintText;

  const DesktopSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  State<DesktopSearchField> createState() => _DesktopSearchFieldState();
}

class _DesktopSearchFieldState extends State<DesktopSearchField> {
  bool _hasFocus = false;

  @override
  Widget build(final BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _hasFocus
                      ? WebColors.primaryGold.withOpacity(0.85)
                      : WebColors.primaryGold.withOpacity(0.22),
                  width: _hasFocus ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        WebColors.primaryGold.withOpacity(_hasFocus ? 0.28 : 0.12),
                    blurRadius: _hasFocus ? 38 : 22,
                    spreadRadius: _hasFocus ? 2 : 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Focus(
                onFocusChange: (final f) {
                  if (mounted) setState(() => _hasFocus = f);
                },
                child: TextField(
                  controller: widget.controller,
                  autofocus: true,
                  onChanged: widget.onChanged,
                  onSubmitted: (final _) => widget.onSubmitted?.call(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    color: WebColors.whiteText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: WebColors.primaryGold,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: WebColors.textTertiary,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: WebColors.primaryGold, size: 26),
                    suffixIcon: widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: WebColors.textSecondary, size: 20),
                            onPressed: widget.onClear,
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// =============================================================================
// MASAÜSTÜ FİLTRE SEKMELERİ
// =============================================================================

/// Bir filtre sekmesi. [colors] o kategorinin "Çam & Mercan" paletinden
/// gelen [açık, koyu] tonu — seçiliyken gradyan, seçili değilken ince bir
/// kenarlık/etiket rengi olarak kullanılır. Böylece masaüstü filtre çubuğu
/// da mobildeki chip'lerle aynı kategori kimliğini taşır (örn. "Mekanlar"
/// her iki yüzeyde de aynı yeşil tonu alır).
class DesktopFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const DesktopFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? LinearGradient(colors: colors) : null,
              color: isSelected ? null : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? Colors.transparent : colors[0].withOpacity(0.3),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: colors[1].withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6)),
                    ]
                  : const [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? WebColors.veryDarkBlue : WebColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
}

/// Ortalanmış, sarmalanabilen (Wrap) masaüstü filtre çubuğu. Mobildeki yatay
/// kaydırmalı chip listesinin aksine, geniş ekranda tüm filtreler tek satırda
/// (gerekirse iki satıra sararak) rahatça görünür.
///
/// [palettes], her etiket için `SearchCategoryPalette.tints` sırasıyla eşleşen
/// [açık, koyu] renk çiftlerinin listesidir.
class DesktopFilterTabs extends StatelessWidget {
  final List<String> labels;
  final List<List<Color>> palettes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const DesktopFilterTabs({
    super.key,
    required this.labels,
    required this.palettes,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) => Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 10,
          children: List.generate(
            labels.length,
            (final i) => DesktopFilterChip(
              label: labels[i],
              isSelected: selectedIndex == i,
              colors: palettes[i % palettes.length],
              onTap: () => onSelect(i),
            ),
          ),
        ),
      );
}
