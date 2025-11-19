import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';

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
    return Column(
      children: [
        // Hero Section
        const HeroVideoSection(),
        SizedBox(height: 40),
        // Quote Section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          decoration: const BoxDecoration(
            gradient: WebColors.backgroundGradient,
          ),
          child: Text(
            '"Hikayelerimizle kalplere dokunuyor,\nsanatla hayata anlam katıyoruz"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: WebColors.whiteText.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ),

        // Shows Section
        Container(key: showsKey, child: const ShowsSection()),

        // Metafor Landing
        Container(key: artisticKey, child: const MetaforLanding()),

        const SizedBox(height: 40),

        // Kurtar Beni Doktor
        const KurtarBeniDoktorLanding(),

        const SizedBox(height: 40),

        // Göz Kap Vaz Yap
        const GozYapVazYapLanding(),

        // About Section
        Container(key: aboutKey, child: const AboutCard()),

        // Team Section
        Container(key: teamKey, child: const TeamCard()),

        // Contact Section
        Container(key: contactKey, child: const ContactCard()),

        // Footer spacing
        const SizedBox(height: 60),
      ],
    );
  }
}
