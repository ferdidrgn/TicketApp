import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Ekip detay sayfasının masaüstü bölümleri için ortak, editoryal başlık:
/// gradyanlı ikon rozeti + büyük başlık + sağa uzanan ince ayraç çizgisi.
class TeamSectionTitleWeb extends StatelessWidget {
  final String title;
  final IconData icon;

  const TeamSectionTitleWeb({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                WebColors.primaryGold,
                WebColors.primaryGoldLight,
              ]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.4),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(icon, color: WebColors.veryDarkBlue, size: 24),
          ),
          const SizedBox(width: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: WebColors.whiteText,
              letterSpacing: 1,
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
        ],
      );
}
