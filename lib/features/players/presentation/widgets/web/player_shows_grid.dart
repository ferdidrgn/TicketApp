import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import 'player_section_heading.dart';
import 'scroll_reveal.dart';

/// 🗂️ ARŞİV IZGARASI
///
/// Geçmişte sahnelenen gösteriler için daha kompakt, zarif bir kart ızgarası
/// — hover'da hafifçe yükselen kartlar.
class PlayerShowsGrid extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Show> shows;
  final String emptyMessage;

  const PlayerShowsGrid({
    super.key,
    required this.title,
    required this.icon,
    required this.shows,
    required this.emptyMessage,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScrollReveal(child: PlayerSectionHeading(title: title, icon: icon)),
        const SizedBox(height: AppSpacing.xxxl),
        if (shows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              emptyMessage,
              style: const TextStyle(
                color: WebColors.textTertiary,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          )
        else
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: shows.asMap().entries.map((final entry) {
              return ScrollReveal(
                delay: Duration(milliseconds: 60 * entry.key),
                child: _ArchiveShowCard(show: entry.value),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ArchiveShowCard extends StatefulWidget {
  final Show show;

  const _ArchiveShowCard({required this.show});

  @override
  State<_ArchiveShowCard> createState() => _ArchiveShowCardState();
}

class _ArchiveShowCardState extends State<_ArchiveShowCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => NavigationHandler.goToShow(
            context, widget.show.id, widget.show.name),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: 260,
          transform: Matrix4.identity()..translate(0.0, _hovered ? -8.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: WebColors.darkBlueSurface.withOpacity(0.5),
            border: Border.all(
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.6)
                  : WebColors.primaryGold.withOpacity(0.15),
            ),
            boxShadow: _hovered
                ? AppShadows.level3(WebColors.primaryGold)
                : AppShadows.level1(Colors.black),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AnimatedScale(
                    duration: AppMotion.normal,
                    scale: _hovered ? 1.05 : 1.0,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(_hovered ? 0.0 : 0.15),
                        BlendMode.darken,
                      ),
                      child: OptimizedCachedImage(
                          imageUrl: widget.show.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: WebColors.whiteText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 14, color: WebColors.textTertiary),
                        const SizedBox(width: 6),
                        const Text(
                          'ARŞİV',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: WebColors.textTertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
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
