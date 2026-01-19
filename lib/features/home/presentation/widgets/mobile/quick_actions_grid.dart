import 'package:flutter/material.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';

/// Quick actions grid - 4 hızlı erişim butonu
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onFavoritesTap;
  final VoidCallback? onTicketsTap;
  final VoidCallback? onCalendarTap;

  const QuickActionsGrid({
    super.key,
    this.onNotificationsTap,
    this.onFavoritesTap,
    this.onTicketsTap,
    this.onCalendarTap,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hızlı Erişim",
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _QuickActionCard(
                  icon: Icons.notifications_outlined,
                  label: "Bildirimler",
                  color: const Color(0xFFFFB7B2),
                  onTap: onNotificationsTap,
                ),
                _QuickActionCard(
                  icon: Icons.favorite_outline,
                  label: "Favorilerim",
                  color: const Color(0xFFE2F0CB),
                  onTap: onFavoritesTap,
                ),
                _QuickActionCard(
                  icon: Icons.confirmation_number_outlined,
                  label: "Biletlerim",
                  color: const Color(0xFFFFDAC1),
                  onTap: onTicketsTap,
                ),
                _QuickActionCard(
                  icon: Icons.calendar_today_outlined,
                  label: "Takvim",
                  color: const Color(0xFFC7CEEA),
                  onTap: onCalendarTap,
                ),
              ],
            ),
          ],
        ),
      );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
}
