import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../pages/bottom_nav_pages/discovery_page.dart';
import '../pages/bottom_nav_pages/home_page.dart';
import '../pages/bottom_nav_pages/nearby_events_page.dart';
import '../pages/bottom_nav_pages/profile_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  // Bu fonksiyon, dışarıdan BottomNavBar'daki sekmeyi değiştirmek için kullanılacak
  static _BottomNavBarState? of(final BuildContext context) =>
      context.findAncestorStateOfType<_BottomNavBarState>();

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  String? selectedCategoryTitle;

  void changeTabWithCategory(final int index, final String? categoryTitle) {
    setState(() {
      _selectedIndex = index;
      selectedCategoryTitle = categoryTitle;
    });
  }

  void _onItemTapped(final int index) => setState(() => _selectedIndex = index);

  List<Widget> get _pages => [
        const HomePage(),
        DiscoveryPage(selectedCategory: selectedCategoryTitle),
        const NearbyEventsPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(final BuildContext context) {
    final bottomNavBarTheme = Theme.of(context).bottomNavigationBarTheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TiyatRol ',
          style: textTheme.headlineLarge
              ?.copyWith(fontSize: 30, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      extendBody: true, //BottomNavBar background transparent
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: bottomNavBarTheme.selectedItemColor!,
        buttonBackgroundColor: bottomNavBarTheme.selectedItemColor,
        height: 50,
        items: const [
          Icon(Icons.home, size: 30),
          Icon(Icons.event_seat_sharp, size: 30),
          Icon(Icons.location_city, size: 30),
          Icon(Icons.people, size: 30),
        ],
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        index: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
