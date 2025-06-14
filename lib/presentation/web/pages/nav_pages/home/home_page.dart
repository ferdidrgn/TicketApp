import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_news_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/shows/widgets/kurtar_beni_doktor_landing.dart';
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
              '"Hikayelerimizle kalplere dokunuyor,\nsanatla hayata anlam katıyoruz"',
              style: TextStyle(
                fontSize: 25,
                color: AppWebLightColors.whiteText.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ShowsSection(),
          const SizedBox(height: 40),
          MetaforNewsLanding(),
          const SizedBox(height: 40),
          const KurtarBeniDoktorLanding(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
