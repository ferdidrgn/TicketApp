import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class MobileBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MobileBottomNavBar({super.key, required this.navigationShell});

  @override
  State<MobileBottomNavBar> createState() => _MobileBottomNavBarState();
}

class _MobileBottomNavBarState extends State<MobileBottomNavBar> {
  final GlobalKey<CurvedNavigationBarState> _navKey =
      GlobalKey<CurvedNavigationBarState>();

  void _onItemTapped(final int index) {
    widget.navigationShell.goBranch(index,
        initialLocation: index == widget.navigationShell.currentIndex);

    _navKey.currentState?.setPage(index);
  }

  /// 🔑 DIŞARIDAN category ile Discover’a geçiş
  void goToDiscoverWithCategory(final String category) {
    widget.navigationShell.goBranch(1);
    _navKey.currentState?.setPage(1);
  }

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

        // ❗️ IndexedStack YOK
        /*body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),*/
        body: widget.navigationShell,

        bottomNavigationBar: SafeArea(
          child: CurvedNavigationBar(
            key: _navKey,
            index: widget.navigationShell.currentIndex,
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
