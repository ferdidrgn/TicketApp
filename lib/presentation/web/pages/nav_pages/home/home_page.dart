import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theatre_game_slider.dart';
import '../../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeroVideoSection(),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hikayelerimizle kalplere dokunuyor, sanatla hayata anlam katıyoruz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppWebLightColors.whiteText.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const SizedBox(height: 40),
          WebTheaterGamesSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
