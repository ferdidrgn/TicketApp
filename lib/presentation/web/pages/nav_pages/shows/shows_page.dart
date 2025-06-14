import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import '../home/widgets/kurtar_beni_doktor_landing.dart';

class ShowsPage extends StatelessWidget {
  const ShowsPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          const GozYapVazYapLanding(),
          SizedBox(height: 40),
          const KurtarBeniDoktorLanding(),
        ],
      ),
    );
  }
}
