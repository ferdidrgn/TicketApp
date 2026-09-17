import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

/// Premium keşif kartı: posterin üzerine gelindiğinde (hover) ikinci bir
/// prodüksiyon fotoğrafına yumuşakça geçer ve özet/CTA metni yukarı kayarak
/// belirir. `landing/style.css`'teki `.show`/`.show__img--secondary` ve
/// `.show__desc` hover davranışının Flutter karşılığıdır
/// (bkz. `landing/index.html` "Repertuar" bölümü).
///
/// Boyuttan bağımsızdır: ebeveyn tarafından verilen kısıtlara (SizedBox,
/// AspectRatio, GridView hücresi vb.) göre şekillenir, böylece hem yatay
/// "öne çıkanlar" şeridinde hem de ızgara görünümünde yeniden kullanılabilir.
class DiscoveryShowCard extends StatefulWidget {
  final String imageUrl;
  final String? secondaryImageUrl;
  final String title;
  final String category;
  final String description;
  final VoidCallback onTap;
  final double borderRadius;
  final double titleFontSize;

  const DiscoveryShowCard({
    super.key,
    required this.imageUrl,
    this.secondaryImageUrl,
    required this.title,
    required this.category,
    this.description = '',
    required this.onTap,
    this.borderRadius = 20,
    this.titleFontSize = 19,
  });

  @override
  State<DiscoveryShowCard> createState() => _DiscoveryShowCardState();
}

class _DiscoveryShowCardState extends State<DiscoveryShowCard> {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);

  bool get _hasSecondary =>
      widget.secondaryImageUrl != null &&
      widget.secondaryImageUrl!.isNotEmpty &&
      widget.secondaryImageUrl != widget.imageUrl;

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onEnter: (final _) => _isHovered.value = true,
        onExit: (final _) => _isHovered.value = false,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isHovered,
            builder: (final context, final isActive, final staticChild) =>
                AnimatedScale(
              scale: isActive ? 1.025 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? WebColors.primaryGold.withOpacity(0.35)
                          : Colors.black.withOpacity(0.35),
                      blurRadius: isActive ? 32 : 16,
                      spreadRadius: isActive ? 1 : 0,
                      offset: Offset(0, isActive ? 18 : 8),
                    ),
                  ],
                ),
                child: staticChild,
              ),
            ),
            child: _buildContent(context),
          ),
        ),
      );

  Widget _buildContent(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. POSTER <-> İKİNCİL FOTOĞRAF (hover'da çapraz geçiş)
            ValueListenableBuilder<bool>(
              valueListenable: _isHovered,
              builder: (final context, final isActive, final _) {
                final bool showSecondary = isActive && _hasSecondary;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: OptimizedCachedImage(
                    key: ValueKey(
                        showSecondary ? widget.secondaryImageUrl : widget.imageUrl),
                    imageUrl:
                        showSecondary ? widget.secondaryImageUrl! : widget.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                );
              },
            ),

            // 2. ALT GRADIENT + KENARLIK
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovered,
                builder: (final context, final isActive, final _) =>
                    AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: isActive
                          ? WebColors.primaryGold.withOpacity(0.7)
                          : WebColors.primaryGold.withOpacity(0.18),
                      width: isActive ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(isActive ? 0.88 : 0.72),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. METİN + HOVER'DA BELİREN ÖZET/CTA
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: WebColors.goldGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.category.toUpperCase(),
                      style: const TextStyle(
                        color: WebColors.darkBlueBackground,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.titleFontSize,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isHovered,
                    builder: (final context, final isActive, final _) =>
                        AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: isActive
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild:
                          const SizedBox(width: double.infinity, height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.description.isNotEmpty)
                              Text(
                                widget.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Detayları Gör',
                                  style: TextStyle(
                                    color: WebColors.primaryGoldLight,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded,
                                    color: WebColors.primaryGold, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
