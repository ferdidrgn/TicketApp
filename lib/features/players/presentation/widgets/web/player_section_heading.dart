import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

/// Masaüstü oyuncu sayfasındaki bölüm başlıkları için ortak stil.
/// `show_detail_page_web.dart` içindeki `_SectionTitle` biçemini izler.
class PlayerSectionHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? trailingLabel;

  const PlayerSectionHeading({
    super.key,
    required this.title,
    required this.icon,
    this.trailingLabel,
  });

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: WebColors.goldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.4),
                  blurRadius: 16),
            ],
          ),
          child: Icon(icon, color: WebColors.veryDarkBlue, size: 22),
        ),
        const SizedBox(width: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: WebColors.whiteText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                WebColors.primaryGold.withOpacity(0.5),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        if (trailingLabel != null) ...[
          const SizedBox(width: 18),
          Text(
            trailingLabel!,
            style: TextStyle(
              color: WebColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
