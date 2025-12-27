import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../features/discovery/presentation/pages/discovery_page.dart';
import '../../../features/discovery/presentation/pages/nearby_events_page.dart';
import '../../../features/home/presentation/pages/home_page_mobile.dart';
import '../../../features/users/presentation/pages/profile_page.dart';

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

  void changeTabWithCategory(final int index, final String? categoryTitle) =>
      setState(() {
        _selectedIndex = index;
        selectedCategoryTitle = categoryTitle;
      });

  void _onItemTapped(final int index) => setState(() => _selectedIndex = index);

  List<Widget> get _pages => [
        const HomePage(),
        DiscoveryPage(selectedCategory: selectedCategoryTitle),
        const NearbyEventsPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(final BuildContext context) {
    final bool isDark = context.isDarkMode;
    // Temadaki navigasyon barı rengini alıyoruz
    final navTheme = context.theme.bottomNavigationBarTheme;
    final Color barColor =
        navTheme.selectedItemColor ?? context.theme.primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Alt barı tamamen şeffaf yapıyoruz
        systemNavigationBarColor: barColor,
        systemNavigationBarDividerColor: Colors.transparent,
        // Alt bar üzerindeki tuşların rengini ayarlıyoruz
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'TiyatRol ',
            style: context.textTheme.headlineLarge
                ?.copyWith(fontSize: 30, color: Colors.white),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          top: false, // Üstten boşluk bırakma
          child: CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: navTheme.selectedItemColor ?? context.theme.primaryColor,
            buttonBackgroundColor:
                navTheme.selectedItemColor ?? context.theme.primaryColor,
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
