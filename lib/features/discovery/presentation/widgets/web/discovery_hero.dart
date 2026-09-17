import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

/// Keşif sayfasının masaüstü sürümü için sinematik/editoryal giriş bloğu.
/// Mobilin sıkışık uygulama çubuğu yerine, büyük başlık tipografisi ve
/// solda/sağda nefes alan bir "aktif oyun sayısı" rozetiyle Apple.com
/// tarzı bir güven veren giriş hissi verir.
class DiscoveryHero extends StatelessWidget {
  final String? categoryLabel;
  final int showCount;

  /// true iken "Geçmiş Oyunlar" (arşiv) moduna özel metinler/etiket
  /// gösterilir — aynı bileşen hem aktif hem geçmiş tarama görünümünde
  /// yeniden kullanılır.
  final bool archiveMode;

  const DiscoveryHero({
    super.key,
    this.categoryLabel,
    required this.showCount,
    this.archiveMode = false,
  });

  @override
  Widget build(final BuildContext context) {
    final String eyebrow = categoryLabel != null
        ? categoryLabel!.toUpperCase()
        : (archiveMode ? 'ARŞİV' : 'REPERTUAR');
    final String headline = categoryLabel ??
        (archiveMode ? 'Geçmiş\nOyunlar' : 'Sahnede\nSeni Bekleyenler');
    final String lede = categoryLabel != null
        ? (archiveMode
            ? '"$categoryLabel" kategorisinde sahnelenmiş, perdesi artık kapanmış oyunları keşfet.'
            : '"$categoryLabel" kategorisindeki oyunları keşfet, biletini dakikalar içinde ayırt.')
        : (archiveMode
            ? 'Takviminde artık gelecek etkinliği kalmamış prodüksiyonların '
                'arşivine göz at; her biri bir zamanlar sahnedeydi.'
            : 'Küratörlerimizin özenle seçtiği prodüksiyonlar arasında dolaş; '
                'her perde farklı bir hikâye anlatıyor.');

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final bool stacked = constraints.maxWidth < 760;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 2, color: WebColors.primaryGold),
                const SizedBox(width: 14),
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 1.02,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                lede,
                style: TextStyle(
                  color: WebColors.textSecondary,
                  fontSize: 16.5,
                  height: 1.7,
                ),
              ),
            ),
          ],
        );

        final badge = _CountBadge(count: showCount, archiveMode: archiveMode);

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 28),
              badge,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 7, child: titleBlock),
            const SizedBox(width: 32),
            Expanded(flex: 3, child: Align(alignment: Alignment.bottomRight, child: badge)),
          ],
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool archiveMode;

  const _CountBadge({required this.count, this.archiveMode = false});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              archiveMode ? 'GEÇMİŞ OYUN' : 'AKTİF OYUN',
              style: TextStyle(
                color: WebColors.primaryGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
}
