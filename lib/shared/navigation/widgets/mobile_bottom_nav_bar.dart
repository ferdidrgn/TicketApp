import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/providers/account_deletion_provider.dart';
import '../../../features/auth/presentation/widgets/account_deletion_widgets.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import 'ticket_nav_bar.dart';

/// 📱 MOBİL ALT GEZİNME
///
/// E_Learning tarzı kayan daire: seçili sekmenin ikonu temanın `primary`
/// dairesinde, altında her zaman görünen etiket (Ana Sayfa / Keşfet /
/// Yakındakiler / Profil). Navigasyon: sabit rota + `context.go`, aynı
/// sekmeye tekrar dokununca yenileme, haptic, `goToDiscoverWithCategory`.
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
    context.go(
        '/discover?category=${Uri.encodeQueryComponent(category.trim())}');
    // Çubuk rota değişiminde kabukla birlikte yeniden çizilir; ayrıca
    // elle sayfa ayarlamaya (eski `setPage`) gerek yok.
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarIconBrightness:
            context.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        // Çubuk artık opak; içerik arkasına taşmaz, son satır çubuğun
        // altında kalmaz. Çentiğin içinden bu zemin görünür.
        extendBody: false,
        backgroundColor: cs.surface,
        // Silinmek üzere olan hesapta kalıcı şerit (yoksa görünmez).
        body: _ShellBody(child: widget.navigationShell),
        bottomNavigationBar: TicketBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

/// Kabuk gövdesi. Hesap silme beklerken üstte kalıcı şerit gösterir: şerit
/// durum çubuğunun altında durur ve alttaki sayfaların üst güvenli alanı
/// tekrar eklemesi engellenir. Bekleyen silme yoksa düzen hiç değişmez.
class _ShellBody extends ConsumerWidget {
  final Widget child;

  const _ShellBody({required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final pending = ref.watch(accountDeletionInfoProvider).value != null;
    // Yapı her durumda aynı kalır: şerit açılıp kapanırken sekmeler
    // (IndexedStack) yeniden kurulmaz.
    return Column(
      children: [
        pending
            ? const SafeArea(bottom: false, child: AccountDeletionBanner())
            : const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
              context: context, removeTop: pending, child: child),
        ),
      ],
    );
  }
}
