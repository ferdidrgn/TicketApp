import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/services/sign_out_delete.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';
import '../../../settings/presentation/pages/app_settings.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with
        TickerProviderStateMixin,
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler,
        ProfilePhoneLinkHandler,
        ProfileGoogleLinkHandler {
  late AnimationController _sparkleController;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _breathController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;
    final bool isUserLoggedIn = loginState.isLoggedIn && !loginState.isGuest;

    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn)
        context.go('/login');
      if (next.isAccountDeleted) context.go('/login');
    });

    final Color bgColor = theme.colorScheme.surface;
    final Color lightShadow = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.white;
    final Color darkShadow = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.5)
        : Colors.grey.withOpacity(0.2);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildMagicDust(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Başlık - Optimize Edilmiş
                  _buildArtisticHeader(theme, isUserLoggedIn),
                  const SizedBox(height: 30),

                  // Profil Kartı - Boyutları Ayarlanmış
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.88,
                    child: _buildExpandedCuratorCard(loginState, theme, bgColor,
                        lightShadow, darkShadow, isUserLoggedIn),
                  ),

                  const SizedBox(height: 32),

                  // Ruh Hali Bölümü
                  _buildSectionHeader(
                      theme, "RUH HALİNİ YANSIT", "Görünümünü özelleştir"),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.88,
                    child: ThemeSelectorCard(),
                  ),

                  const SizedBox(height: 32),

                  // Yolculuk Kayıtları - Grid Boyutları Ayarlanmış
                  _buildSectionHeader(
                      theme, "YOLCULUK KAYITLARI", "Koleksiyonunun izleri"),
                  const SizedBox(height: 16),
                  _buildMagicActionGrid(loginState, theme, !isUserLoggedIn,
                      bgColor, lightShadow, darkShadow),

                  const SizedBox(height: 32),

                  // Gizem ve Güvenlik - Daha Az Yükseklik
                  _buildSectionHeader(
                      theme, "GİZEM VE GÜVENLİK", "Sessiz kararların"),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.88,
                    child: _buildSecuritySection(
                        loginState, theme, bgColor, lightShadow, darkShadow),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- OPTİMİZE BAŞLIK ---
  Widget _buildArtisticHeader(ThemeData theme, bool isLoggedIn) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _breathAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'BAKMANIN DEĞİL, GÖRMENİN HİKAYESİ',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 3,
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.primary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isLoggedIn
              ? 'Estetik Hafıza • Senin Başyapıtın'
              : 'Ziyaretçi Ruhu • Keşif Modu',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.withOpacity(0.6),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // --- GENİŞLETİLMİŞ KÜRATÖR KARTI (OPTİMİZE) ---
  Widget _buildExpandedCuratorCard(LoginState state, ThemeData theme, Color bg,
      Color light, Color dark, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _neuBox(bg, light, dark, borderRadius: 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Işık halkası
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 1.0],
                  ),
                ),
              ),

              // Avatar
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: isLoggedIn
                      ? OptimizedCachedImage(
                          imageUrl: state.photoUrl ??
                              'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: bg,
                          child: Icon(
                            Icons.fingerprint,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isLoggedIn
                ? (state.displayName ?? 'İSİMSİZ SANATÇI').toUpperCase()
                : "MİSAFİR RUH",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoggedIn
                ? (state.email ?? "küratör@sanat.com")
                : "Keşif Modu Aktif",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLoggedIn ? "Kıdemli Küratör" : "Keşfedilmeyi Bekleyen Ruh",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // İstatistikler - Daha Kompakt
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: bg.withOpacity(0.5),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                    "Bilet", "12", Icons.confirmation_number_outlined),
                _buildMiniStat(
                    "Anı", "42", Icons.collections_bookmark_outlined),
                _buildMiniStat("Puan", "8.9", Icons.auto_fix_high),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SİHİRLİ IZGARA (GRID) - OPTİMİZE ---
  Widget _buildMagicActionGrid(LoginState state, ThemeData theme, bool isGuest,
      Color bg, Color light, Color dark) {
    final double gridWidth = MediaQuery.of(context).size.width * 0.9;

    return SizedBox(
      width: gridWidth,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        // Daha düşük oran
        children: [
          _magicTile("Atölyem", Icons.brush_outlined, theme, bg, light, dark,
              () => context.push('/profile-edit/${state.userId}')),
          _magicTile("Giriş Kartları", Icons.vpn_key_outlined, theme, bg, light,
              dark, () => context.push('/my-tickets/${state.userId}')),
          _magicTile("Koleksiyon", Icons.auto_awesome_mosaic_outlined, theme,
              bg, light, dark, () {}),
          _magicTile(
              "Ayarlar",
              Icons.settings_input_component_outlined,
              theme,
              bg,
              light,
              dark,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) => const AppSettingsPage()))),
        ],
      ),
    );
  }

  // --- GÜVENLİK BÖLÜMÜ - OPTİMİZE ---
  Widget _buildSecuritySection(
      LoginState state, ThemeData theme, Color bg, Color light, Color dark) {
    return Column(
      children: [
        if (state.isGuest) ...[
          _neuTile(
            theme,
            "Görünmezlik Modu (Google)",
            Icons.account_circle_outlined,
            bg,
            light,
            dark,
            () => handleGoogleLink(context, ref),
            subtitle: "Kalıcı bağlantı kur",
          ),
          const SizedBox(height: 12),
        ],
        _neuTile(
          theme,
          "Veda Et (Çıkış)",
          Icons.logout_rounded,
          bg,
          light,
          dark,
          () => showSignOutDialog(context, ref),
          subtitle: "Oturumu kapat",
        ),
        const SizedBox(height: 12),
        _neuTile(
          theme,
          "Hafızayı Sil (Hesabı Sil)",
          Icons.no_accounts_outlined,
          bg,
          light,
          dark,
          () => showDeleteAccountDialog(context, ref, state.userId ?? ''),
          subtitle: "Tüm izleri temizle",
          isError: true,
        ),
      ],
    );
  }

  // --- YARDIMCI METODLAR ---

  BoxDecoration _neuBox(Color bg, Color light, Color dark,
      {double borderRadius = 15, bool isPressed = false}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                  color: dark,
                  offset: const Offset(3, 3),
                  blurRadius: 5,
                  spreadRadius: -1),
              BoxShadow(
                  color: light,
                  offset: const Offset(-3, -3),
                  blurRadius: 5,
                  spreadRadius: -1),
            ]
          : [
              BoxShadow(
                color: dark,
                offset: const Offset(8, 8),
                blurRadius: 16,
                spreadRadius: -2, // Yayılmayı azalt
              ),
              BoxShadow(
                color: light,
                offset: const Offset(-8, -8),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
    );
  }

  Widget _magicTile(String title, IconData icon, ThemeData theme, Color bg,
      Color light, Color dark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _neuBox(bg, light, dark, borderRadius: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _neuTile(
    ThemeData theme,
    String title,
    IconData icon,
    Color bg,
    Color light,
    Color dark,
    VoidCallback onTap, {
    String subtitle = "",
    bool isError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: _neuBox(bg, light, dark, borderRadius: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isError ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isError ? Colors.red : null,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isError
                  ? Colors.red.withOpacity(0.6)
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.withOpacity(0.7)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMagicDust() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: 0.3,
            child: CustomPaint(
              painter: _SparklePainter(_sparkleController.value),
              size: MediaQuery.of(context).size,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title,
      [String subtitle = ""]) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              letterSpacing: 2,
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final random = Random(42);
    for (int i = 0; i < 15; i++) {
      // Daha az parçacık
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height * 0.7) +
          (progress * 50); // Daha az hareket
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
