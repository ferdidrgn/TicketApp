import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../features/shows/domain/entities/show.dart';
import 'optimized_cached_image.dart';

/// Tek, paylaşılan "tiyatro gösterisi" poster kartı.
///
/// Hem web ana sayfasının "Sahnede Bu Sezon" ızgarasında hem de keşif
/// sayfasının kart ızgarasında kullanılan, iki ayrı-ama-neredeyse-aynı
/// kart uygulamasının yerine geçen TEK kaynak. Amaç: iki ızgara da aynı
/// görünüp aynı davransın.
///
/// Hover'da (masaüstü/fare) `show.photosShowId` doluysa, kart bağlanırken
/// bir kez rastgele seçilmiş (mount süresince sabit kalan — her hover'da
/// yeniden ZAR ATILMAZ) bir galeri fotoğrafını, `page_transitions.dart`
/// içindeki `curtainTransition`'ın aynı "perde açılışı" tekniğiyle
/// (`ClipRect` + ortadan büyüyen `Align(widthFactor: ...)`) posterin
/// üzerine açar. `photosShowId` boşsa sadece kaldırma/parlama/kenarlık
/// hover efektleri uygulanır, görsel değişmez — asla kırık/boş görsel
/// göstermez ya da uydurma bir yedek kullanmaz.
class TheatreShowCard extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const TheatreShowCard({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  State<TheatreShowCard> createState() => _TheatreShowCardState();
}

class _TheatreShowCardState extends State<TheatreShowCard> {
  bool _hovered = false;

  /// Bu kart örneği bağlı kaldığı sürece sabit kalan, bir kez seçilmiş
  /// "sürpriz" galeri fotoğrafı. `photosShowId` boşsa null kalır.
  String? _revealImageUrl;

  /// "Yaprak/taç yaprağı" köşesi — kartın kısa kenarının ~%40-60'ı kadar
  /// büyük TEK bir köşe (sağ-üst), diğer üç köşe ise tutarlılık için
  /// mevcut `AppRadius` ölçeğinden. Kasıtlı olarak düz dairesel
  /// `Radius.circular` — özel bir `ClipPath`/bezier eğrisi DEĞİL (bu
  /// oturumda render önizlemesi yok, elle çizilmiş bir path hatalı
  /// görünüp yakalanamayabilir). Kart, ızgara hücresinden daha küçükse
  /// Flutter bu yarıçapı otomatik olarak kutuya sığacak şekilde ölçekler,
  /// bu yüzden büyük bir değer seçmek güvenlidir.
  static const double _petalCorner = 72;

  static const BorderRadius _petalRadius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.xs),
    topRight: Radius.circular(_petalCorner),
    bottomLeft: Radius.circular(AppRadius.xs),
    bottomRight: Radius.circular(AppRadius.sm),
  );

  /// Görsel alanının iç kırpması: dış çerçeveyle aynı köşe dili ama 1px
  /// içeride (kenarlığın hemen içinde) ve sadece üst iki köşe — alt kenar
  /// görselin altındaki metin bandına bitiştiği için köşeli kalmalı,
  /// tıpkı orijinal uygulamadaki gibi.
  static const BorderRadius _petalRadiusInner = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.xs - 1),
    topRight: Radius.circular(_petalCorner - 1),
  );

  @override
  void initState() {
    super.initState();
    final photos = widget.show.photosShowId;
    if (photos.isNotEmpty) {
      _revealImageUrl = photos[Random().nextInt(photos.length)];
    }
  }

  @override
  Widget build(final BuildContext context) {
    final show = widget.show;
    final hasReveal =
        _revealImageUrl != null && _revealImageUrl != show.imageUrl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: _petalRadius,
            border: Border.all(
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.45)
                  : WebColors.darkBlueAccent,
              width: 1.2,
            ),
            boxShadow: _hovered
                ? AppShadows.level3(WebColors.primaryGold)
                : AppShadows.level2(WebColors.primaryGold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: _petalRadiusInner,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Ana poster (her zaman görünür taban katman).
                      OptimizedCachedImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),

                      // 2. Hover'da "perde açılışı" ile beliren galeri
                      // fotoğrafı — sadece gerçek galeri verisi varsa.
                      if (hasReveal)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: _hovered ? 1.0 : 0.0,
                          ),
                          duration: AppMotion.normal,
                          curve: AppMotion.dramatic,
                          builder: (final context, final t, final child) {
                            if (t <= 0) return const SizedBox.shrink();
                            return ClipRect(
                              child: Align(
                                alignment: Alignment.center,
                                widthFactor: t,
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox.expand(
                            child: OptimizedCachedImage(
                              imageUrl: _revealImageUrl!,
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            ),
                          ),
                        ),

                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: WebColors.veryDarkBlue.withOpacity(0.72),
                            borderRadius: AppRadius.asymSm,
                            border: Border.all(
                              color: WebColors.primaryGold.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            show.category.toUpperCase(),
                            style: const TextStyle(
                              color: WebColors.primaryGoldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 🔥 DÜZELTME: Ne `show.duration` ("2 perde / 145dk"
                    // gibi) ne de `show.ageLimit` metni hiçbir esnek/ellipsis
                    // koruması olmadan sabit bir Row'a yazılıyordu — kart dar
                    // ekranlarda (ör. ana sayfa mobil şeridi) bu iki metin
                    // birlikte sığmayınca "RenderFlex overflowed" hatasıyla
                    // sağdan taşıyordu. Süre metni (daha değişken/uzun
                    // olan) artık Flexible + ellipsis; yaş sınırı rozeti de
                    // aynı korumayla güvence altına alındı.
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: WebColors.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            show.duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (show.ageLimit.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.shield_outlined,
                              size: 13, color: WebColors.textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              show.ageLimit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WebColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
