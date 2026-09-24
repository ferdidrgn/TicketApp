import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/search/presentation/widgets/web/search_category_palette.dart';
import 'package:ticketapp/features/search/presentation/widgets/web/search_scroll_reveal.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

// =============================================================================
// KÖŞE DİLİ — landing/style.css'teki asimetrik `border-radius` motifinin
// (örn. `.show{border-radius:4px 28px 4px 28px}`, `.venue{border-radius:
// 4px 20px}`) Flutter karşılığı. Tek biçimli `BorderRadius.circular` yerine
// her yüzeyde aynı yönde (sol-üst/sağ-alt keskin, sağ-üst/sol-alt yuvarlak)
// köşegen bir kesim kullanılır — büyüklük hiyerarşiye göre değişir.
// =============================================================================

const BorderRadius kSearchCardCorner = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(28),
  bottomRight: Radius.circular(4),
  bottomLeft: Radius.circular(28),
);

const BorderRadius kSearchPlaceCorner = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(4),
  bottomLeft: Radius.circular(20),
);

const BorderRadius kSearchBadgeCorner = BorderRadius.only(
  topLeft: Radius.circular(2),
  topRight: Radius.circular(10),
  bottomRight: Radius.circular(2),
  bottomLeft: Radius.circular(10),
);

const BorderRadius kSearchIconCorner = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(16),
  bottomRight: Radius.circular(4),
  bottomLeft: Radius.circular(16),
);

// =============================================================================
// BÖLÜM BAŞLIĞI (show_detail_page_web.dart'daki _SectionTitle konvansiyonu)
// =============================================================================

class DesktopSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onSeeAll;

  /// Bölümün kategori tonu ([açık, koyu]) — verilmezse ana mercan
  /// gradyanına düşer ("Tümü" / genel kullanım).
  final List<Color>? accentColors;

  const DesktopSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onSeeAll,
    this.accentColors,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = accentColors ??
        const [WebColors.primaryGold, WebColors.primaryGoldLight];
    return Padding(
        padding: const EdgeInsets.only(bottom: 28, top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: kSearchIconCorner,
                boxShadow: [
                  BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 18),
                ],
              ),
              child: Icon(icon, color: WebColors.veryDarkBlue, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: const TextStyle(
                      color: WebColors.secondaryAccentLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: WebColors.whiteText,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (onSeeAll != null)
              TextButton.icon(
                onPressed: onSeeAll,
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: WebColors.primaryGoldLight, size: 18),
                label: const Text(
                  'Tümünü Gör',
                  style: TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      );
  }
}

// =============================================================================
// SONUÇ META ÇUBUĞU — facet bar
// =============================================================================
//
// Segmentli kategori anahtarı (bkz. `search_header_web.dart`) hangi
// kategoride olduğumuzu gösteriyor; bu şerit ise NE KADAR sonuç bulunduğunu
// ve (varsa) aktif metin sorgusunu tek satırlık, sessiz bir "facet bar"
// olarak özetler — gerçek e-ticaret/arama ürünlerindeki "124 sonuç ·
// Oyuncular" satırına yakın. Chip değil: interaktif değil, kendi arka
// planı/kenarlığı yok, içeriğe gömülü düz bir metin satırı.
class DesktopResultsMetaBar extends StatelessWidget {
  final int count;
  final int filterIndex;
  final String query;

  const DesktopResultsMetaBar({
    super.key,
    required this.count,
    required this.filterIndex,
    required this.query,
  });

  @override
  Widget build(final BuildContext context) {
    final String categoryLabel = SearchCategoryPalette.labels[
        filterIndex.clamp(0, SearchCategoryPalette.labels.length - 1)];
    final Color accent = SearchCategoryPalette.tintFor(filterIndex)[0];
    final String suffix = <String>[
      if (filterIndex != SearchCategoryPalette.all) '$categoryLabel içinde',
      if (query.isNotEmpty) '"$query" için',
    ].join('  ·  ');
    const secondaryStyle = TextStyle(
      fontSize: 14,
      color: WebColors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22, top: 2),
      child: Row(
        children: [
          // Facet anahtarının seçili segmentiyle aynı tonu taşıyan, filtre
          // değiştikçe yumuşakça renk geçişi yapan küçük bir "canlı" nokta —
          // hangi kategoride olduğumuzu sessizce hatırlatır.
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _AnimatedCount(
                  value: count,
                  style: const TextStyle(
                    fontSize: 14,
                    color: WebColors.whiteText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(' sonuç', style: secondaryStyle),
                if (suffix.isNotEmpty) ...[
                  const Text('  ·  ', style: secondaryStyle),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (final child, final animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        suffix,
                        key: ValueKey(suffix),
                        style: secondaryStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CANLI SAYAÇ — sonuç sayısı değiştikçe (yazarken daralan/genişleyen sonuç
// kümesi) rakamın eskisinden yenisine doğru sayarak geçiş yapmasını sağlar.
// Sadece gerçek, zaten hesaplanmış `count` değerini kullanır — uydurma bir
// sayı üretmez, sadece onu göstermenin biçimini canlandırır.
// =============================================================================

class _AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCount({required this.value, required this.style});

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animation = AlwaysStoppedAnimation<double>(widget.value.toDouble());
  }

  @override
  void didUpdateWidget(covariant final _AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final double from = _animation.value;
      _animation = Tween<double>(begin: from, end: widget.value.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _animation,
        builder: (final context, final _) => Text(
          _animation.value.round().toString(),
          style: widget.style,
        ),
      );
}

// =============================================================================
// GÖSTERİ (SHOW) KARTI
// =============================================================================

class DesktopShowCard extends StatefulWidget {
  final Show show;
  final int index;

  const DesktopShowCard({super.key, required this.show, required this.index});

  @override
  State<DesktopShowCard> createState() => _DesktopShowCardState();
}

class _DesktopShowCardState extends State<DesktopShowCard> {
  bool _hovered = false;

  void _setHovered(final bool value) {
    if (mounted) setState(() => _hovered = value);
  }

  @override
  Widget build(final BuildContext context) => SearchRevealOnScroll(
        index: widget.index,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (final _) => _setHovered(true),
          onExit: (final _) => _setHovered(false),
          child: GestureDetector(
            onTap: () =>
                NavigationHandler.goToShow(context, widget.show.id, widget.show.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..translate(0.0, _hovered ? -8.0 : 0.0),
              decoration: BoxDecoration(
                borderRadius: kSearchCardCorner,
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? WebColors.primaryGold.withOpacity(0.4)
                        : Colors.black.withOpacity(0.35),
                    blurRadius: _hovered ? 30 : 16,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: kSearchCardCorner,
                // Poster görseli hâlâ sabit bir oranda (0.72) — bozulmasın
                // diye. Asıl masonry farkı, altındaki gerçek-veri satırından
                // (`_buildMetaFooter`) gelir: `show.category`/`show.duration`
                // dolu olan kartlar bir satır daha uzun olur, boş olanlarda
                // bu satır hiç render edilmez — uydurma bir yükseklik farkı
                // DEĞİL, gerçek verinin doğal sonucu.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 0.72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedScale(
                            scale: _hovered ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                            child: OptimizedCachedImage(
                                imageUrl: widget.show.imageUrl,
                                fit: BoxFit.cover,
                                borderRadius: 0),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    WebColors.veryDarkBlue
                                        .withOpacity(_hovered ? 0.96 : 0.9),
                                  ],
                                  stops: const [0.35, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: SearchCategoryPalette
                                        .tints[SearchCategoryPalette.events][0]
                                        .withOpacity(0.9),
                                    borderRadius: kSearchBadgeCorner,
                                  ),
                                  child: const Text('ETKİNLİK',
                                      style: TextStyle(
                                          color: WebColors.veryDarkBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1)),
                                ),
                                const SizedBox(height: 10),
                                Text(widget.show.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: WebColors.whiteText,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2)),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topLeft,
                                  child: AnimatedOpacity(
                                    opacity: _hovered ? 1 : 0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: _hovered
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text('Detayları Gör',
                                                    style: TextStyle(
                                                        color: WebColors
                                                            .primaryGoldLight,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                SizedBox(width: 4),
                                                Icon(
                                                    Icons
                                                        .arrow_forward_rounded,
                                                    color: WebColors
                                                        .primaryGoldLight,
                                                    size: 14),
                                              ],
                                            ),
                                          )
                                        : const SizedBox(
                                            width: double.infinity),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.show.category.isNotEmpty ||
                        widget.show.duration.isNotEmpty)
                      _buildMetaFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Kartın altında, sadece GERÇEK `show.category` / `show.duration` alanı
  /// doluysa görünen bir meta satırı. İkisi de boşsa hiç render edilmez —
  /// bu yüzden bazı kartlar diğerlerinden gerçekten daha uzun olur ve
  /// masonry grid'de anlamlı, veriye dayalı bir fark yaratır (uydurma bir
  /// yükseklik varyasyonu DEĞİL).
  Widget _buildMetaFooter() {
    final Color accent =
        SearchCategoryPalette.tints[SearchCategoryPalette.events][0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: WebColors.darkBlueSurface,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.show.category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.16),
                borderRadius: kSearchBadgeCorner,
                border: Border.all(color: accent.withOpacity(0.5)),
              ),
              child: Text(
                widget.show.category.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          if (widget.show.duration.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: WebColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  widget.show.duration,
                  style: const TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// OYUNCU (PLAYER) KARTI
// =============================================================================

class DesktopPlayerCard extends StatefulWidget {
  final Player player;
  final int index;

  const DesktopPlayerCard({super.key, required this.player, required this.index});

  @override
  State<DesktopPlayerCard> createState() => _DesktopPlayerCardState();
}

class _DesktopPlayerCardState extends State<DesktopPlayerCard> {
  bool _hovered = false;

  void _setHovered(final bool value) {
    if (mounted) setState(() => _hovered = value);
  }

  @override
  Widget build(final BuildContext context) {
    final fullName = '${widget.player.firstName} ${widget.player.lastName}';

    // Küçük, oval "kimlik rozeti" — mobil uygulamanın kendi oyuncu
    // şeridiyle (bkz. players_bubble_card.dart: 120px genişlik, ClipOval,
    // isim altta) AYNI minimal dil, web'e uyarlanmış hâli. Önceki sürüm
    // (büyük dikdörtgen "headshot" + ayrı koyu isim plaketi, 6 sütunlu
    // devasa kartlar) kullanıcı tarafından "berbat" olarak işaretlendi —
    // burada TAMAMEN kaldırıldı, ağır kenarlık/gölge/plaket yerine sade
    // bir daire + tek satırlık isim var. Grid, search_page.dart'ta bu
    // kartın küçük boyutuna uygun şekilde çok daha yoğun bir
    // crossAxisCount kullanıyor.
    //
    // 🔥 DÜZELTME: Mobildeki gibi tam yuvarlak (72x72) olması istenmedi —
    // "oval, uzun, ayna gibi" bir siluet istendi (sonradan hem yandan hem
    // alttan biraz daha uzatılıp büyütüldü: 84x128). `BoxShape.circle`
    // (ve `ClipOval`) kutunun ORANINA göre elips çizer — kutu artık
    // kareden ziyade dikey dikdörtgen olduğu için otomatik olarak uzun
    // bir el aynası ovaline dönüşüyor, ekstra bir path/clipper gerekmiyor.
    return SearchRevealOnScroll(
      index: widget.index,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => _setHovered(true),
        onExit: (final _) => _setHovered(false),
        child: GestureDetector(
          onTap: () => NavigationHandler.goToPlayer(
              context, widget.player.id, fullName),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: 84,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hovered
                        ? WebColors.primaryGold
                        : WebColors.primaryGold.withOpacity(0.25),
                    width: _hovered ? 2 : 1,
                  ),
                  boxShadow: _hovered
                      ? AppShadows.level2(WebColors.primaryGold)
                      : AppShadows.level0,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: AnimatedScale(
                      scale: _hovered ? 1.08 : 1.0,
                      duration: AppMotion.normal,
                      curve: AppMotion.standard,
                      child: OptimizedCachedImage(
                        imageUrl: widget.player.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 104,
                // Sabit yükseklik: iki satıra sarılan uzun isimlerde
                // (ör. "Mualla Sürezlioğlu") grid hücresinin hesaplanan
                // yüksekliği metnin doğal yüksekliğinden birkaç piksel az
                // kalıp "BOTTOM OVERFLOWED" hatası veriyordu — Text'i
                // `mainAxisSize: min` bir Column içinde serbest bırakmak
                // yerine sabit bir yüksekliğe oturtmak taşmayı kesin olarak
                // önlüyor (grid oranı ne olursa olsun).
                height: 32,
                child: Text(
                  fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hovered
                        ? WebColors.primaryGoldLight
                        : WebColors.whiteText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MEKAN / EKİP (STAGE / TEAM) KARTI
// =============================================================================

/// [item], `id`, `name` ve `imageUrl` alanlarına sahip Stage veya Team
/// olabilir (mevcut `_GridCards` konvansiyonuyla aynı `dynamic` yaklaşımı).
class DesktopPlaceCard extends StatefulWidget {
  final dynamic item;
  final int index;
  final bool isStage;

  const DesktopPlaceCard(
      {super.key, required this.item, required this.index, required this.isStage});

  @override
  State<DesktopPlaceCard> createState() => _DesktopPlaceCardState();
}

class _DesktopPlaceCardState extends State<DesktopPlaceCard> {
  bool _hovered = false;

  void _setHovered(final bool value) {
    if (mounted) setState(() => _hovered = value);
  }

  @override
  Widget build(final BuildContext context) {
    // Mekan ve ekip kategorileri, aynı kart tipini paylaşsa bile
    // SearchCategoryPalette'ten farklı bir ton alır — böylece rozet ve
    // hover parıltısı "Mekanlar" filtre sekmesiyle/simgesiyle,
    // "Ekipler" ise kendi sekmesiyle aynı kimliği taşır.
    final accent = SearchCategoryPalette.tints[
        widget.isStage ? SearchCategoryPalette.stages : SearchCategoryPalette.teams];

    return SearchRevealOnScroll(
        index: widget.index,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (final _) => _setHovered(true),
          onExit: (final _) => _setHovered(false),
          child: GestureDetector(
            onTap: () => widget.isStage
                ? NavigationHandler.goToStage(
                    context, widget.item.id as String, widget.item.name as String)
                : NavigationHandler.goToTeam(
                    context, widget.item.id as String, widget.item.name as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..translate(0.0, _hovered ? -6.0 : 0.0),
              decoration: BoxDecoration(
                borderRadius: kSearchPlaceCorner,
                boxShadow: [
                  BoxShadow(
                      color: _hovered
                          ? accent[1].withOpacity(0.35)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: _hovered ? 26 : 14,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: kSearchPlaceCorner,
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hovered ? 1.07 : 1.0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        child: OptimizedCachedImage(
                            imageUrl: widget.item.imageUrl as String,
                            fit: BoxFit.cover,
                            borderRadius: 0),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                WebColors.veryDarkBlue.withOpacity(0.92),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent[0].withOpacity(0.9),
                                borderRadius: kSearchBadgeCorner,
                              ),
                              // Rozet artık salt renkle değil, bir ikonla da
                              // "mekan mı ekip mi" ayrımını taşıyor — Mekan
                              // (fiziksel yer) vs. Ekip (topluluk/organizasyon)
                              // arasındaki gerçek kavramsal farkı sessizce
                              // vurgular.
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isStage
                                        ? Icons.location_city_rounded
                                        : Icons.groups_rounded,
                                    size: 10,
                                    color: WebColors.veryDarkBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.isStage ? 'MEKAN' : 'EKİP',
                                    style: const TextStyle(
                                        color: WebColors.veryDarkBlue,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.item.name as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: WebColors.whiteText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2)),
                            _buildRealInfoLine(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  /// Mekanlar (yerler) ve Ekipler (topluluklar) farklı türde şeylerdir —
  /// Show/Player kartlarının "editoryal" hissinden ayrı, kısa bir
  /// "bilgi" (informational) satırı ekler. SADECE zaten entity üzerinde
  /// var olan GERÇEK alanları kullanır: Mekan için `Stage.address`
  /// (konum ipucu), Ekip için `Team.showsId`/`Stage.showsId` uzunluğu
  /// (kaç gösteriyle ilişkili — gerçek, zaten hesaplanmış bir sayı).
  /// Uydurma bir koltuk sayısı, kuruluş yılı vb. EKLENMEZ; alan boş/sıfırsa
  /// satır hiç render edilmez.
  Widget _buildRealInfoLine() {
    final IconData icon;
    final String label;
    if (widget.isStage) {
      final String address = ((widget.item.address as String?) ?? '').trim();
      if (address.isEmpty) return const SizedBox.shrink();
      icon = Icons.location_on_rounded;
      label = address;
    } else {
      final List<dynamic> showsId =
          (widget.item.showsId as List<dynamic>?) ?? const [];
      if (showsId.isEmpty) return const SizedBox.shrink();
      icon = Icons.theater_comedy_rounded;
      label = '${showsId.length} gösteri';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: WebColors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WebColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOŞ SONUÇ DURUMU
// =============================================================================

class DesktopSearchEmptyState extends StatelessWidget {
  final String message;
  final String clearLabel;
  final VoidCallback onClear;

  /// Boş sonuç anında kullanıcıya gerçekten var olan kategorileri (uydurma
  /// arama önerileri DEĞİL) hızlıca göz atma imkânı sunar — dokunulduğunda
  /// hem sorgu temizlenir hem de o kategoriye geçilir.
  final void Function(int categoryIndex) onBrowseCategory;

  const DesktopSearchEmptyState({
    super.key,
    required this.message,
    required this.clearLabel,
    required this.onClear,
    required this.onBrowseCategory,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                const _BreathingEmptyIcon(),
                const SizedBox(height: 28),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: WebColors.whiteText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    backgroundColor: WebColors.primaryGold,
                    foregroundColor: WebColors.veryDarkBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    // landing/style.css .btn: köşegen kesimli CTA (2px 14px
                    // 2px 14px) — tam yuvarlak hap yerine marka köşe dili.
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(2),
                      bottomLeft: Radius.circular(18),
                    )),
                  ),
                  child: Text(clearLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 36),
                Container(
                  height: 1,
                  width: 64,
                  color: WebColors.primaryGold.withOpacity(0.18),
                ),
                const SizedBox(height: 22),
                Text(
                  'Bunun yerine göz atabilirsin',
                  style: TextStyle(
                    color: WebColors.textTertiary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 1; i < SearchCategoryPalette.labels.length; i++)
                      _EmptyStateCategoryChip(
                        index: i,
                        onTap: () => onBrowseCategory(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Boş durum ikonu — sabit değil, dikkat çekmeden sürekli hafifçe "nefes
/// alan" bir ölçek/opaklık döngüsü. Marka rengiyle (primaryGold) uyumlu,
/// sonsuz döngülü ama küçük genlikli — abartısız bir "burada hâlâ hayat
/// var" motifi.
class _BreathingEmptyIcon extends StatefulWidget {
  const _BreathingEmptyIcon();

  @override
  State<_BreathingEmptyIcon> createState() => _BreathingEmptyIconState();
}

class _BreathingEmptyIconState extends State<_BreathingEmptyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          final double t = Curves.easeInOut.transform(_controller.value);
          final double scale = 1.0 + (t * 0.06);
          final double glow = 0.10 + (t * 0.10);
          return Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WebColors.primaryGold.withOpacity(0.12),
              border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.3 + t * 0.2)),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(glow),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: const Icon(Icons.auto_awesome_motion_outlined,
            size: 44, color: WebColors.primaryGoldLight),
      );
}

/// Boş durumda önerilen, GERÇEK var olan kategori — uydurma bir arama
/// terimi değil, doğrudan `SearchCategoryPalette`'ten (aynı ikon/ton).
class _EmptyStateCategoryChip extends StatefulWidget {
  final int index;
  final VoidCallback onTap;

  const _EmptyStateCategoryChip({required this.index, required this.onTap});

  @override
  State<_EmptyStateCategoryChip> createState() =>
      _EmptyStateCategoryChipState();
}

class _EmptyStateCategoryChipState extends State<_EmptyStateCategoryChip> {
  bool _hovered = false;

  void _setHovered(final bool value) {
    if (mounted) setState(() => _hovered = value);
  }

  @override
  Widget build(final BuildContext context) {
    final accent = SearchCategoryPalette.tintFor(widget.index);
    final label = SearchCategoryPalette.labels[widget.index];
    final icon = SearchCategoryPalette.icons[widget.index];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => _setHovered(true),
      onExit: (final _) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0.0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? accent[0].withOpacity(0.14)
                : WebColors.darkBlueSurface,
            borderRadius: kSearchIconCorner,
            border: Border.all(
              color: _hovered
                  ? accent[0].withOpacity(0.7)
                  : WebColors.textTertiary.withOpacity(0.25),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: accent[0].withOpacity(0.3), blurRadius: 16)]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _hovered ? accent[0] : WebColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _hovered ? WebColors.whiteText : WebColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
