import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import '../../../../../../core/theme/app_theme.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          child: const SizedBox(height: 20),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CustomSectionTitle(
                title: 'Hakkımızda',
                textColor: Colors.yellow,
                fontSize: 50,
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (final context, final constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return isWide
                      ? _buildAboutWideLayout()
                      : _buildAboutNarrowLayout();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 2, child: _buildAboutText()),
        SizedBox(width: 40),
        Expanded(child: _buildStatsGrid()),
      ],
    );
  }

  Widget _buildAboutNarrowLayout() {
    return Column(
      children: [_buildAboutText(), SizedBox(height: 40), _buildStatsGrid()],
    );
  }

  Widget _buildAboutText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sahne Sanatları Tiyatro Topluluğu, 2018 yılında kurulan ve İstanbul merkezli faaliyet gösteren profesyonel bir tiyatro grubudur. Amacımız, klasik eserleri modern yorumlarla sahneye taşımak ve özgün metinlerle çağdaş tiyatro sanatına katkıda bulunmaktır.',
          style: TextStyle(
            fontSize: 16,
            color: AppWebLightColors.whiteText.withOpacity(0.9),
            height: 1.8,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Ekibimiz, deneyimli oyuncular, yaratıcı yönetmenler ve yetenekli sahne sanatçılarından oluşmaktadır. Her oyunumuzda kaliteyi ve sanatsal bütünlüğü ön planda tutarak, seyircilerimize unutulmaz deneyimler yaşatmayı hedefliyoruz.',
          style: TextStyle(
            fontSize: 16,
            color: AppWebLightColors.whiteText.withOpacity(0.9),
            height: 1.8,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Tiyatro sanatını sadece sahne performansı olarak görmeyip, toplumsal dönüşüme katkıda bulunan bir araç olarak değerlendiriyoruz. Bu anlayışla hareket ederek, her yaştan seyirciye hitap eden, düşündüren ve duygulandıran yapımlar üretiyoruz.',
          style: TextStyle(
            fontSize: 16,
            color: AppWebLightColors.whiteText.withOpacity(0.9),
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'number': '10+', 'label': 'Sahnelenen Oyun'},
      {'number': '10k+', 'label': 'Seyirci'},
      {'number': '7', 'label': 'Yıllık Deneyim'},
      {'number': '10', 'label': 'Gönül Vermiş Kişiler'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (final context, final index) {
        return Container(
          decoration: BoxDecoration(
            color: AppWebLightColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppWebLightColors.primaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stats[index]['number']!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppWebLightColors.primaryGold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                stats[index]['label']!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppWebLightColors.whiteText.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
