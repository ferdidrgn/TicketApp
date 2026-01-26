import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/reg_exp_extentions.dart';
import '../providers/navigation_keys.dart';

/// 🧭 Global Navigation Handler
/// Tüm uygulama genelinde navigasyon işlemlerini yönetir
class NavigationHandler {
  NavigationHandler._();

  static final NavigationHandler instance = NavigationHandler._();

  // ═══════════════════════════════════════════════════════════════
  // ROUTE HELPERS
  // ═══════════════════════════════════════════════════════════════

  static void goToLogin(final BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/login/?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  static void goToHome(final BuildContext context) => context.go('/');

  static void goToSearch(final BuildContext context) => context.go('/search');

  static void goToNearby(final BuildContext context) => context.go('/nearby');

  static void goToProfile(final BuildContext context) => context.go('/profile');

  static void goToDiscoverWithCategory(
          final BuildContext context, final String category) =>
      context.go('/discover?category=$category');

  /// Etkinlik detay sayfasına git (slug-id yapısı)
  static void goToShow(
      final BuildContext context, final String showId, final String showSlug) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/show/${showSlug.toSlug()}-$showId?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  /// Oyuncu detay sayfasına git
  static void goToPlayer(
    final BuildContext context,
    final String playerId,
    final String playerSlug,
  ) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/player/${playerSlug.toSlug()}-$playerId?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  /// Mekan/Sahne detay sayfasına git
  static void goToStage(
    final BuildContext context,
    final String stageId,
    final String stageSlug,
  ) {
    final String currentPath = GoRouterState.of(context).uri.path;
    // Slug kısmını temizleyip ID ile birleştiriyoruz
    final String targetPath =
        '/stage/${stageSlug.toSlug()}-$stageId?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  /// Ekip detay sayfasına git
  static void goToTeam(
    final BuildContext context,
    final String teamId,
    final String teamSlug,
  ) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/team/${teamSlug.toSlug()}-$teamId?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  /// Koltuk seçimi sayfasına git
  static void goToSeatSelection(final BuildContext context, final String showId,
      final String eventId, final String userId) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/seat-selection/$showId-$eventId-$userId?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  static void goToSettings(final BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/settings?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  static void goToFavorites(final BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/favorites?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  static void goToContracts(final BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/contracts?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  static void goToHelpSupport(final BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/help-support?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  /// Biletlerim sayfasına git (User ID'yi slug yaparak koruma amaçlı veya SEO amaçlı)
  static void goToMyTickets(
      final BuildContext context, final String currentUserId) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final String targetPath =
        '/my-tickets/${currentUserId.toSlug()}?from=${Uri.encodeComponent(currentPath)}';

    context.go(targetPath);
  }

  // ═══════════════════════════════════════════════════════════════
  // SMART BACK NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static void smartGoBack(final BuildContext context) {
    final state = GoRouterState.of(context);
    final fromRoute = state.uri.queryParameters['from'];

    if (fromRoute != null && fromRoute.isNotEmpty)
      context.go(Uri.decodeComponent(fromRoute));
    else {
      if (Navigator.canPop(context))
        Navigator.pop(context);
      else
        context.go('/');
    }
  }

  static bool canGoBack(final BuildContext context) {
    final state = GoRouterState.of(context);
    final fromRoute = state.uri.queryParameters['from'];
    return fromRoute != null || Navigator.canPop(context);
  }

  // ═══════════════════════════════════════════════════════════════
  // GLOBAL ERİŞİM & UTILITY
  // ═══════════════════════════════════════════════════════════════

  static NavigatorState? get _rootNav =>
      NavigationKeys.rootNavigator.currentState;

  static void globalGoTo(final String location) =>
      _rootNav?.context.go(location);

  static String getCurrentPath(final BuildContext context) =>
      GoRouterState.of(context).uri.path;

  static void scrollToWebSection(final String section) =>
      NavigationKeys.webBarKey.currentState?.scrollToSection(section);
}

/*
// ═══════════════════════════════════════════════════════════════
// 📚 KULLANIM ÖRNEKLERİ
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 1️⃣ GLASSMORPHISM BACK BUTTON
// ═══════════════════════════════════════════════════════════════

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sayfa içeriği
          YourContent(),

          // Geri butonu (sol üst)
          Positioned(
            top: 60,
            left: 20,
            child: GlassmorphismBackButton(),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// 2️⃣ GLASSMORPHISM ICON BUTTON
// ═══════════════════════════════════════════════════════════════

class MyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassmorphismBackButton(),
        Spacer(),

        // Favori butonu
        GlassmorphismIconButton(
          icon: Icons.favorite_border,
          onPressed: () {},
          backgroundColor: AppColors.error,
        ),
        SizedBox(width: 12),

        // Paylaş butonu
        GlassmorphismIconButton(
          icon: Icons.share_outlined,
          onPressed: () {},
          backgroundColor: AppColors.primary,
        ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// 3️⃣ GLASSMORPHISM APP BAR (Sticky Header)
// ═══════════════════════════════════════════════════════════════

class ProductDetailPage extends StatefulWidget {
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isScrolled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            // Scroll listener ekle
            controller: ScrollController()
              ..addListener(() {
                setState(() {
                  _isScrolled = scrollController.offset > 100;
                });
              }),
            slivers: [
              // Sayfa içeriği
            ],
          ),

          // Sticky header
          if (_isScrolled)
            GlassmorphismAppBar(
              title: 'Ürün Adı',
              subtitle: '₺1,299',
              showBackButton: true,
              actions: [
                GlassmorphismIconButton(
                  icon: Icons.favorite_border,
                  onPressed: () {},
                ),
              ],
            ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// 4️⃣ NAVIGATION HANDLER
// ═══════════════════════════════════════════════════════════════

import '../util/navigation_handler.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ürün detayına git
        NavigationHandler.goToProduct(
          context: context,
          productId: product.id,
          productSlug: product.name.toSlug(),
        );
      },
      child: ProductCardWidget(),
    );
  }
}

class CustomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Akıllı geri dön
        NavigationHandler.smartGoBack(context);
      },
      child: Text('Geri'),
    );
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arama'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Ana sayfaya git
            NavigationHandler.goToHome(context);
          },
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// 5️⃣ ÖZEL BUTON ÖRNEKLERİ
// ═══════════════════════════════════════════════════════════════

// Küçük geri butonu
GlassmorphismBackButton
(
size: 36,
backgroundColor: AppColors.primary,
)

// Büyük geri butonu
GlassmorphismBackButton(
size: 56,
backgroundColor: Colors.black,
iconColor: Colors.white,
)

// Border'sız geri butonu
GlassmorphismBackButton(
showBorder: false,
backgroundColor: AppColors.secondary,
)

// Custom action ile
GlassmorphismBackButton(
onPressed: () {
// Özel işlem
print('Custom back action');
Navigator.pop(context);
},
)


// ═══════════════════════════════════════════════════════════════
// 6️⃣ HERO HEADER ÖRNEĞI (Product Detail)
// ═══════════════════════════════════════════════════════════════

Widget buildProductHero() {
return Stack(
children: [
// Ana görsel
Image.network(product.imageUrl),

// Gradient overlay
Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.black.withOpacity(0.3),
Colors.transparent,
],
),
),
),

// Header butonları
SafeArea(
child: Padding(
padding: EdgeInsets.all(20),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
GlassmorphismBackButton(
backgroundColor: AppColors.primary,
),
Row(
children: [
GlassmorphismIconButton(
icon: Icons.favorite_border,
onPressed: () {},
backgroundColor: AppColors.primary,
),
SizedBox(width: 12),
GlassmorphismIconButton(
icon: Icons.share_outlined,
onPressed: () {},
backgroundColor: AppColors.primary,
),
],
),
],
),
),
),
],
);
}


// ═══════════════════════════════════════════════════════════════
// 7️⃣ FARKLI RENKLERLE KULLANIM
// ═══════════════════════════════════════════════════════════════

// Kırmızı (Error)
GlassmorphismIconButton(
icon: Icons.favorite,
backgroundColor: AppColors.error,
iconColor: Colors.white,
onPressed: () {},
)

// Yeşil (Success)
GlassmorphismIconButton(
icon: Icons.check_circle,
backgroundColor: AppColors.success,
iconColor: Colors.white,
onPressed: () {},
)

// Altın (Accent)
GlassmorphismIconButton(
icon: Icons.star,
backgroundColor: AppColors.accent,
iconColor: Colors.white,
onPressed: () {},
)

// Siyah
GlassmorphismIconButton(
icon: Icons.shopping_cart,
backgroundColor: Colors.black,
iconColor: Colors.white,
onPressed: () {},
)


// ═══════════════════════════════════════════════════════════════
// 📋 ÖZET
// ═══════════════════════════════════════════════════════════════

/*
✅ OLUŞTURDUK:
1. NavigationHandler - Global navigasyon yöneticisi
2. GlassmorphismBackButton - Buzlu cam geri butonu
3. GlassmorphismIconButton - Genel amaçlı buzlu cam buton
4. GlassmorphismAppBar - Sticky header

✅ ÖZELLİKLER:
- Glassmorphism (buzlu cam) efekt
- Hover animasyonu
- Tap animasyonu (basınca küçülme)
- Özelleştirilebilir renk ve boyut
- Responsive

✅ KULLANIM YERLERİ:
- Product detail header
- Sticky scroll header
- Modal header'ları
- Floating action buttons
- Gallery overlay
- Search sayfası
*/
*/
