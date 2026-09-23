import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

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

  /// Tam-genişlik, nefes alan bir fotoğraf zemini — GERÇEK bir oyunun
  /// `photosShowId`'sinden (yoksa `imageUrl`'inden) ÇAĞIRANIN (bkz.
  /// `discovery_page.dart` `_DiscoveryDesktopBrowserState._pickHeroBackdrop`)
  /// bir KEZ rastgele seçtiği fotoğraf — `theatre_show_card.dart`'taki
  /// "initState'te bir kez seç, sonra sabit kal" ilkesiyle aynı. null/boş
  /// ise (gerçek bir görsel yoksa) sessizce eski, fotoğrafsız düzene düşer
  /// — asla uydurma bir görsel göstermez.
  final String? backdropImageUrl;

  const DiscoveryHero({
    super.key,
    this.categoryLabel,
    required this.showCount,
    this.archiveMode = false,
    this.backdropImageUrl,
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

    final Widget content = LayoutBuilder(
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

    final bool hasBackdrop =
        backdropImageUrl != null && backdropImageUrl!.isNotEmpty;

    // Gerçek bir arka plan fotoğrafı yoksa (ör. hiçbir oyunun ne galerisi
    // ne de afişi varsa — pratikte olmaz ama savunmacı davranıyoruz) sade,
    // fotoğrafsız eski düzene sessizce düşer.
    if (!hasBackdrop) return content;

    // Referans lüks/editoryal sitelerdeki "büyük, tek güçlü, nefes alan
    // görsel" hissi: gerçek fotoğraf zemini + okunurluğu garanti eden çift
    // yönlü koyu "scrim" (bkz. `home_page_web.dart`'taki `_HeroBackdropPhoto`
    // ile AYNI teknik) + bol iç boşluk (`AppSpacing.section`).
    return ClipRRect(
      borderRadius: AppRadius.asymLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: AppShadows.level4(WebColors.veryDarkBlue),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: OptimizedCachedImage(
                imageUrl: backdropImageUrl!,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),
            // Yatay scrim: metnin durduğu sol taraf koyu, sağ taraf
            // (rozetin arkası) fotoğrafın nefes almasına izin verecek
            // kadar açık.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      WebColors.veryDarkBlue.withOpacity(0.95),
                      WebColors.veryDarkBlue.withOpacity(0.8),
                      WebColors.veryDarkBlue.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Dikey scrim: üst/alt kenarlarda ek okunurluk.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      WebColors.veryDarkBlue.withOpacity(0.45),
                      Colors.transparent,
                      WebColors.veryDarkBlue.withOpacity(0.55),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl,
                  AppSpacing.section, AppSpacing.xxxl, AppSpacing.section),
              child: content,
            ),
          ],
        ),
      ),
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
