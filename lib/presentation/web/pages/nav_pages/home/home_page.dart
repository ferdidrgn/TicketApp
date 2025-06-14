import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/artistic_showcase.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';

import '../../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  final GlobalKey showsKey;
  final GlobalKey aboutKey;
  final GlobalKey teamKey;
  final GlobalKey artisticKey;
  final GlobalKey contactKey;

  const HomePage({
    super.key,
    required this.showsKey,
    required this.aboutKey,
    required this.teamKey,
    required this.artisticKey,
    required this.contactKey,
  });

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

          // Oyunlar
          ShowsSection(key: showsKey),
          const SizedBox(height: 40),

          MetaforLanding(),
          const SizedBox(height: 40),

          const KurtarBeniDoktorLanding(),
          GozYapVazYapLanding(),

          // Hakkımızda
          AboutCard(key: aboutKey),

          //Ekip
          TeamCard(key: teamKey),

          // Artistik Bölüm
          ArtisticShowcase(key: artisticKey),

          // İletişim
          ContactCard(key: contactKey)
        ],
      ),
    );
  }
}
