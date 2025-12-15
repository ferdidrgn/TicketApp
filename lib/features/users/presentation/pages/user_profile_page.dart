import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import '../../../../core/theme/theme_context_extension.dart';
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
import '../../../users/presentation/pages/user_profile_edit.dart';
import '../../../users/presentation/providers/user_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _localUserData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await LocalStorageService.init();
      final userData = LocalStorageService.getEssentialUserData();
      setState(() {
        _localUserData = userData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);

    if (_isLoading || loginState.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: context.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profil Başlığı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.appGradient(isActive: true),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Profilim',
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sanat yolculuğun',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Ana İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profil Kartı
                  _buildProfileCard(context, loginState),
                  const SizedBox(height: 30),

                  // İşlevsel Butonlar
                  _buildFunctionalSection(context, loginState),
                  const SizedBox(height: 30),

                  // Tema Seçimi
                  _buildThemeSelector(context, ref),
                  const SizedBox(height: 30),

                  // Güvenlik Bölümü
                  _buildSecuritySection(context, loginState),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      final BuildContext context, final LoginState loginState) {
    final firebaseUser = loginState.user;
    final isLoggedIn = firebaseUser != null || _localUserData != null;
    final isGuest = loginState.isGuest;

    // Kullanıcı bilgilerini al (öncelik sırası: Firebase → Local → Varsayılan)
    final displayName = firebaseUser?.displayName ??
        _localUserData?['displayName'] ??
        'Sanat Sever';

    final email = firebaseUser?.email ??
        _localUserData?['email'] ??
        (isLoggedIn ? 'Kullanıcı' : 'Misafir');

    final userRole = _localUserData?['role'] ?? 'Sanat Sever';

    final photoURL = firebaseUser?.photoURL ??
        _localUserData?['photoURL'] ??
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=500&auto=format&fit=crop';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.surfaceColor,
              context.surfaceColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Avatar ve Halo Efekti
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: context.appGradient(isActive: true),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: context.surfaceColor,
                backgroundImage: NetworkImage(photoURL),
                onBackgroundImageError: (final exception, final stackTrace) {
                  // Hata durumunda default avatar
                },
                child: photoURL.contains('placeholder') || photoURL.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 40,
                        color: context.primaryColor,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // İsim ve Rol
            Column(
              children: [
                Text(
                  displayName,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Rol Badge'i
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(userRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(userRole).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    userRole,
                    style: TextStyle(
                      color: _getRoleColor(userRole),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            Text(
              email,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),

            // Durum Etiketleri
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Login Metodu
                _buildStatusChip(
                  _getLoginMethodText(firebaseUser),
                  _getLoginMethodIcon(_getLoginMethod(firebaseUser)),
                  _getLoginMethodColor(_getLoginMethod(firebaseUser)),
                ),

                // Misafir Durumu
                if (isGuest)
                  _buildStatusChip(
                    'Misafir',
                    Icons.person_outline,
                    Colors.orange,
                  ),

                // Son Giriş Tarihi
                if (_localUserData?['lastLogin'] != null)
                  _buildStatusChip(
                    'Aktif',
                    Icons.circle,
                    Colors.green,
                  ),
              ],
            ),

            // İstatistikler (Opsiyonel)
            if (_localUserData != null &&
                (_localUserData?['ticketCount'] != null ||
                    _localUserData?['favoriteCount'] != null))
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Bilet',
                        Icons.confirmation_number,
                        '${_localUserData?['ticketCount'] ?? 0}',
                        context.primaryColor,
                      ),
                      _buildStatItem(
                        'Favori',
                        Icons.favorite,
                        '${_localUserData?['favoriteCount'] ?? 0}',
                        Colors.pink,
                      ),
                      _buildStatItem(
                        'Katılım',
                        Icons.event,
                        '${_localUserData?['eventCount'] ?? 0}',
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionalSection(
      final BuildContext context, final LoginState loginState) {
    final buttons = [
      if (loginState.user != null)
        _buildFunctionalButton(
          context,
          'Profilini Düzenle',
          'Kişisel bilgilerini güncelle',
          Icons.edit,
          context.primaryColor,
          () =>
              _navigateTo(UserProfileEditScreen(userId: loginState.user!.uid)),
        ),
      if (loginState.user != null)
        _buildFunctionalButton(
          context,
          'Biletlerim',
          'Satın aldığın biletler',
          Icons.confirmation_number,
          Colors.green,
          () => _navigateTo(MyTicketPage(userId: loginState.user!.uid)),
        ),
      if (loginState.user != null)
        _buildFunctionalButton(
          context,
          'Favorilerim',
          'Beğendiğin etkinlikler',
          Icons.favorite_border,
          Colors.pink,
          () => _navigateTo(FavoritesPage()),
        ),
      _buildFunctionalButton(
        context,
        'Ayarlar',
        'Uygulama ayarları',
        Icons.settings,
        Colors.orange,
        () => _navigateTo(const AppSettingsPage()),
      ),
      _buildFunctionalButton(
        context,
        'İzinler',
        'Bildirim ayarları',
        Icons.notifications,
        Colors.purple,
        () => _navigateTo(const PermissionSettingsScreen()),
      ),
      _buildFunctionalButton(
        context,
        'Sözleşmeler',
        'Gizlilik ve güvenlik',
        Icons.privacy_tip,
        Colors.blueGrey,
        () => _navigateTo(const ContractsPage()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'İşlevler',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ),
        ...buttons,
      ],
    );
  }

  Widget _buildFunctionalButton(
    final BuildContext context,
    final String title,
    final String subtitle,
    final IconData icon,
    final Color color,
    final VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.surfaceColor,
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.textColor.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(final BuildContext context, final WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Tema',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.surfaceColor,
            border: Border.all(
              color: context.colors.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: context.appGradient(isActive: true),
                      ),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sergi Işıklandırması',
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          'Görünümünü kişiselleştir',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'Açık',
                      ThemeMode.light,
                      Icons.wb_sunny_outlined,
                      currentTheme,
                      ref,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'Koyu',
                      ThemeMode.dark,
                      Icons.nightlight_round,
                      currentTheme,
                      ref,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'Oto',
                      ThemeMode.system,
                      Icons.settings_outlined,
                      currentTheme,
                      ref,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    final BuildContext context,
    final String label,
    final ThemeMode mode,
    final IconData icon,
    final ThemeMode currentTheme,
    final WidgetRef ref,
  ) {
    final isActive = currentTheme == mode;

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? context.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? context.primaryColor.withOpacity(0.3)
                : context.colors.outline.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? context.primaryColor
                  : context.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? context.primaryColor
                    : context.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(
      final BuildContext context, final LoginState loginState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Güvenlik',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ),
        if (loginState.user != null) ...[
          // Çıkış Yap Butonu
          _buildSecurityButton(
            context,
            'Çıkış Yap',
            'Hesabından çıkış yap',
            Icons.logout,
            Colors.orange,
            Colors.white,
            () => _signOut(),
          ),
          const SizedBox(height: 12),

          // Hesabı Sil Butonu (Daha Belirgin)
          _buildSecurityButton(
            context,
            'Hesabı Sil',
            'Hesabını ve tüm verilerini kalıcı sil',
            Icons.delete_forever,
            Colors.red,
            Colors.white,
            () => _showDeleteAccountDialog(loginState.user!.uid),
          ),
        ] else ...[
          // Giriş Yap Butonu
          _buildSecurityButton(
            context,
            'Giriş Yap',
            'Hesabına giriş yap',
            Icons.login,
            context.primaryColor,
            Colors.white,
            () => _navigateToLogin(),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityButton(
    final BuildContext context,
    final String title,
    final String subtitle,
    final IconData icon,
    final Color backgroundColor,
    final Color textColor,
    final VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor.withOpacity(0.1),
        border: Border.all(
          color: backgroundColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: backgroundColor == Colors.red
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: backgroundColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, color: backgroundColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: backgroundColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: backgroundColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (backgroundColor == Colors.red)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'TEHLİKE',
                      style: TextStyle(
                        color: Colors.red,
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
    );
  }

  // Yardımcı Metotlar
  Color _getRoleColor(final String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'yönetici':
        return Colors.red;
      case 'vip':
      case 'premium':
        return Colors.amber[700]!;
      case 'sanatçı':
      case 'artist':
        return Colors.purple;
      case 'moderatör':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildStatusChip(
      final String text, final IconData icon, final Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(final String label, final IconData icon,
      final String value, final Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getLoginMethodText(final User? firebaseUser) {
    if (firebaseUser == null) return 'Misafir';

    if (firebaseUser.providerData
        .any((final p) => p.providerId == 'google.com')) {
      return 'Google';
    }

    if (firebaseUser.providerData.any((final p) => p.providerId == 'phone')) {
      return 'Telefon';
    }

    if (firebaseUser.providerData
        .any((final p) => p.providerId == 'password')) {
      return 'Email';
    }

    return 'Anonim';
  }

  String _getLoginMethod(final User? firebaseUser) {
    if (firebaseUser == null) return 'anonymous';
    if (firebaseUser.providerData
        .any((final p) => p.providerId == 'google.com')) {
      return 'google';
    }
    if (firebaseUser.providerData.any((final p) => p.providerId == 'phone')) {
      return 'phone';
    }
    if (firebaseUser.providerData
        .any((final p) => p.providerId == 'password')) {
      return 'email';
    }
    return 'anonymous';
  }

  IconData _getLoginMethodIcon(final String method) {
    switch (method) {
      case 'google':
        return Icons.g_mobiledata_rounded;
      case 'phone':
        return Icons.phone_android;
      case 'email':
        return Icons.email;
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
      case 'email':
        return Colors.blueGrey;
      case 'anonymous':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _navigateTo(final Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (final _) => page));
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _signOut() async {
    try {
      await ref.read(loginProvider.notifier).signOut();
      await LocalStorageService.clearAllUserData();
      await _loadUserData();
      _navigateToLogin();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yaparken hata: $e'),
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
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[800]),
            const SizedBox(width: 12),
            Text(
              'Hesabı Sil',
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
              'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istiyor musunuz?',
              style: TextStyle(
                color: context.textColor.withOpacity(0.8),
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
                    '• Biletleriniz kaybolacak\n'
                    '• Favorileriniz silinecek\n'
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
                color: context.textColor.withOpacity(0.6),
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
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(final String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => const CustomLoadingDialog(
        message: 'Hesap siliniyor...',
      ),
    );

    try {
      final userNotifier = ref.read(userProvider.notifier);
      final isDeleteUserDocument = await userNotifier.deleteUser(userId);

      if (!isDeleteUserDocument) {
        _closeDialogAndShowError('Kullanıcı verileri silinemedi');
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
          message: 'Hesabınız başarıyla silindi',
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
