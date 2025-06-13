import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web_tab_navigation.dart';
import 'mobil/navigation/bottom_nav_bar.dart';

class WebOrMobilCheck extends StatelessWidget {
  const WebOrMobilCheck({super.key});

  @override
  Widget build(final BuildContext context) {
    if (kIsWeb) // Web ise
      return const WebTabNavigation();
    else // Mobil ise
      return const BottomNavBar();
  }
}
