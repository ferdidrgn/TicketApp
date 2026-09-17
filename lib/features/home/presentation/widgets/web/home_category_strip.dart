import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// "Kategoriler" şeridi — mobildeki `CategoryGrid`'in web karşılığı.
///
/// Aynı 4 sabit kategoriyi taşır (Tiyatro/Konser/Stand-up/Müze — mobil
/// tarafta da Firestore'dan değil sabit bir listeden geliyor, burada da
/// öyle: yeni bir veri uydurulmadı). Mobildeki pastel renk paleti yerine
/// marka renklerinden türetilmiş tonlar kullanılıyor, ve mobilin aksine
/// (orada dokunulamaz, sadece dekoratif) burada `/discover?category=...`
/// rotasına gidiyor — zaten var olan gerçek bir işlevsellik.
class HomeCategoryStrip extends StatelessWidget {
  final void Function(String category) onCategoryTap;

  const HomeCategoryStrip({super.key, required this.onCategoryTap});

  static const _categories = [
    // Aynı 4 sabit ikon/etiket, mobildeki category_grid.dart ile birebir
    // aynı (doğrulanmış) Icons sabitleri kullanılıyor.
    _CategoryData(icon: Icons.theater_comedy, label: 'Tiyatro'),
    _CategoryData(icon: Icons.music_note, label: 'Konser'),
    _CategoryData(icon: Icons.mic_external_on, label: 'Stand-up'),
    _CategoryData(icon: Icons.museum, label: 'Müze'),
  ];

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: _categories
            .map((final c) => _CategoryChip(
                  data: c,
                  onTap: () => onCategoryTap(c.label),
                ))
            .toList(),
      );
}

class _CategoryData {
  final IconData icon;
  final String label;

  const _CategoryData({required this.icon, required this.label});
}

class _CategoryChip extends StatefulWidget {
  final _CategoryData data;
  final VoidCallback onTap;

  const _CategoryChip({required this.data, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(4),
  );

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.10)
                  : WebColors.darkBlueSurface,
              borderRadius: _radius,
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.55)
                    : WebColors.darkBlueAccent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.data.icon,
                    size: 17,
                    color: _hovered
                        ? WebColors.primaryGoldLight
                        : WebColors.secondaryAccentLight),
                const SizedBox(width: 10),
                Text(
                  widget.data.label,
                  style: TextStyle(
                    color: _hovered
                        ? WebColors.whiteText
                        : WebColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
