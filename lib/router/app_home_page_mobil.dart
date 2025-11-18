// lib/router//app_home_page_mobil.dart
import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/mobil/navigation/bottom_nav_bar.dart';

// Mobil için kullanılacak ana widget'ı döndürür
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(final BuildContext context) => const BottomNavBar();
}
