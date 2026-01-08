import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class MobileBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MobileBottomNavBar({super.key, required this.navigationShell});

  @override
  State<MobileBottomNavBar> createState() => MobileBottomNavBarState();
}

class MobileBottomNavBarState extends State<MobileBottomNavBar> {
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
    final Color vibrantColor = context.isDarkMode
        ? context.colors
            .primaryContainer // Veya AppLightColors.primary diyerek zorla o rengi ver
        : context.colors.primary;

    final Color systemBarColor = context.isDarkMode
        ? Colors.black // Dark modda alt taraf siyah kalsın, bar ile karışmasın
        : vibrantColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          systemNavigationBarColor: systemBarColor,
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
            index: widget.navigationShell.currentIndex,
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
