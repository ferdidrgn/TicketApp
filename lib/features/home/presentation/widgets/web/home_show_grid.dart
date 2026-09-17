import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

/// "Sahnede Bu Sezon" repertuar ızgarası.
///
/// Gerçek bir bilet platformunun repertuar/keşif sayfasında göreceğin türden
/// sakin, kart tabanlı bir ızgara — mobildeki collage'ın bire bir kopyası
/// değil, masaüstüne özel sıfırdan bir kompozisyon.
class HomeShowGrid extends StatelessWidget {
  final List<Show> shows;
  final void Function(Show show) onShowTap;

  const HomeShowGrid({
    super.key,
    required this.shows,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1280
              ? 4
              : width >= 900
                  ? 3
                  : width >= 600
                      ? 2
                      : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shows.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 22,
              mainAxisSpacing: 22,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (final context, final index) =>
                _ShowCard(show: shows[index], onTap: () => onShowTap(shows[index])),
          );
        },
      );
}

class _ShowCard extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const _ShowCard({required this.show, required this.onTap});

  @override
  State<_ShowCard> createState() => _ShowCardState();
}

class _ShowCardState extends State<_ShowCard> {
  bool _hovered = false;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(26),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(26),
  );

  @override
  Widget build(final BuildContext context) {
    final show = widget.show;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: _radius,
            border: Border.all(
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.45)
                  : WebColors.darkBlueAccent,
              width: 1.2,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: WebColors.primaryGold.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(25),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OptimizedCachedImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: WebColors.veryDarkBlue.withOpacity(0.72),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(10),
                            ),
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
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: WebColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          show.duration,
                          style: const TextStyle(
                            color: WebColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.shield_outlined,
                            size: 13, color: WebColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          show.ageLimit,
                          style: const TextStyle(
                            color: WebColors.textSecondary,
                            fontSize: 12,
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
