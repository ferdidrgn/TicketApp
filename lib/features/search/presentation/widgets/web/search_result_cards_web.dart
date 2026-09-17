import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
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
                child: AspectRatio(
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
                                WebColors.veryDarkBlue.withOpacity(_hovered ? 0.96 : 0.9),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                duration: const Duration(milliseconds: 200),
                                child: _hovered
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
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
                                            Icon(Icons.arrow_forward_rounded,
                                                color:
                                                    WebColors.primaryGoldLight,
                                                size: 14),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ),
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
  Widget build(final BuildContext context) => SearchRevealOnScroll(
        index: widget.index,
        // Avatar boyutu, grid hücresinin gerçek genişliğine göre hesaplanır
        // (sabit piksel yerine) — böylece dar masaüstü genişliklerinde veya
        // yüksek sütun sayılarında taşma (overflow) yaşanmaz.
        child: LayoutBuilder(
          builder: (final context, final constraints) {
            final double maxW =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 132;
            final double baseSize = (maxW * 0.86).clamp(56.0, 132.0);
            final double avatarSize = _hovered ? baseSize * 1.05 : baseSize;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (final _) => _setHovered(true),
              onExit: (final _) => _setHovered(false),
              child: GestureDetector(
                onTap: () => NavigationHandler.goToPlayer(context,
                    widget.player.id,
                    '${widget.player.firstName} ${widget.player.lastName}'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: avatarSize,
                      height: avatarSize,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hovered
                              ? WebColors.primaryGold
                              : SearchCategoryPalette
                                  .tints[SearchCategoryPalette.players][1]
                                  .withOpacity(0.35),
                          width: _hovered ? 3 : 1.5,
                        ),
                        boxShadow: _hovered
                            ? [
                                BoxShadow(
                                    color:
                                        WebColors.primaryGold.withOpacity(0.35),
                                    blurRadius: 24,
                                    spreadRadius: 2),
                              ]
                            : const [],
                      ),
                      child: ClipOval(
                        child: OptimizedCachedImage(
                            imageUrl: widget.player.imageUrl,
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${widget.player.firstName}\n${widget.player.lastName}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _hovered
                            ? WebColors.primaryGoldLight
                            : WebColors.whiteText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
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
                              child: Text(
                                widget.isStage ? 'MEKAN' : 'EKİP',
                                style: const TextStyle(
                                    color: WebColors.veryDarkBlue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1),
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
}

// =============================================================================
// BOŞ SONUÇ DURUMU
// =============================================================================

class DesktopSearchEmptyState extends StatelessWidget {
  final String message;
  final String clearLabel;
  final VoidCallback onClear;

  const DesktopSearchEmptyState({
    super.key,
    required this.message,
    required this.clearLabel,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WebColors.primaryGold.withOpacity(0.12),
                    border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome_motion_outlined,
                      size: 44, color: WebColors.primaryGoldLight),
                ),
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
              ],
            ),
          ),
        ),
      );
}
