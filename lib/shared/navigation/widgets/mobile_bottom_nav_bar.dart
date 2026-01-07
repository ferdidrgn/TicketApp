import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/discovery/presentation/pages/discovery_page.dart';
import 'package:ticketapp/features/discovery/presentation/pages/nearby_events_page.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_mobile.dart';
import 'package:ticketapp/features/users/presentation/pages/profile_page.dart';

/// 🔑 DIŞARIDAN ERİŞİM İÇİN GLOBAL KEY
final GlobalKey<MobileBottomNavBarState> bottomNavBarKey =
    GlobalKey<MobileBottomNavBarState>();

class MobileBottomNavBar extends StatefulWidget {
  const MobileBottomNavBar({super.key});

  @override
  MobileBottomNavBarState createState() => MobileBottomNavBarState();
}

class MobileBottomNavBarState extends State<MobileBottomNavBar> {
  int _selectedIndex = 0;
  String? _selectedCategory;

  final GlobalKey<CurvedNavigationBarState> _navKey =
      GlobalKey<CurvedNavigationBarState>();

  void changeTabWithCategory(final int index, final String? category) {
    debugPrint('➡️ changeTabWithCategory: $index | $category');

    setState(() {
      _selectedIndex = index;
      _selectedCategory = category;
    });

    // CurvedNavigationBar senkronu
    _navKey.currentState?.setPage(index);
  }

  void _onItemTapped(final int index) => setState(() {
        _selectedIndex = index;
        _selectedCategory = null; // manuel geçişte reset
      });

  List<Widget> get _pages => [
        const HomePage(),
        DiscoveryPage(selectedCategory: _selectedCategory),
        const NearbyEventsPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(final BuildContext context) {
    final barColor = context.theme.bottomNavigationBarTheme.selectedItemColor ??
        context.theme.colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: barColor,
        systemNavigationBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          child: CurvedNavigationBar(
            key: _navKey,
            index: _selectedIndex,
            height: 60,
            backgroundColor: Colors.transparent,
            color: barColor,
            buttonBackgroundColor: barColor,
            items: const [
              Icon(Icons.home, size: 30, color: Colors.white),
              Icon(Icons.event_seat_sharp, size: 30, color: Colors.white),
              Icon(Icons.location_city, size: 30, color: Colors.white),
              Icon(Icons.people, size: 30, color: Colors.white),
            ],
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
