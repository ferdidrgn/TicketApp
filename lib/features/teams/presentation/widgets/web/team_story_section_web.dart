import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// 📖 EKİP HİKAYESİ (MASAÜSTÜ)
///
/// Mobildeki tek sütun kart yerine, editoryal bir dergi sayfası gibi
/// asimetrik iki sütun: solda ince bir başlık + dekoratif tırnak işareti,
/// sağda geniş, nefes alan bir anlatı metni.
class TeamStorySectionWeb extends StatelessWidget {
  final String description;

  const TeamStorySectionWeb({super.key, required this.description});

  @override
  Widget build(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 2,
                      color: WebColors.primaryGold,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'EKİP HİKAYESİ',
                      style: TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Sahnenin\nArkasındaki\nRuh',
                  style: TextStyle(
                    color: WebColors.whiteText,
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '“',
                  style: TextStyle(
                    color: WebColors.primaryGold.withOpacity(0.35),
                    fontSize: 96,
                    height: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: WebColors.veryDarkBlue.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Text(
                description.replaceAll('\\n', '\n'),
                style: TextStyle(
                  color: WebColors.textSecondary,
                  fontSize: 17,
                  height: 1.9,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      );
}
