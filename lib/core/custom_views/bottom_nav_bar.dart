import 'package:flutter/material.dart';
import '../../presentation/pages/main_pages/discovery.dart';
import '../../presentation/pages/main_pages/nearby_events.dart';
import '../../presentation/pages/main_pages/profile_page.dart';
import '../../presentation/pages/main_pages/home_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavBar extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const BottomNavBar({super.key, required this.onThemeChanged});

  // Bu fonksiyon, dışarıdan BottomNavBar'daki sekmeyi değiştirmek için kullanılacak
  static _BottomNavBarState? of(BuildContext context) =>
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
      ProfilePage(onThemeChanged: widget.onThemeChanged),
    ];
  }

  // Bu metot ile sekme değiştirebiliriz ve başlık gönderebiliriz
  void changeTabWithCategory(int index, String? categoryTitle) {
    setState(() {
      _selectedIndex = index;
      selectedCategoryTitle = categoryTitle; // Seçilen başlığı sakla
      _pages[1] = DiscoveryPage(selectedCategory: selectedCategoryTitle);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavBarTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilet Satış Uygulaması'),
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Align(
            alignment: Alignment.bottomCenter,
            child: CurvedNavigationBar(
              backgroundColor: Colors.transparent,
              color: bottomNavBarTheme.selectedItemColor!,
              buttonBackgroundColor: bottomNavBarTheme.selectedItemColor!,
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
              onTap: _onItemTapped
            )
          )
        ]
      )
    );
  }
}