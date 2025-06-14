import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../claude.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final team = [
      {
        'name': 'Mehmet Kaya',
        'role': 'Kurucu & Sanat Yönetmeni',
        'initials': 'MK',
        'bio': '15 yıllık tiyatro deneyimi. İstanbul Devlet Tiyatrosu mezunu.',
      },
      {
        'name': 'Ayşe Demir',
        'role': 'Baş Oyuncu',
        'initials': 'AD',
        'bio': 'Sahne sanatları alanında 12 yıllık deneyim.',
      },
      {
        'name': 'Zeynep Yılmaz',
        'role': 'Dramatik Oyuncu',
        'initials': 'ZY',
        'bio': 'Tiyatro akademisi mezunu. Dramatik rollerdeki başarısı.',
      },
      {
        'name': 'Emre Çelik',
        'role': 'Yönetmen Asistanı',
        'initials': 'EÇ',
        'bio': 'Genç ve dinamik tiyatro insanı.',
      },
      {
        'name': 'Deniz Öztürk',
        'role': 'Sahne Tasarımcısı',
        'initials': 'DO',
        'bio': 'Güzel Sanatlar Akademisi mezunu.',
      },
      {
        'name': 'Selin Kara',
        'role': 'Kostüm & Makyaj',
        'initials': 'SK',
        'bio': 'Moda tasarımı kökenli sanatçı.',
      },
    ];

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          TeamIntroSection(),
          CustomSectionTitle(title: 'Ekibimiz'),
          SizedBox(height: 40),
          LayoutBuilder(
            builder: (final context, final constraints) {
              final int crossAxisCount = constraints.maxWidth > 1000
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: team.length,
                itemBuilder: (final context, final index) {
                  return _buildTeamCard(team[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(final Map<String, String> member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: AppWebLightColors.primaryGold.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppWebLightColors.primaryGold, Color(0xFFf4d03f)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member['initials']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppWebLightColors.darkBlueBackground,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              member['name']!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppWebLightColors.whiteText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              member['role']!,
              style: TextStyle(
                fontSize: 14,
                color: AppWebLightColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Expanded(
              child: Text(
                member['bio']!,
                style: TextStyle(
                  color: AppWebLightColors.whiteText.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
