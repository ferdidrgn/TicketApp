import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import '../../../../../core/theme/app_theme.dart';

class PlayersPage extends StatelessWidget {
  const PlayersPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final plays = [
      {
        'title': 'Hamlet',
        'date': '15-20 Temmuz 2025',
        'description':
        'Shakespeare\'in ölümsüz eseri Hamlet, modern yorumumuzla sahnemizde. Danimarka Prensi Hamlet\'in intikam hikayesi, günümüzün sorunlarıyla harmanlanan güçlü bir uyarlama.',
        'cast': 'Mehmet Kaya, Ayşe Demir, Can Özkan',
      },
      {
        'title': 'Aşk-ı Memnu',
        'date': '5-10 Ağustos 2025',
        'description':
        'Halit Ziya Uşaklıgil\'in klasik romanından uyarlanan bu oyun, yasak aşkın trajik hikayesini sahneye taşıyor.',
        'cast': 'Zeynep Yılmaz, Emre Çelik, Burcu Şen',
      },
      {
        'title': 'Kafanın İçinde',
        'date': '20-25 Eylül 2025',
        'description':
        'Özgün bir metin olan bu oyun, modern insanın iç dünyasını, korkularını ve umutlarını surreal bir anlatımla sahneye getiriyor.',
        'cast': 'Deniz Öztürk, Murat Aydın, Selin Kara',
      },
      {
        'title': 'Leyla ile Mecnun',
        'date': '10-15 Ekim 2025',
        'description':
        'Klasik Doğu edebiyatının en büyük aşk hikayesi, çağdaş sahne sanatlarının imkanlarıyla yeniden hayat buluyor.',
        'cast': 'Kaan Ergün, Elif Nar, Tarık Bey',
      },
    ];

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          CustomSectionTitle(title: 'Oyunlarımız'),
          SizedBox(height: 40),
          LayoutBuilder(
            builder: (final context, final constraints) {
              final int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: plays.length,
                itemBuilder: (final context, final index) {
                  return _buildPlayCard(plays[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayCard(final Map<String, String> play) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppWebLightColors.primaryGold.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              play['title']!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppWebLightColors.primaryGold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              play['date']!,
              style: TextStyle(
                color: AppWebLightColors.primaryGold, // Added to AppWebLightColors
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Text(
                play['description']!,
                style: TextStyle(
                  color: AppWebLightColors.whiteText.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Oyuncular: ${play['cast']!}',
              style: TextStyle(
                color: AppWebLightColors.whiteText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
