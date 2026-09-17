import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../shows/domain/entities/show.dart';

/// Aktif kategori/filtre içindeki ilk oyunu, landing sayfasının asimetrik
/// editoryal düzenine benzer şekilde büyük bir "öne çıkan" pano olarak
/// sunar (büyük poster + başlık + özet + CTA).
class DiscoveryFeaturedShow extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const DiscoveryFeaturedShow({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  State<DiscoveryFeaturedShow> createState() => _DiscoveryFeaturedShowState();
}

class _DiscoveryFeaturedShowState extends State<DiscoveryFeaturedShow> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final show = widget.show;

    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface.withOpacity(0.55),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
              topRight: Radius.circular(52),
              bottomLeft: Radius.circular(52),
            ),
            border: Border.all(
              color: WebColors.primaryGold.withOpacity(_hovered ? 0.6 : 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: _hovered ? 44 : 26,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (final context, final constraints) {
              // Dar bir masaüstü kesitinde (ör. iki panel yan yana açıksa)
              // görsel/metin sıkışmasın diye alt alta düzene geçiyoruz.
              final bool stacked = constraints.maxWidth < 760;

              final poster = AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(44),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  child: AnimatedScale(
                    scale: _hovered ? 1.045 : 1.0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    child: OptimizedCachedImage(
                      imageUrl: show.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                ),
              );

              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 32, height: 2, color: WebColors.primaryGold),
                      const SizedBox(width: 12),
                      Text(
                        'HAFTANIN SEÇKİSİ',
                        style: TextStyle(
                          color: WebColors.primaryGoldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    show.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    show.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 15.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: WebColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: WebColors.primaryGold
                              .withOpacity(_hovered ? 0.55 : 0.25),
                          blurRadius: _hovered ? 28 : 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Detayları Gör',
                          style: TextStyle(
                            color: WebColors.darkBlueBackground,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: WebColors.darkBlueBackground, size: 18),
                      ],
                    ),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 260, child: poster),
                    const SizedBox(height: 32),
                    text,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: poster),
                  const SizedBox(width: 48),
                  Expanded(flex: 6, child: text),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
