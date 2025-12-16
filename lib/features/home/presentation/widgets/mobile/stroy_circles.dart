import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/common/base_loadable_state.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../campaigns/domain/entities/campaign.dart';

class StoryCircles extends StatelessWidget {
  final LoadableState<dynamic, List<Campaign>> state;
  final Function(int index) onStoryTap;

  const StoryCircles({
    super.key,
    required this.state,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.hasData) return const SizedBox.shrink();

    final campaigns = state.dataList!;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: campaigns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          return _StoryItem(
            campaign: campaigns[index],
            onTap: () => onStoryTap(index),
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const _StoryItem({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFF56040),
                  Color(0xFFFCAF45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundImage: CachedNetworkImageProvider(
                  campaign.imageUrl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 75,
            child: Text(
              campaign.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
