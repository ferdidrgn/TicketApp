import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'widgets/kurtar_beni_doktor_landing.dart';

class ShowsPage extends StatelessWidget {
  const ShowsPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          CustomSectionTitle(title: 'Oyunlarımız', textColor: Colors.yellow),
          SizedBox(height: 40),
          const KurtarBeniDoktorLanding(),
        ],
      ),
    );
  }
}
