import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/common/base_loadable_state.dart';
import '../../../../../shared/widgets/shimmer.dart';
import '../../../../stages/domain/entities/stage.dart';

class StageCarousel extends StatelessWidget {
  final LoadableState<dynamic, List<Stage>> state;
  final Function(String stageId) onStageTap;

  const StageCarousel({
    super.key,
    required this.state,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ShimmerLoading(height: 160, width: double.infinity),
      );
    }

    if (!state.hasData) return const SizedBox.shrink();

    final stages = state.dataList!;

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          return _StageCard(
            stage: stages[index],
            onTap: () => onStageTap(stages[index].id),
          );
        },
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              stage.imageUrl,
              maxHeight: 300,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}