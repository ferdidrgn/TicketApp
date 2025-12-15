import 'dart:math';
import 'dart:ui'; // BackdropFilter için gerekli

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';
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

  // Animasyonları basitleştirdik, sadece hafif bir nefes alma efekti
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

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

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
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

    if (loginState.isLoading || _isLoadingLocalData) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // 1. MODERN ARKA PLAN (AMBIENT LIGHT)
          // Eski dalgalar yerine flu, soft renk geçişleri
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

          // 2. İÇERİK
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profil Başlığı
                _buildProfileHeader(theme),
                const SizedBox(height: 20),

                // Sanatsal Profil Kartı (DOKUNULMADI)
                _buildArtisticProfileCard(loginState.user, theme, loginState),
                const SizedBox(height: 40),

                // İŞLEVSEL BÖLÜM (YENİLENDİ: Glassmorphism & Clean)
                _buildFunctionalSection(loginState, theme),
                const SizedBox(height: 32),

                // TEMA AYARI (YENİLENDİ: Modern Pill Tasarımı)
                _buildThemeSelectorArtistic(ref, theme),
                const SizedBox(height: 32),

                // GÜVENLİK BÖLÜMÜ (YENİLENDİ: Minimal & Clean)
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

  // --- DOKUNULMAYAN ALAN BAŞLANGICI ---
  Widget _buildArtisticProfileCard(
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Tablo çerçevesi
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Tablonun askı ipi efekti
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[400]!,
                        Colors.grey[300]!,
                        Colors.grey[400]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Portre çerçevesi (antik çerçeve efekti)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.2),
                        theme.colorScheme.primary.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (final context, final child) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(photoURL),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.colorScheme.primary
                                      .withOpacity(0.1 * _glowAnimation.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sanatsal başlık
                Text(
                  displayName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Playfair',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Alt başlık
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Sanat etiketleri
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildArtTag('Sanat Sever', Icons.palette, Colors.blue),
                    _buildArtTag('Bilet Koleksiyonu', Icons.confirmation_number,
                        Colors.green),
                    if (!isGuest)
                      _buildArtTag(
                          _getLoginMethod(firebaseUser),
                          _getLoginMethodIcon(_getLoginMethod(firebaseUser)),
                          _getLoginMethodColor(_getLoginMethod(firebaseUser))),
                    if (isGuest)
                      _buildArtTag(
                          'Misafir Sergisi', Icons.person, Colors.orange),
                  ],
                ),

                // Tablo altı imzası
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 2,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'TicketApp Galerisi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Köşe süsleri
          Positioned(
            top: 20,
            right: 20,
            child: _buildCornerOrnament(),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildCornerOrnament(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtTag(
      final String text, final IconData icon, final Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerOrnament() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // --- DOKUNULMAYAN ALAN BİTİŞİ ---

  // İŞLEVSEL BÖLÜM - YENİ MODERN TASARIM
  Widget _buildFunctionalSection(
      final LoginState loginState, final ThemeData theme) {
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Ana işlevsel butonlar
    List<Map<String, dynamic>> functionalButtons = [
      if (loginState.user != null)
        {
          'title': 'Profil Portresi',
          'subtitle': 'Portreni düzenle',
          'icon': Icons.edit_outlined,
          'color': const Color(0xFF64B5F6), // Pastel Mavi
          'onTap': () =>
              _navigateTo(UserProfileEditScreen(userId: loginState.user!.uid)),
          'artMetaphor': '🎨 Fırça',
        },
      if (loginState.user != null)
        {
          'title': 'Bilet Arşivi',
          'subtitle': 'Geçmiş biletlerin',
          'icon': Icons.confirmation_number_outlined,
          'color': const Color(0xFF81C784), // Pastel Yeşil
          'onTap': () =>
              _navigateTo(MyTicketPage(userId: loginState.user!.uid)),
          'artMetaphor': '📜 Parşömen',
        },
      if (loginState.user != null)
        {
          'title': 'Favori Koleksiyon',
          'subtitle': 'Beğendiğin eserler',
          'icon': Icons.favorite_border,
          'color': const Color(0xFFF06292), // Pastel Pembe
          'onTap': () => _navigateTo(FavoritesPage()),
          'artMetaphor': '❤️ Kalp',
        },
      {
        'title': 'Ayarlar',
        'subtitle': 'Uygulama ayarları',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFFFFB74D), // Pastel Turuncu
        'onTap': () => _navigateTo(const AppSettingsPage()),
        'artMetaphor': '⚙️ Dişli',
      },
      {
        'title': 'İzinler',
        'subtitle': 'Bildirim ayarları',
        'icon': Icons.notifications_outlined,
        'color': const Color(0xFFBA68C8), // Pastel Mor
        'onTap': () => _navigateTo(const PermissionSettingsScreen()),
        'artMetaphor': '🔔 Zil',
      },
      {
        'title': 'Sözleşmeler',
        'subtitle': 'Gizlilik ve güvenlik',
        'icon': Icons.privacy_tip_outlined,
        'color': const Color(0xFF7986CB), // Pastel İndigo
        'onTap': () => _navigateTo(const ContractsPage()),
        'artMetaphor': '📄 Kontrat',
      },
      {
        'title': 'Yardım',
        'subtitle': 'SSS ve destek',
        'icon': Icons.help_outline,
        'color': const Color(0xFF4DB6AC), // Pastel Teal
        'onTap': () {},
        'artMetaphor': '❓ Soru',
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Buzlu Cam Etkisi
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(isDark ? 0.6 : 0.8),
            // Şeffaf Zemin
            borderRadius: BorderRadius.circular(24),
            // Çerçeve yerine çok hafif bir iç parlama efekti
            border: Border.all(
              color: colors.onSurface.withOpacity(0.05),
              width: 1,
            ),
            // Çok hafif, dağınık gölge
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
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
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 70),
                  // Çizgiyi ikondan sonra başlat
                  child: Divider(
                    height: 1,
                    color: colors.outline.withOpacity(0.1),
                  ),
                ),
                itemBuilder: (context, index) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Simge alanı (Clean & Painted Look)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Çok soft zemin
                  borderRadius: BorderRadius.circular(14),
                  // Border yerine renkli soft shadow
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

              // Başlık ve açıklama
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

              // Sanatsal benzetme (Etiket gibi)
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

  // TEMA SEÇİCİ - DAHA TEMİZ VE MODERN
  Widget _buildThemeSelectorArtistic(
      final WidgetRef ref, final ThemeData theme) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(isDark ? 0.6 : 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
            ),
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
                  // Seçili olanı yazan küçük etiket
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

              // Yan yana 3 buton - Temiz ve Modern
              Row(
                children: [
                  Expanded(
                      child: _buildThemeButton(
                          'Gün', ThemeMode.light, Icons.wb_sunny_rounded, ref)),
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
        height: 50, // Daha kompakt yükseklik
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
          // Column yerine Row, daha şık ve yatay
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

  // GÜVENLİK BÖLÜMÜ - MİNİMAL VE MODERN
  Widget _buildSecuritySection(
      final LoginState loginState, final ThemeData theme) {
    final colors = theme.colorScheme;

    return Column(
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
          // ÇIKIŞ BUTONU - Clean & Minimal
          _buildSecurityButton(
            label: 'Sergiden Çıkış Yap',
            subLabel: 'Güvenli çıkış',
            icon: Icons.logout_rounded,
            color: Colors.orange,
            onTap: () => _signOut(),
            theme: theme,
          ),
          const SizedBox(height: 12),

          // SİLME BUTONU - Clean & Minimal
          _buildSecurityButton(
            label: 'Koleksiyonu Sil',
            subLabel: 'Hesabı kalıcı kapat',
            icon: Icons.delete_outline_rounded,
            color: Colors.red,
            onTap: () => _showDeleteAccountDialog(loginState.user!.uid),
            theme: theme,
            isDestructive: true,
          ),
        ] else ...[
          // GİRİŞ YAP
          _buildSecurityButton(
            label: 'Sergiye Giriş Yap',
            subLabel: 'Hesabına eriş',
            icon: Icons.login_rounded,
            color: colors.primary,
            onTap: () => _navigateToLogin(),
            theme: theme,
            isPrimary: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityButton({
    required String label,
    required String subLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : color,
                      ),
                    ),
                    Text(
                      subLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPrimary
                            ? Colors.white.withOpacity(0.8)
                            : color.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isPrimary
                    ? Colors.white.withOpacity(0.5)
                    : color.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    showDialog(
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
