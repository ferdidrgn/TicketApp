import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/discovery/presentation/pages/discovery_page.dart';
import 'package:ticketapp/features/discovery/presentation/pages/nearby_events_page.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_mobile.dart';
import 'package:ticketapp/features/users/presentation/pages/profile_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

/// 🔥 STATE ARTIK PUBLIC
class BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  String? selectedCategoryTitle;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ BottomNavBarState INIT');
  }

  /// 🔑 DIŞARIDAN ÇAĞRILAN METOT
  void changeTabWithCategory(int index, String? category) {
    debugPrint('➡️ changeTabWithCategory: $index | $category');
    setState(() {
      _selectedIndex = index;
      selectedCategoryTitle = category;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> get _pages => [
        const HomePage(),
        DiscoveryPage(selectedCategory: selectedCategoryTitle),
        const NearbyEventsPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    final navTheme = context.theme.bottomNavigationBarTheme;
    final barColor = navTheme.selectedItemColor ?? context.theme.primaryColor;

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
            backgroundColor: Colors.transparent,
            color: barColor,
            buttonBackgroundColor: barColor,
            height: 60,
            index: _selectedIndex,
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
