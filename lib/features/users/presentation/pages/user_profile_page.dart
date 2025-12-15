import 'dart:math';

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
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLocalUserData();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
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

    if (loginState.isLoading || _isLoadingLocalData) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.primary.withOpacity(0.05),
                colors.surface,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan su boyası efekti
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _waveAnimation.value * 20),
                  child: CustomPaint(
                    painter: WatercolorPainter(
                      colors: [
                        colors.primary.withOpacity(0.08),
                        colors.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Sanatsal Profil Kartı (Aynı kaldı)
                _buildArtisticProfileCard(loginState.user, theme, loginState),
                const SizedBox(height: 32),

                // İŞLEVSEL BÖLÜM - SANATSAL BENZETMELERLE
                _buildFunctionalSection(loginState, theme),
                const SizedBox(height: 32),

                // TEMA AYARI - Sergi Işıklandırması (Aynı kaldı)
                _buildThemeSelectorArtistic(ref, theme),
                const SizedBox(height: 32),

                // GÜVENLİK BÖLÜMÜ - Daha Belirgin ve Ağırlıklı
                _buildSecuritySection(loginState, theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

                // Portre çerçevesi
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
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(photoURL),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İŞLEVSEL BÖLÜM - SANATSAL BENZETMELER
  Widget _buildFunctionalSection(
      final LoginState loginState, final ThemeData theme) {
    final colors = theme.colorScheme;

    // Ana işlevsel butonlar
    List<Map<String, dynamic>> functionalButtons = [
      if (loginState.user != null)
        {
          'title': 'Profil Portresi',
          'subtitle': 'Portreni düzenle',
          'icon': Icons.edit_outlined,
          'color': Colors.blue,
          'onTap': () =>
              _navigateTo(UserProfileEditScreen(userId: loginState.user!.uid)),
          'artMetaphor': '🎨 Fırça',
        },
      if (loginState.user != null)
        {
          'title': 'Bilet Arşivi',
          'subtitle': 'Geçmiş biletlerin',
          'icon': Icons.confirmation_number_outlined,
          'color': Colors.green,
          'onTap': () =>
              _navigateTo(MyTicketPage(userId: loginState.user!.uid)),
          'artMetaphor': '📜 Parşömen',
        },
      if (loginState.user != null)
        {
          'title': 'Favori Koleksiyon',
          'subtitle': 'Beğendiğin eserler',
          'icon': Icons.favorite_border,
          'color': Colors.pink,
          'onTap': () => _navigateTo(FavoritesPage()),
          'artMetaphor': '❤️ Kalp',
        },
      {
        'title': 'Ayarlar',
        'subtitle': 'Uygulama ayarları',
        'icon': Icons.settings_outlined,
        'color': Colors.orange,
        'onTap': () => _navigateTo(const AppSettingsPage()),
        'artMetaphor': '⚙️ Dişli',
      },
      {
        'title': 'İzinler',
        'subtitle': 'Bildirim ayarları',
        'icon': Icons.notifications_outlined,
        'color': Colors.purple,
        'onTap': () => _navigateTo(const PermissionSettingsScreen()),
        'artMetaphor': '🔔 Zil',
      },
      {
        'title': 'Sözleşmeler',
        'subtitle': 'Gizlilik ve güvenlik',
        'icon': Icons.privacy_tip_outlined,
        'color': Colors.indigo,
        'onTap': () => _navigateTo(const ContractsPage()),
        'artMetaphor': '📄 Kontrat',
      },
      {
        'title': 'Yardım',
        'subtitle': 'SSS ve destek',
        'icon': Icons.help_outline,
        'color': Colors.teal,
        'onTap': () {},
        'artMetaphor': '❓ Soru İşareti',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Sanat Atölyesi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: functionalButtons.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colors.outline.withOpacity(0.2),
              indent: 20,
              endIndent: 20,
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
        ],
      ),
    );
  }

  Widget _buildFunctionalButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String artMetaphor,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              // Simge alanı
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Sanatsal benzetme
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Ok işareti
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelectorArtistic(
      final WidgetRef ref, final ThemeData theme) {
    final currentTheme = ref.watch(themeProvider);
    String currentThemeText = '';

    switch (currentTheme) {
      case ThemeMode.light:
        currentThemeText = 'Gün Işığı';
        break;
      case ThemeMode.dark:
        currentThemeText = 'Gece Işığı';
        break;
      case ThemeMode.system:
        currentThemeText = 'Oto';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.8),
                        theme.colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sergi Işıklandırması',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Şu an: $currentThemeText',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeButton(
                    'Gün', ThemeMode.light, Icons.wb_sunny_outlined, ref),
                _buildThemeButton(
                    'Gece', ThemeMode.dark, Icons.nights_stay_outlined, ref),
                _buildThemeButton(
                    'Oto', ThemeMode.system, Icons.settings_outlined, ref),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(
      String label, ThemeMode mode, IconData icon, WidgetRef ref) {
    final isActive = ref.watch(themeProvider) == mode;
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(
      final LoginState loginState, final ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güvenlik ve Erişim',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (loginState.user != null) ...[
          // ÇIKIŞ YAP - Daha Belirgin
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.orange.withOpacity(0.05),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _signOut(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sergiden Çık',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            Text(
                              'Hesabından çıkış yap',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700]!.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.orange[700]!.withOpacity(0.5),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // HESABI SİL - ÇOK DAHA BELİRGİN
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.red.withOpacity(0.05),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDeleteAccountDialog(loginState.user!.uid),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_forever,
                          color: Colors.red[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Koleksiyonu Temizle',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            Text(
                              'Hesabını ve tüm verilerini kalıcı sil',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red[700]!.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'TEHLİKE',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // GİRİŞ YAP butonu
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.secondary.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToLogin(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.login,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sergiye Katıl',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Hesabına giriş yap',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Yardımcı widget'lar ve metotlar...
  Widget _buildArtTag(String text, IconData icon, Color color) {
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

  String _getLoginMethod(final User? firebaseUser) {
    if (firebaseUser == null) return 'anonymous';
    if (firebaseUser.providerData.any((p) => p.providerId == 'google.com'))
      return 'google';
    if (firebaseUser.providerData.any((p) => p.providerId == 'phone'))
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
      builder: (context) => AlertDialog(
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

// Su boyası efekti için custom painter
class WatercolorPainter extends CustomPainter {
  final List<Color> colors;

  WatercolorPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.softLight;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      final path = Path();
      final offset = size.height * 0.1 * i;

      path.moveTo(0, size.height * (0.2 + i * 0.15));
      for (double x = 0; x < size.width; x += 20) {
        final y = size.height * (0.2 + i * 0.15) + sin(x * 0.02 + offset) * 30;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WatercolorPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
