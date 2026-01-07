import 'package:flutter/material.dart';
import 'package:ticketapp/shared/navigation/widgets/mobile_bottom_nav_bar.dart';
import '../../../../../shared/navigation/providers/navigation_keys.dart';

// Mobil için kullanılacak ana widget'ı döndürür
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(final BuildContext context) =>
      MobileBottomNavBar(key: NavigationKeys.mobileNavKey);
}
