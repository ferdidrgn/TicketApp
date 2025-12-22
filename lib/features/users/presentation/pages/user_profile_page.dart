import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../appTools/presentation/pages/contracts.dart';
import '../../../favorite/presentation/pages/favorite_screen.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';
import '../../../settings/presentation/pages/app_settings.dart';
import '../../../settings/presentation/pages/permission_settings.dart';
import '../../../tickets/presentation/pages/my_ticket_page.dart';
import '../providers/user_provider.dart';
import 'user_profile_edit.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _localUserData;
  bool _isLoadingLocalData = true;

  late AnimationController _glowController;
  late AnimationController _badgeRotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _badgeRotation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLocalUserData();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _badgeRotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _badgeRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _badgeRotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _badgeRotateController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalUserData() async {
    try {
      await LocalStorageService.init();
      final userData = LocalStorageService.getEssentialUserData();
      setState(() {
        _localUserData = userData;
        _isLoadingLocalData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocalData = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;
    final colors = context.colors;
    final isDark = theme.brightness == Brightness.dark;

    if (loginState.isLoading || _isLoadingLocalData)
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // ARKA PLAN
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(isDark ? 0.15 : 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withOpacity(isDark ? 0.15 : 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // İÇERİK
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(theme),
                const SizedBox(height: 20),

                // YENİ: LÜKS PROFİL KARTI
                _buildLuxuryProfileCard(loginState.user, theme, loginState),
                const SizedBox(height: 40),

                _buildThemeSelectorArtistic(ref, theme),
                const SizedBox(height: 32),

                _buildFunctionalSection(loginState, theme),
                const SizedBox(height: 32),

                _buildSecuritySection(loginState, theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(final ThemeData theme) {
    return Column(
      children: [
        Text(
          'SANAT GALERİSİ',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: theme.colorScheme.primary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profil Koleksiyonun',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // YENİ: LÜKS PROFİL KARTI
  Widget _buildLuxuryProfileCard(
    final User? firebaseUser,
    final ThemeData theme,
    final LoginState loginState,
  ) {
    final isGuest = loginState.isGuest;
    final displayName = firebaseUser?.displayName ??
        _localUserData?['displayName'] ??
        'Sanat Sever';
    final email = firebaseUser?.email ?? 'sergi@ticketapp.com';
    final photoURL = firebaseUser?.photoURL ??
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=500&auto=format&fit=crop';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.9),
            theme.colorScheme.surface.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 25),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekoratif köşe çizgileri
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  top: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Ana içerik
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                // Üst rozetler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPremiumBadge(theme),
                    _buildLevelBadge(theme, 'VIP', Colors.amber),
                    _buildActivityBadge(theme, 'Aktif', Colors.green),
                  ],
                ),
                const SizedBox(height: 30),

                // Profil resmi ve etrafındaki sanatsal elementler
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dış halka efekti
                    AnimatedBuilder(
                      animation: _badgeRotation,
                      builder: (final context, final child) {
                        return Transform.rotate(
                          angle: _badgeRotation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Orta halka
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Profil fotoğrafı
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          photoURL,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Köşe süsleri
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _buildCornerIcon(Icons.star, Colors.amber, theme),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child:
                          _buildCornerIcon(Icons.brush, Colors.purple, theme),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Kullanıcı bilgileri
                Column(
                  children: [
                    Text(
                      displayName.toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Playfair',
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Sanatsal ayraç
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 25),

                // ROZET KOLEKSİYONU
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ROZET KOLEKSİYONU',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Rozetler grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildArtBadge(
                            '🎨 Sanat Uzmanı',
                            Icons.palette,
                            Colors.deepPurple,
                            theme,
                            isActive: true,
                          ),
                          _buildArtBadge(
                            '🏛️ Sergi Gezgin',
                            Icons.museum,
                            Colors.blue,
                            theme,
                            isActive: true,
                          ),
                          _buildArtBadge(
                            '🎟️ Bilet Koleksiyoncu',
                            Icons.confirmation_number,
                            Colors.green,
                            theme,
                            isActive: true,
                          ),
                          _buildArtBadge(
                            '❤️ Favori Avcısı',
                            Icons.favorite,
                            Colors.pink,
                            theme,
                            isActive: false,
                          ),
                          _buildArtBadge(
                            '⚡ Hızlı Gezgin',
                            Icons.flash_on,
                            Colors.orange,
                            theme,
                            isActive: true,
                          ),
                          _buildArtBadge(
                            '🌟 Yıldız Koleksiyoncu',
                            Icons.stars,
                            Colors.amber,
                            theme,
                            isActive: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // İstatistikler
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('247', 'Bilet', Icons.confirmation_number,
                          theme.colorScheme.primary),
                      _buildStatItem('38', 'Favori', Icons.favorite,
                          theme.colorScheme.secondaryContainer.withRed(190)),
                      _buildStatItem('12', 'Sergi', Icons.museum,
                          theme.colorScheme.secondaryContainer.withRed(150)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge(final ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade300,
            Colors.amber.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(
      final ThemeData theme, final String level, final Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBadge(
      final ThemeData theme, final String status, final Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerIcon(
      final IconData icon, final Color color, final ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildArtBadge(final String title, final IconData icon,
      final Color color, final ThemeData theme,
      {final bool isActive = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.1)
            : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive
              ? color.withOpacity(0.3)
              : theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isActive ? color : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: isActive
                  ? color
                  : theme.colorScheme.onSurface.withOpacity(0.3),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(final String value, final String label,
      final IconData icon, final Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            // Opacity yok, direkt temanın ana yazı rengi (Beyaz veya Siyah)
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // İşlevsel bölüm (değişmeden)
  Widget _buildFunctionalSection(
      final LoginState loginState, final ThemeData theme) {
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> functionalButtons = [
      if (loginState.user != null)
        {
          'title': 'Profil Portresi',
          'subtitle': 'Portreni düzenle',
          'icon': Icons.edit_outlined,
          'color': const Color(0xFF64B5F6),
          'onTap': () =>
              _navigateTo(UserProfileEditScreen(userId: loginState.user!.uid)),
          'artMetaphor': '🎨 Fırça',
        },
      if (loginState.user != null)
        {
          'title': 'Bilet Arşivi',
          'subtitle': 'Geçmiş biletlerin',
          'icon': Icons.confirmation_number_outlined,
          'color': const Color(0xFF81C784),
          'onTap': () =>
              _navigateTo(MyTicketPage(userId: loginState.user!.uid)),
          'artMetaphor': '📜 Parşömen',
        },
      if (loginState.user != null)
        {
          'title': 'Favori Koleksiyon',
          'subtitle': 'Beğendiğin eserler',
          'icon': Icons.favorite_border,
          'color': const Color(0xFFF06292),
          'onTap': () => _navigateTo(FavoritesPage()),
          'artMetaphor': '❤️ Kalp',
        },
      {
        'title': 'Ayarlar',
        'subtitle': 'Uygulama ayarları',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFFFFB74D),
        'onTap': () => _navigateTo(const AppSettingsPage()),
        'artMetaphor': '⚙️ Dişli',
      },
      {
        'title': 'İzinler',
        'subtitle': 'Bildirim ayarları',
        'icon': Icons.notifications_outlined,
        'color': const Color(0xFFBA68C8),
        'onTap': () => _navigateTo(const PermissionSettingsScreen()),
        'artMetaphor': '🔔 Zil',
      },
      {
        'title': 'Sözleşmeler',
        'subtitle': 'Gizlilik ve güvenlik',
        'icon': Icons.privacy_tip_outlined,
        'color': const Color(0xFF7986CB),
        'onTap': () => _navigateTo(const ContractsPage()),
        'artMetaphor': '📄 Kontrat',
      },
      {
        'title': 'Yardım',
        'subtitle': 'SSS ve destek',
        'icon': Icons.help_outline,
        'color': const Color(0xFF4DB6AC),
        'onTap': () {},
        'artMetaphor': '❓ Soru',
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colors.surface,
        border: Border.all(
          color: colors.onSurface.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(isDark ? 0.6 : 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                  child: Row(
                    children: [
                      Icon(Icons.brush, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Sanat Atölyesi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: functionalButtons.length,
                  separatorBuilder: (final context, final index) => Padding(
                    padding: const EdgeInsets.only(left: 70),
                    child: Divider(
                      height: 1,
                      color: colors.outline.withOpacity(0.1),
                    ),
                  ),
                  itemBuilder: (final context, final index) {
                    final button = functionalButtons[index];
                    return _buildFunctionalButton(
                      title: button['title'] as String,
                      subtitle: button['subtitle'] as String,
                      icon: button['icon'] as IconData,
                      color: button['color'] as Color,
                      onTap: button['onTap'] as VoidCallback,
                      artMetaphor: button['artMetaphor'] as String,
                      theme: theme,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionalButton({
    required final String title,
    required final String subtitle,
    required final IconData icon,
    required final Color color,
    required final VoidCallback onTap,
    required final String artMetaphor,
    required final ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  artMetaphor,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tema seçici (değişmeden)
  Widget _buildThemeSelectorArtistic(
      final WidgetRef ref, final ThemeData theme) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(isDark ? 0.6 : 0.8),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined,
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sergi Işığı',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentTheme == ThemeMode.light
                            ? 'Gün Işığı'
                            : currentTheme == ThemeMode.dark
                                ? 'Gece Işığı'
                                : 'Otomatik',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildThemeButton('Gün', ThemeMode.light,
                            Icons.wb_sunny_rounded, ref)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildThemeButton('Gece', ThemeMode.dark,
                            Icons.nights_stay_rounded, ref)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildThemeButton('Oto', ThemeMode.system,
                            Icons.hdr_auto_rounded, ref)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(final String label, final ThemeMode mode,
      final IconData icon, final WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = ref.watch(themeProvider) == mode;

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color:
              isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Güvenlik bölümü (değişmeden)
  Widget _buildSecuritySection(
      final LoginState loginState, final ThemeData theme) {
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'GÜVENLİK',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          if (loginState.user != null) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.orange.withOpacity(0.05),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _signOut(),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sergiden Çıkış Yap',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'Güvenli çıkış',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.orange.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.red.withOpacity(0.05),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDeleteAccountDialog(loginState.user!.uid),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Koleksiyonu Sil',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'Hesabı kalıcı kapat',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.red.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToLogin(),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sergiye Giriş Yap',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Hesabına eriş',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Kalan fonksiyonlar değişmeden kalacak
  String _getLoginMethod(final User? firebaseUser) {
    if (firebaseUser == null) return 'anonymous';
    if (firebaseUser.providerData
        .any((final p) => p.providerId == 'google.com')) return 'google';
    if (firebaseUser.providerData.any((final p) => p.providerId == 'phone'))
      return 'phone';
    return 'anonymous';
  }

  IconData _getLoginMethodIcon(final String method) {
    switch (method) {
      case 'google':
        return Icons.g_mobiledata_rounded;
      case 'phone':
        return Icons.phone_android;
      case 'anonymous':
        return Icons.person_outline;
      default:
        return Icons.login;
    }
  }

  Color _getLoginMethodColor(final String method) {
    switch (method) {
      case 'google':
        return Colors.blue;
      case 'phone':
        return Colors.green;
      case 'anonymous':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _navigateTo(final Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (final _) => page));

  void _navigateToLogin() =>
      Navigator.of(context).pushReplacementNamed('/login');

  Future<void> _signOut() async {
    try {
      await ref.read(loginProvider.notifier).signOut();
      await _loadLocalUserData();
      _navigateToLogin();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yaparken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(final String userId) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[800]),
            const SizedBox(width: 12),
            Text(
              'Koleksiyonu Temizle',
              style: TextStyle(
                color: Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm sanat koleksiyonunuzu kalıcı olarak silmek istiyor musunuz?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Kalıcı Kayıp:',
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Tüm kişisel verileriniz silinecek\n'
                    '• Bilet koleksiyonunuz kaybolacak\n'
                    '• Favori sergileriniz silinecek\n'
                    '• Bu işlem geri alınamaz!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700]!.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'VAZGEÇ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(userId);
            },
            child: const Text('TÜMÜNÜ SİL'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(final String userId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => CustomLoadingDialog(
        message: 'Koleksiyon temizleniyor...',
      ),
    );

    try {
      final userNotifier = ref.read(userProvider.notifier);
      final bool isDeleteUserDocument = await userNotifier.deleteUser(userId);

      if (!isDeleteUserDocument) {
        _closeDialogAndShowError('Koleksiyon temizlenemedi');
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        await LocalStorageService.clearAllUserData();
        ref.read(loginProvider.notifier).clearLoginState();
        ref.read(userProvider.notifier).clearUserState();
      }

      _closeDialogAndShowSuccess();
    } catch (e) {
      _closeDialogAndShowError('Silme işlemi sırasında hata: $e');
    }
  }

  void _closeDialogAndShowError(final String message) {
    if (context.mounted) {
      Navigator.of(context).pop();
      _showErrorDialog(message);
    }
  }

  void _closeDialogAndShowSuccess() {
    if (context.mounted) {
      Navigator.of(context).pop();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final context) => CustomSuccessDialog(
          message: 'Koleksiyonunuz başarıyla temizlendi',
          onConfirm: () => _navigateToLogin(),
        ),
      );

  void _showErrorDialog(final String message) => showDialog(
        context: context,
        builder: (final context) => CustomErrorDialog(
          message: message,
          onConfirm: () => Navigator.pop(context),
        ),
      );
}
