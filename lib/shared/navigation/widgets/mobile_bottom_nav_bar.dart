import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

class MobileBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MobileBottomNavBar({super.key, required this.navigationShell});

  @override
  State<MobileBottomNavBar> createState() => MobileBottomNavBarState();
}

class MobileBottomNavBarState extends State<MobileBottomNavBar> {
  final GlobalKey<CurvedNavigationBarState> _navKey =
      GlobalKey<CurvedNavigationBarState>();

  // 🔧 FIX: Direkt route paths tanımla
  static const List<String> _routePaths = [
    '/app', // 0: Ana Sayfa
    '/discover', // 1: Keşfet
    '/nearby', // 2: Yakındakiler
    '/profile', // 3: Profil
  ];

  // 🔧 FIX: Mevcut index'i route'dan hesapla
  int get _currentIndex {
    final location = GoRouterState.of(context).uri.path;

    // Tam eşleşme kontrol et
    for (int i = 0; i < _routePaths.length; i++)
      if (location == _routePaths[i]) return i;

    // Fallback: navigationShell index
    return widget.navigationShell.currentIndex;
  }

  void _onItemTapped(final int index) {
    if (index < 0 || index >= _routePaths.length) return;

    // 🔧 FIX: Direkt context.go() kullan - goBranch() yerine
    final targetPath = _routePaths[index];

    // Aynı sayfadaysa refresh yap
    if (_currentIndex == index) {
      HapticFeedback.mediumImpact();
      context.go(targetPath);
    } else {
      HapticFeedback.selectionClick();
      context.go(targetPath);
    }

    // UI güncelleme
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _navKey.currentState?.setPage(index);
    });
  }

  /// 🔑 DIŞARıDAN category ile Discover'a geçiş
  void goToDiscoverWithCategory(final String category) {
    context.go('/discover?category=$category');

    WidgetsBinding.instance
        .addPostFrameCallback((final _) => _navKey.currentState?.setPage(1));
  }

  @override
  Widget build(final BuildContext context) {
    final Color vibrantColor = context.isDarkMode
        ? context.colors.secondaryContainer
        : context.colors.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          systemNavigationBarColor: vibrantColor,
          systemNavigationBarDividerColor: Colors.transparent,
          // Alt bar üzerindeki tuşların rengini ayarlıyoruz
          systemNavigationBarIconBrightness:
              context.isDarkMode ? Brightness.light : Brightness.dark),
      child: Scaffold(
        extendBody: true,

        // ❗️ IndexedStack YOK
        /*body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),*/
        body: widget.navigationShell,
        bottomNavigationBar: SafeArea(
          top: false, // Üstten boşluk bırakma
          child: CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: vibrantColor,
            buttonBackgroundColor: vibrantColor,
            height: 60,
            key: _navKey,
            index: _currentIndex,
            // 🔧 FIX: Dinamik index hesaplama
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
