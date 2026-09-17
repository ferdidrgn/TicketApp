import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'player_section_heading.dart';
import 'scroll_reveal.dart';

/// 🏆 BAŞARILAR ZAMAN ÇİZELGESİ
///
/// `Player.achievements` (`List<Map<String, String>>` — `year`/`title`/
/// `detail`) alanını dikey bir zaman çizelgesi olarak sunar. Veri yoksa hiçbir
/// şey uydurmadan boş durum mesajı gösterir.
class PlayerAchievementsTimeline extends StatelessWidget {
  final List<Map<String, String>> achievements;

  const PlayerAchievementsTimeline({super.key, required this.achievements});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScrollReveal(
          child: PlayerSectionHeading(
              title: 'Başarılar', icon: Icons.emoji_events_rounded),
        ),
        const SizedBox(height: 32),
        if (achievements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Başarı hikayesi henüz yazılmamış.',
              style: TextStyle(
                color: WebColors.textTertiary,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          )
        else
          Column(
            children: achievements.asMap().entries.map((final entry) {
              final int index = entry.key;
              final Map<String, String> item = entry.value;
              final bool isLast = index == achievements.length - 1;
              return ScrollReveal(
                delay: Duration(milliseconds: 70 * index),
                beginOffset: const Offset(0, 0.08),
                child: _TimelineEntry(
                  year: item['year'] ?? '----',
                  title: item['title'] ?? '',
                  detail: item['detail'],
                  isLast: isLast,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String year;
  final String title;
  final String? detail;
  final bool isLast;

  const _TimelineEntry({
    required this.year,
    required this.title,
    required this.detail,
    required this.isLast,
  });

  @override
  Widget build(final BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              year,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: WebColors.primaryGoldLight,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: WebColors.primaryGold.withOpacity(0.25),
                      width: 5),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: WebColors.primaryGold.withOpacity(0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: WebColors.whiteText,
                      height: 1.3,
                    ),
                  ),
                  if (detail != null && detail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      detail!,
                      style: const TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
