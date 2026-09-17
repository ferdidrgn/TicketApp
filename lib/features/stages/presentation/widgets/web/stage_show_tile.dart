import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

/// Bir sahnede oynayan eseri temsil eden, masaüstü için tasarlanmış zarif
/// liste öğesi. Fare üzerine geldiğinde görsel hafifçe büyür, kart hafifçe
/// yükselir ve kenarlığı mercan tonuna döner.
class StageUpcomingShowTile extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const StageUpcomingShowTile(
      {super.key, required this.show, required this.onTap});

  @override
  State<StageUpcomingShowTile> createState() => _StageUpcomingShowTileState();
}

class _StageUpcomingShowTileState extends State<StageUpcomingShowTile> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 16),
            transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface
                  .withOpacity(_hovered ? 0.95 : 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.55)
                    : WebColors.primaryGold.withOpacity(0.15),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                          color: WebColors.primaryGold.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedScale(
                    scale: _hovered ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: OptimizedCachedImage(
                      imageUrl: widget.show.imageUrl,
                      width: 96,
                      height: 120,
                      fit: BoxFit.cover,
                      borderRadius: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.show.name,
                        style: const TextStyle(
                          color: WebColors.whiteText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.show.category.isNotEmpty)
                            _Tag(text: widget.show.category),
                          if (widget.show.duration.isNotEmpty)
                            _Tag(text: widget.show.duration),
                          if (widget.show.ageLimit.isNotEmpty)
                            _Tag(text: widget.show.ageLimit),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? WebColors.primaryGold
                        : WebColors.primaryGold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _hovered
                        ? WebColors.veryDarkBlue
                        : WebColors.primaryGoldLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: WebColors.secondaryAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: WebColors.secondaryAccentLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
