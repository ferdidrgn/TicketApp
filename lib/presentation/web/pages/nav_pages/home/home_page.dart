import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theatre_game_slider.dart';
import '../../../../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onDiscoverPlays;

  const HomePage({super.key, required this.onDiscoverPlays});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

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
          ElevatedButton(
            onPressed: widget.onDiscoverPlays,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppWebLightColors.primaryGold,
              foregroundColor: AppWebLightColors.darkBlueBackground,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
            ),
            child: const Text(
              'OYUNLARIMIZI KEŞFEDİN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const TheaterGamesSlider(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
