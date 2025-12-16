import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// Trending now section - Popüler aramalar
class TrendingNowSection extends StatelessWidget {
  const TrendingNowSection({super.key});

  static const _trendingItems = [
    "🎭 Tiyatro",
    "🎵 Konser",
    "🎤 Stand-up",
    "🎨 Sergi",
    "🎬 Sinema",
    "🎪 Festival",
  ];

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: context.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  "Şu An Popüler",
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _trendingItems.map((final item) {
                return _TrendingChip(label: item);
              }).toList(),
            ),
          ],
        ),
      );
}

class _TrendingChip extends StatelessWidget {
  final String label;

  const _TrendingChip({required this.label});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      );
}
