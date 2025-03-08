import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/bottom_nav_bar.dart';

class HomePageContainer extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomePageContainer({super.key, required this.onThemeChanged});

  @override
  _HomePageContainerState createState() => _HomePageContainerState();
}

class _HomePageContainerState extends State<HomePageContainer> {
  @override
  Widget build(final BuildContext context) {
    return Scaffold(body: BottomNavBar(onThemeChanged: widget.onThemeChanged));
  }
}
