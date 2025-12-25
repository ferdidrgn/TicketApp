import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../features/discovery/presentation/pages/discovery_page.dart';
import '../../../features/discovery/presentation/pages/nearby_events_page.dart';
import '../../../features/home/presentation/pages/home_page_mobile.dart';
import '../../../features/users/presentation/pages/user_profile_page.dart';

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
  Widget build(final BuildContext context) => Scaffold(
        extendBody: true, // İçeriğin barın arkasına geçmesi için true kalmalı
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
        bottomNavigationBar: Container(
          // Rengi temadan alıyoruz, yoksa fallback olarak ana rengi kullanıyoruz
          color: Colors.transparent,
          child: SafeArea(
            // Sadece alt kısımdaki sistem çizgisinden kaçıyoruz Sistem navigasyon barının yüksekliğini alıyoruz
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 10),
              child: CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color:
                    context.theme.bottomNavigationBarTheme.selectedItemColor ??
                        context.theme.primaryColor,
                buttonBackgroundColor:
                    context.theme.bottomNavigationBarTheme.selectedItemColor ??
                        context.theme.primaryColor,
                height: 60,
                // 50 çok dardı, 60 daha ergonomik
                index: _selectedIndex,
                items: const [
                  Icon(Icons.home, size: 30, color: Colors.white),
                  Icon(Icons.event_seat_sharp, size: 30, color: Colors.white),
                  Icon(Icons.location_city, size: 30, color: Colors.white),
                  Icon(Icons.people, size: 30, color: Colors.white),
                ],
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 600),
                onTap: _onItemTapped,
              ),
            ),
          ),
        ),
      );
}
