import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/search/presentation/widgets/web/search_scroll_reveal.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

// =============================================================================
// BÖLÜM BAŞLIĞI (show_detail_page_web.dart'daki _SectionTitle konvansiyonu)
// =============================================================================

class DesktopSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onSeeAll;

  const DesktopSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onSeeAll,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28, top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [WebColors.primaryGold, WebColors.primaryGoldLight]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: WebColors.primaryGold.withOpacity(0.35), blurRadius: 18),
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
                borderRadius: BorderRadius.circular(20),
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
                borderRadius: BorderRadius.circular(20),
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
                            imageUrl: widget.show.imageUrl, fit: BoxFit.cover),
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
                                color: WebColors.primaryGold.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
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
                            AnimatedOpacity(
                              opacity: _hovered ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('Detayları Gör',
                                        style: TextStyle(
                                            color: WebColors.primaryGoldLight,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: WebColors.primaryGoldLight, size: 14),
                                  ],
                                ),
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
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (final _) => _setHovered(true),
          onExit: (final _) => _setHovered(false),
          child: GestureDetector(
            onTap: () => NavigationHandler.goToPlayer(context, widget.player.id,
                '${widget.player.firstName} ${widget.player.lastName}'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: _hovered ? 132 : 124,
                  height: _hovered ? 132 : 124,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hovered
                          ? WebColors.primaryGold
                          : WebColors.secondaryAccent.withOpacity(0.35),
                      width: _hovered ? 3 : 1.5,
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                                color: WebColors.primaryGold.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 2),
                          ]
                        : const [],
                  ),
                  child: ClipOval(
                    child: OptimizedCachedImage(
                        imageUrl: widget.player.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${widget.player.firstName}\n${widget.player.lastName}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hovered ? WebColors.primaryGoldLight : WebColors.whiteText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
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
  Widget build(final BuildContext context) => SearchRevealOnScroll(
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
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: _hovered
                          ? WebColors.secondaryAccent.withOpacity(0.3)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: _hovered ? 26 : 14,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
                            imageUrl: widget.item.imageUrl as String, fit: BoxFit.cover),
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
                                color: WebColors.secondaryAccent.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(clearLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}
