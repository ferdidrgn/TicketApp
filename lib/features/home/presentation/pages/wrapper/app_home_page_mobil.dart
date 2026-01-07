import 'package:flutter/material.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_mobile.dart';
import 'package:ticketapp/shared/navigation/providers/navigation_keys.dart';

class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(final BuildContext context) =>
      HomePage(key: NavigationKeys.mobileNavKey);
}
