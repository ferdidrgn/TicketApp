// lib/router//app_home_page_web.dart
import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/navigation/web_tab_navigation.dart';

// Web için kullanılacak ana widget'ı döndürür
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(final BuildContext context) => const WebTabNavigation();
}
