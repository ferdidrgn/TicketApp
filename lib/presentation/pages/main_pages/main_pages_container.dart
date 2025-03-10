import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/bottom_nav_bar.dart';

class HomePageContainer extends StatelessWidget {
  const HomePageContainer({super.key});

  @override
  Widget build(final BuildContext context) {
    return const Scaffold(body: BottomNavBar());
  }
}
