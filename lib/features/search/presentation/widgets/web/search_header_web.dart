import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/search/presentation/widgets/web/search_category_palette.dart';

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
// MASAÜSTÜ ARAMA + FİLTRE KOMUT ÇUBUĞU
// =============================================================================
//
// Önceki sürümde filtreler arama kutusunun ALTINDA, kendi gölgesi/kenarlığı
// olan ayrı bir "chip" satırıydı (DesktopFilterChip/DesktopFilterTabs —
// kaldırıldı). Kullanıcı geri bildirimi net: filtreler artık kendi başına
// yüzen pilller gibi DEĞİL, arama kutusuyla AYNI kabuğun bir parçası gibi
// görünmeli.
//
// Burada tek bir kabuk var: solda arama alanı, ince bir dikey ayraç, sağda
// segmentli bir kategori anahtarı (macOS Finder'ın görünüm anahtarına ya da
// bir editoryal sitenin sekme şeridine yakın bir dil) — tek bir kayan vurgu
// parçası seçili segmentin altında/arkasında hareket eder. Hiçbir segmentin
// kendi ayrı kenarlığı, gölgesi ya da hap şekli yok; hepsi tek kabuğun içinde
// erimiş durumda.
class DesktopSearchCommandBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onSubmitted;
  final String hintText;
  final int selectedIndex;
  final ValueChanged<int> onSelectFacet;

  const DesktopSearchCommandBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
    required this.selectedIndex,
    required this.onSelectFacet,
    this.onSubmitted,
  });

  @override
  State<DesktopSearchCommandBar> createState() =>
      _DesktopSearchCommandBarState();
}

class _DesktopSearchCommandBarState extends State<DesktopSearchCommandBar> {
  bool _hasFocus = false;

  @override
  Widget build(final BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              height: 68,
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface.withOpacity(0.85),
                // Marka köşe dili: keskin+yuvarlak çapraz kesim (bkz.
                // kSearchCardCorner) — tam hap şekli yerine.
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(40),
                  bottomRight: Radius.circular(22),
                  bottomLeft: Radius.circular(40),
                ),
                border: Border.all(
                  color: _hasFocus
                      ? WebColors.primaryGold.withOpacity(0.85)
                      : WebColors.primaryGold.withOpacity(0.22),
                  width: _hasFocus ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        WebColors.primaryGold.withOpacity(_hasFocus ? 0.26 : 0.1),
                    blurRadius: _hasFocus ? 34 : 20,
                    spreadRadius: _hasFocus ? 1 : 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
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
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: WebColors.primaryGold,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: const TextStyle(
                            color: WebColors.textTertiary,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: WebColors.primaryGold, size: 23),
                          suffixIcon: widget.controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: WebColors.textSecondary, size: 18),
                                  onPressed: widget.onClear,
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: WebColors.whiteText.withOpacity(0.1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DesktopSearchFacetSwitcher(
                      selectedIndex: widget.selectedIndex,
                      onSelect: widget.onSelectFacet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// =============================================================================
// MASAÜSTÜ SEGMENTLİ KATEGORİ ANAHTARI
// =============================================================================

/// Her segmentin sabit genişliği. Segment sayısı × bu değer, anahtarın
/// toplam (sabit) genişliğini verir — kayan vurgu parçası bu ızgaraya göre
/// konumlanır (`AnimatedPositioned` ile ölçüm/GlobalKey gerektirmeden).
const double _kFacetSegmentWidth = 78;

/// [DesktopSearchCommandBar]'ın sağ yarısını dolduran segmentli anahtar.
/// Tek bir kayan vurgu parçası (`AnimatedPositioned`) seçili segmentin
/// altına kayar; segmentlerin kendi ayrı arka planı/kenarlığı yoktur —
/// bu yüzden bir "chip listesi" değil, TEK bir kontrol gibi okunur.
class DesktopSearchFacetSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const DesktopSearchFacetSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    final labels = SearchCategoryPalette.switcherLabels;
    final icons = SearchCategoryPalette.icons;
    final tooltips = SearchCategoryPalette.labels;
    final int n = labels.length;
    final double totalWidth = _kFacetSegmentWidth * n;
    final accent = SearchCategoryPalette.tintFor(selectedIndex);

    return SizedBox(
      width: totalWidth,
      height: 52,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: _kFacetSegmentWidth * selectedIndex,
            width: _kFacetSegmentWidth,
            top: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: accent),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(6),
                  bottomLeft: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                      color: accent[1].withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                ],
              ),
            ),
          ),
          Row(
            children: List.generate(
              n,
              (final i) => SizedBox(
                width: _kFacetSegmentWidth,
                height: 52,
                child: _FacetSegmentButton(
                  icon: icons[i],
                  label: labels[i],
                  tooltip: tooltips[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacetSegmentButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _FacetSegmentButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FacetSegmentButton> createState() => _FacetSegmentButtonState();
}

class _FacetSegmentButtonState extends State<_FacetSegmentButton> {
  bool _hovered = false;

  void _setHovered(final bool value) {
    if (mounted) setState(() => _hovered = value);
  }

  @override
  Widget build(final BuildContext context) {
    final Color fg = widget.selected
        ? WebColors.veryDarkBlue
        : (_hovered ? WebColors.whiteText : WebColors.textTertiary);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => _setHovered(true),
        onExit: (final _) => _setHovered(false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.0 : (_hovered ? 1.1 : 1.0),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(widget.icon, size: 17, color: fg),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 0.4,
                  fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                ),
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
