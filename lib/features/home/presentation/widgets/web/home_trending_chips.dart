import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// "Şu An Popüler" — mobildeki `TrendingNowSection`'ın web karşılığı.
///
/// Mobil tarafta da bu liste sabit/dekoratif (Firestore'dan gelen gerçek
/// bir trend hesaplaması değil, tıklanabilir de değil) — aynı 6 etiket
/// birebir taşındı, yeni içerik uydurulmadı.
class HomeTrendingChips extends StatelessWidget {
  const HomeTrendingChips({super.key});

  static const _items = [
    '🎭 Tiyatro',
    '🎵 Konser',
    '🎤 Stand-up',
    '🎨 Sergi',
    '🎬 Sinema',
    '🎪 Festival',
  ];

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _items
            .map((final label) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: WebColors.darkBlueSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WebColors.darkBlueAccent),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
      );
}
