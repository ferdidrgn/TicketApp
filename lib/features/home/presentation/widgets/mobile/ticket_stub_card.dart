import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_context_extension.dart';

class TicketStubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onTap;

  const TicketStubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _ImageSection(imageUrl: imageUrl),
                  _PerforatedDivider(),
                  _ContentSection(
                    title: title,
                    subtitle: subtitle,
                  ),
                ],
              ),
            ),
            _TicketHole(top: -10, left: 108),
            _TicketHole(bottom: -10, left: 108),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final String imageUrl;

  const _ImageSection({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PerforatedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          10,
          (_) => Container(
            width: 2,
            height: 6,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ContentSection({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "GÜNÜN FIRSATI",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketHole extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double left;

  const _TicketHole({
    this.top,
    this.bottom,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
