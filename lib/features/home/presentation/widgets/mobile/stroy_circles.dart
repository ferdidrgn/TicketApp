import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../campaigns/domain/entities/campaign.dart';

class StoryCircles extends StatelessWidget {
  final List<Campaign> campaigns;
  final Function(int index) onStoryTap;

  const StoryCircles({
    super.key,
    required this.campaigns,
    required this.onStoryTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: campaigns.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 18),
        itemBuilder: (final context, final index) => _StoryItem(
          campaign: campaigns[index],
          onTap: () => onStoryTap(index),
        ),
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
  Widget build(final BuildContext context) => GestureDetector(
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
