import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import 'player_section_heading.dart';
import 'scroll_reveal.dart';

/// 🖼️ EDİTORYAL (ASİMETRİK) GÖSTERİ LİSTESİ
///
/// "Sahnede" bölümü için: mobildeki tek tip liste kartları yerine, görsel ve
/// metnin sırayla sağa/sola geçtiği, dergi sayfası hissi veren bir düzen.
class PlayerShowsEditorial extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Show> shows;
  final String emptyMessage;

  const PlayerShowsEditorial({
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
        const SizedBox(height: 32),
        if (shows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
          Column(
            children: shows.asMap().entries.map((final entry) {
              final int index = entry.key;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == shows.length - 1 ? 0 : 48),
                child: ScrollReveal(
                  delay: Duration(milliseconds: 80 * index),
                  beginOffset: Offset(index.isEven ? -0.05 : 0.05, 0),
                  child: _EditorialShowRow(
                    show: entry.value,
                    imageOnLeft: index.isEven,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _EditorialShowRow extends StatefulWidget {
  final Show show;
  final bool imageOnLeft;

  const _EditorialShowRow({required this.show, required this.imageOnLeft});

  @override
  State<_EditorialShowRow> createState() => _EditorialShowRowState();
}

class _EditorialShowRowState extends State<_EditorialShowRow> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final image = _ShowImage(imageUrl: widget.show.imageUrl, hovered: _hovered);
    final text = _ShowCopy(show: widget.show, hovered: _hovered);

    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => NavigationHandler.goToShow(
            context, widget.show.id, widget.show.name),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.imageOnLeft
              ? [
                  Expanded(flex: 5, child: image),
                  const SizedBox(width: 48),
                  Expanded(flex: 6, child: text),
                ]
              : [
                  Expanded(flex: 6, child: text),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: image),
                ],
        ),
      ),
    );
  }
}

class _ShowImage extends StatelessWidget {
  final String imageUrl;
  final bool hovered;

  const _ShowImage({required this.imageUrl, required this.hovered});

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          scale: hovered ? 1.06 : 1.0,
          child: OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ShowCopy extends StatelessWidget {
  final Show show;
  final bool hovered;

  const _ShowCopy({required this.show, required this.hovered});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TİYATRO PERFORMANSI',
          style: TextStyle(
            color: WebColors.secondaryAccentLight,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          show.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: WebColors.whiteText,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        if (show.description.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            show.description.replaceAll('\\n', '\n'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: WebColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: hovered
                    ? WebColors.primaryGoldLight
                    : WebColors.whiteText,
              ),
              child: const Text('Detayları Gör'),
            ),
            const SizedBox(width: 8),
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: hovered ? const Offset(0.3, 0) : Offset.zero,
              child: const Icon(Icons.arrow_forward_rounded,
                  color: WebColors.primaryGold, size: 18),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(top: 6),
          height: 2,
          width: hovered ? 120 : 0,
          color: WebColors.primaryGold,
        ),
      ],
    );
  }
}
