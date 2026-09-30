import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import 'ticket_nav_bar.dart';

/// 📱 MOBİL ALT GEZİNME
///
/// Eskiden `curved_navigation_bar` kullanılıyordu: etiketsiz beyaz ikonlar,
/// temanın vurgusuyla boyanmış kalın bir şerit ve seçili sekmede yukarı
/// fırlayan bir top — hangi sekmede olunduğu ve ikonların ne anlama geldiği
/// belli değildi. Artık temanın yüzeyinde sade bir çubuk: etiketler hep
/// görünür, aktif sekme dolu ikon + kalın etiket + çubuğun kenarına açılmış
/// "zımba çentiği" (bilet dili) ile işaretli (bkz. `TicketBottomNavBar`).
///
/// Navigasyon mantığı birebir korunuyor: sabit rota yolları + `context.go`,
/// aynı sekmeye tekrar dokununca yenileme, dokunsal geri bildirim ve
/// dışarıdan `goToDiscoverWithCategory`.
class MobileBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MobileBottomNavBar({super.key, required this.navigationShell});

  @override
  State<MobileBottomNavBar> createState() => MobileBottomNavBarState();
}

class MobileBottomNavBarState extends State<MobileBottomNavBar> {
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
  }

  /// 🔑 DIŞARıDAN category ile Discover'a geçiş
  void goToDiscoverWithCategory(final String category) {
    context.go('/discover?category=$category');
    // Çubuk rota değişiminde kabukla birlikte yeniden çizilir; ayrıca
    // elle sayfa ayarlamaya (eski `setPage`) gerek yok.
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Sistem gezinme şeridi çubukla aynı renkte — tek parça görünür.
        systemNavigationBarColor: cs.surfaceContainer,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        // Çubuk artık opak; içerik arkasına taşmaz, son satır çubuğun
        // altında kalmaz. Çentiğin içinden bu zemin görünür.
        extendBody: false,
        backgroundColor: cs.surface,
        body: widget.navigationShell,
        bottomNavigationBar: TicketBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
