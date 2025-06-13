import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../pages/bottom_nav_pages/discovery_page.dart';
import '../pages/bottom_nav_pages/home_screen.dart';
import '../pages/bottom_nav_pages/nearby_events.dart';
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
  String? selectedCategoryTitle; // DiscoveryPage'e aktarılacak başlık

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const HomeScreen(),
      DiscoveryPage(selectedCategory: selectedCategoryTitle),
      const NearbyEventsPage(),
      const ProfilePage(),
    ];
  }

  // Bu metot ile sekme değiştirebiliriz ve başlık gönderebiliriz
  void changeTabWithCategory(final int index, final String? categoryTitle) {
    setState(() {
      _selectedIndex = index;
      selectedCategoryTitle = categoryTitle; // Seçilen başlığı sakla
      _pages[1] = DiscoveryPage(selectedCategory: selectedCategoryTitle);
    });
  }

  void _onItemTapped(final int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final bottomNavBarTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilet Satış Uygulaması'),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: bottomNavBarTheme.selectedItemColor!,
        buttonBackgroundColor: bottomNavBarTheme.selectedItemColor,
        height: 50,
        items: const <Widget>[
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
