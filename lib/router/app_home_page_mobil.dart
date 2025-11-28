import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/mobil/navigation/bottom_nav_bar.dart';

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
