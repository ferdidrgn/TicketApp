import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

/// Premium keşif kartı: posterin üzerine gelindiğinde (hover) ikinci bir
/// prodüksiyon fotoğrafına `lib/shared/widgets/theatre_show_card.dart` ile
/// AYNI "perde açılışı" tekniğiyle (bkz. `page_transitions.dart`
/// `curtainTransition`) geçer ve özet/CTA metni yukarı kayarak belirir.
/// `landing/style.css`'teki `.show`/`.show__img--secondary` ve
/// `.show__desc` hover davranışının Flutter karşılığıdır (bkz.
/// `landing/index.html` "Repertuar" bölümü).
///
/// Bu widget'ın kendi genel API'si (tekil `imageUrl`/`secondaryImageUrl`,
/// hover'da beliren `description` + CTA) `TheatreShowCard`'ınkinden
/// kasıtlı olarak farklı — çağıranları (`discovery_page.dart`) bir `Show`
/// değil, önceden seçilmiş ayrı alanlar veriyor ve bu kart açıklama/CTA
/// gösteriyor, `TheatreShowCard` ise süre/yaş sınırı gösteriyor. Bu yüzden
/// burada `TheatreShowCard`'a devretmek yerine AYNI tasarım dilini
/// (`AppMotion`, `AppShadows`, perde-açılışı hover geçişi, tek büyük
/// "taç yaprağı" köşe) kendi içinde uyguluyor — iki ızgara da görsel
/// olarak tutarlı, ama bu kartın kendine özgü açıklama/CTA davranışı
/// korunuyor.
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

  /// "Taç yaprağı" köşesi — `TheatreShowCard`'daki büyük köşeyle AYNI
  /// değer, iki kartın köşe dili tutarlı görünsün diye. Diğer üç köşe
  /// çağıranın verdiği `borderRadius`'u kullanır (varsayılan kullanım
  /// zaten `AppRadius.lg`'ye yakın).
  static const double _petalCorner = 72;

  bool get _hasSecondary =>
      widget.secondaryImageUrl != null &&
      widget.secondaryImageUrl!.isNotEmpty &&
      widget.secondaryImageUrl != widget.imageUrl;

  BorderRadius get _cardRadius => BorderRadius.only(
        topLeft: Radius.circular(widget.borderRadius),
        topRight: Radius.circular(_petalCorner),
        bottomLeft: Radius.circular(widget.borderRadius),
        bottomRight: Radius.circular(widget.borderRadius),
      );

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
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                // `TheatreShowCard`'daki hover'da hafif kaldırma
                // (`Matrix4.translationValues(0, -5, 0)`) ile AYNI teknik —
                // iki ızgaranın hover hissi tutarlı kalsın diye.
                transform: Matrix4.translationValues(0, isActive ? -6 : 0, 0),
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  boxShadow: isActive
                      ? AppShadows.level3(WebColors.primaryGold)
                      : AppShadows.level2(WebColors.primaryGold),
                ),
                child: staticChild,
              ),
            ),
            child: _buildContent(context),
          ),
        ),
      );

  Widget _buildContent(final BuildContext context) => ClipRRect(
        borderRadius: _cardRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ana poster (her zaman görünür taban katman).
            OptimizedCachedImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),

            // 2. Hover'da "perde açılışı" ile beliren ikincil fotoğraf —
            // `TheatreShowCard`'daki ClipRect + ortadan büyüyen
            // Align(widthFactor: ...) tekniğinin birebir aynısı.
            if (_hasSecondary)
              ValueListenableBuilder<bool>(
                valueListenable: _isHovered,
                builder: (final context, final isActive, final _) =>
                    TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isActive ? 1.0 : 0.0),
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
                      imageUrl: widget.secondaryImageUrl!,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                ),
              ),

            // 3. ALT GRADIENT + KENARLIK
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovered,
                builder: (final context, final isActive, final _) =>
                    AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  decoration: BoxDecoration(
                    borderRadius: _cardRadius,
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

            // 4. METİN + HOVER'DA BELİREN ÖZET/CTA
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
                      duration: AppMotion.fast,
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
