import 'package:flutter/material.dart';
import 'package:ticketapp/shared/navigation/widgets/bottom_nav_bar.dart';

// Mobil için kullanılacak ana widget'ı döndürür
class AppHomePage extends StatelessWidget {
  final bool startAnimations;

  const AppHomePage({
    super.key,
    this.startAnimations = false,
  });

  @override
  Widget build(final BuildContext context) => const BottomNavBar();
}
