import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

/// "Şehrin Sahneleri" — mekan/venue yatay şeridi.
class HomeStageRail extends StatelessWidget {
  final List<Stage> stages;
  final void Function(Stage stage) onStageTap;

  const HomeStageRail({
    super.key,
    required this.stages,
    required this.onStageTap,
  });

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: stages.length,
          separatorBuilder: (final _, final __) => const SizedBox(width: 18),
          itemBuilder: (final context, final index) => _StageCard(
            stage: stages[index],
            onTap: () => onStageTap(stages[index]),
          ),
        ),
      );
}

class _StageCard extends StatefulWidget {
  final Stage stage;
  final VoidCallback onTap;

  const _StageCard({required this.stage, required this.onTap});

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _hovered ? 1.02 : 1.0,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: WebColors.veryDarkBlue.withOpacity(0.4),
                    blurRadius: _hovered ? 22 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(4),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                      imageUrl: widget.stage.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            WebColors.veryDarkBlue.withOpacity(0.88),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebColors.whiteText,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event_seat_rounded,
                                  size: 13, color: WebColors.secondaryAccentLight),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.stage.capacity} kişi',
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
          ),
        ),
      );
}
