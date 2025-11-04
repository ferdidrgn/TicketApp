import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../core/widgets/custom_pop_up.dart';
import '../../../../data/providers/login/login_provider.dart';
import '../../../../data/providers/login/login_state.dart';
import '../contracts/contracts.dart';
import '../my_favorites/favorite_screen.dart';
import '../my_ticket/my_ticket_page.dart';
import '../profile_edit/user_profile_edit.dart';
import '../settings/app_settings.dart';
import '../settings/permission_settings.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _localUserData;
  bool _isLoadingLocalData = true;

  @override
  void initState() {
    super.initState();
    _loadLocalUserData();
  }

  Future<void> _loadLocalUserData() async {
    try {
      await LocalStorageService.init();
      final userData = LocalStorageService.getUserData();
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
    final theme = Theme.of(context);

    if (loginState.isLoading || _isLoadingLocalData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(loginState.user, theme, loginState),
          const SizedBox(height: 20),
          if (loginState.user != null) ..._buildUserSpecificButtons(loginState),
          ..._buildGeneralButtons(),
          _themeSelectorCard(ref, theme),
          _buildAuthButton(loginState),
          if (loginState.user != null && loginState.isGuest)
            ..._buildDangerZone(loginState),
          _buildLocalStorageInfo(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ✅ REFACTORED: User-specific buttons
  List<Widget> _buildUserSpecificButtons(final LoginState loginState) {
    return [
      _btn(
        'Profilini Düzenle',
        Icons.edit,
        () => _navigateTo(UserProfileEditScreen(userId: loginState.user!.uid)),
      ),
      _btn(
        'Biletlerim',
        Icons.theaters_rounded,
        () => _navigateTo(MyTicketPage(userId: loginState.user!.uid)),
      ),
      _btn(
        'Favori Etkinliklerim',
        Icons.favorite,
        () => _navigateTo(FavoritesPage()),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ✅ REFACTORED: General buttons
  List<Widget> _buildGeneralButtons() {
    return [
      _btn(
        'Bildirim Ayarları',
        Icons.notifications,
        () => _navigateTo(const PermissionSettingsScreen()),
      ),
      _btn(
        'Uygulama Ayarları',
        Icons.settings,
        () => _navigateTo(const AppSettingsPage()),
      ),
      const SizedBox(height: 20),
      _btn(
        'Gizlilik ve Güvenlik',
        Icons.privacy_tip,
        () => _navigateTo(const ContractsPage()),
      ),
      _btn('Sıkça Sorulan Sorular', Icons.help, () {}),
      const SizedBox(height: 20),
      _btn('Destek ve Bağış', Icons.coffee, () {}),
      const SizedBox(height: 20),
    ];
  }

  // ✅ REFACTORED: Auth button
  Widget _buildAuthButton(final LoginState loginState) {
    return _btn(
      loginState.user != null ? 'Çıkış Yap' : 'Giriş Yap',
      loginState.user != null ? Icons.logout : Icons.login,
      loginState.user != null ? () => _signOut() : () => _navigateToLogin(),
    );
  }

  // ✅ REFACTORED: Danger zone buttons
  List<Widget> _buildDangerZone(final LoginState loginState) {
    return [
      const SizedBox(height: 30),
      _deleteAccountButton(loginState.user!.uid),
    ];
  }

  Widget _profileCard(
    final User? firebaseUser,
    final ThemeData theme,
    final LoginState loginState,
  ) {
    final textTheme = theme.textTheme;
    final radius = BorderRadius.circular(15);

    // User data with fallbacks
    final userData = _getUserData(firebaseUser);
    final bool isGuest = loginState.isGuest || userData.isGuest;

    if (firebaseUser == null && _localUserData == null) {
      return _buildLoginPromptCard(theme, textTheme, radius);
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(userData.photoURL),
            ),
            const SizedBox(height: 10),
            Text(
              userData.displayName,
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              userData.email,
              style: textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            _buildLoginMethodBadge(userData.loginMethod, textTheme),
            if (isGuest) _buildGuestBadge(textTheme),
          ],
        ),
      ),
    );
  }

  // ✅ REFACTORED: User data model
  _UserData _getUserData(final User? firebaseUser) {
    return _UserData(
      displayName: firebaseUser?.displayName ??
          _localUserData?['displayName'] ??
          'İsimsiz Kullanıcı',
      email: firebaseUser?.email ??
          _localUserData?['email'] ??
          'Mail bilgisi bulunamadı',
      photoURL: firebaseUser?.photoURL ??
          _localUserData?['photoURL'] ??
          'https://via.placeholder.com/150',
      loginMethod: _localUserData?['loginMethod'] ?? 'anonymous',
      isGuest: _localUserData?['isGuest'] ?? true,
    );
  }

  Widget _buildLoginPromptCard(final ThemeData theme, final TextTheme textTheme,
      final BorderRadius radius) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.account_circle,
              size: 100,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToLogin,
              child: Text(
                'Giriş Yap',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Lütfen giriş yapın',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginMethodBadge(
      final String loginMethod, final TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: _getLoginMethodColor(loginMethod).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getLoginMethodColor(loginMethod)),
      ),
      child: Text(
        _getLoginMethodText(loginMethod),
        style: textTheme.bodySmall?.copyWith(
          color: _getLoginMethodColor(loginMethod),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGuestBadge(final TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Text(
        'Misafir Modu',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

  String _getLoginMethodText(final String method) {
    switch (method) {
      case 'google':
        return 'Google ile Giriş';
      case 'phone':
        return 'Telefon ile Giriş';
      case 'anonymous':
        return 'Misafir Giriş';
      default:
        return 'Bilinmeyen Giriş';
    }
  }

  Widget _btn(
      final String text, final IconData icon, final VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: CustomElevatedButton(
        text: text,
        iconData: icon,
        onPressed: onPressed,
      ),
    );
  }

  Widget _themeSelectorCard(final WidgetRef ref, final ThemeData theme) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showThemeDialog(ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.color_lens, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                  child:
                      Text('Tema Seçimi', style: theme.textTheme.titleLarge)),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleteAccountButton(final String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: CustomElevatedButton(
        text: 'Hesabı Sil',
        iconData: Icons.delete_forever,
        backgroundColor: Colors.red,
        onPressed: () => _showDeleteAccountDialog(userId),
      ),
    );
  }

  Widget _buildLocalStorageInfo() {
    if (_localUserData == null) return const SizedBox();

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local Storage Bilgileri:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text('UID: ${_localUserData?['uid'] ?? 'Yok'}',
                style: const TextStyle(fontSize: 10)),
            Text('Email: ${_localUserData?['email'] ?? 'Yok'}',
                style: const TextStyle(fontSize: 10)),
            Text('Giriş Methodu: ${_localUserData?['loginMethod'] ?? 'Yok'}',
                style: const TextStyle(fontSize: 10)),
            Text('Misafir: ${_localUserData?['isGuest'] ?? 'Yok'}',
                style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(final WidgetRef ref) {
    showDialog(
      context: context,
      builder: (final _) => AlertDialog(
        title:
            Text('Tema Seçimi', style: Theme.of(context).textTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption('Açık Tema', ThemeMode.light),
            _themeOption('Koyu Tema', ThemeMode.dark),
            _themeOption('Sistem Varsayılanı', ThemeMode.system),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(final String userId) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hesabınızı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Tüm kişisel verileriniz silinecek\n'
              '• Satın aldığınız biletler kaybolacak\n'
              '• Favori etkinlikleriniz silinecek\n'
              '• Bu işlem geri alınamaz!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              _deleteAccount(userId);
            },
            child: const Text(
              'HESABI SİL',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(final String title, final ThemeMode mode) {
    return ListTile(
      title: Text(title),
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
    );
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
          SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
        );
      }
    }
  }

  // ✅ FIXED: Loading popup kapanma sorunu çözüldü
  Future<void> _deleteAccount(final String userId) async {
    // Loading dialog'u değişkene atayalım
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => const CustomLoadingDialog(
        message: 'Hesap siliniyor...',
      ),
    );

    try {
      // 1. Firestore'dan kullanıcı verilerini sil
      final bool isDeleteUserDocument =
          await ref.read(userProvider.notifier).deleteUser(userId);

      if (!isDeleteUserDocument) {
        _closeDialogAndShowError('Kullanıcı verileri silinemedi');
        return;
      }

      // 2. Firebase Auth'tan hesabı sil
      await ref.read(loginProvider.notifier).deleteAccount();

      // 3. Başarılı - loading kapat → success göster
      _closeDialogAndShowSuccess();
    } catch (e) {
      _closeDialogAndShowError('Hesap silinirken hata oluştu: $e');
    }
  }

  // ✅ REFACTORED: Dialog kapatma ve hata gösterme
  void _closeDialogAndShowError(final String message) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Loading dialog'u kapat
      _showErrorDialog(message);
    }
  }

  // ✅ REFACTORED: Başarılı işlem
  void _closeDialogAndShowSuccess() {
    if (context.mounted) {
      Navigator.of(context).pop(); // Loading dialog'u kapat
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => CustomSuccessDialog(
        message: 'Hesabınız başarıyla silindi',
        onConfirm: () {
          Navigator.pop(context); // Success dialog'u kapat
          _navigateToLogin(); // Login sayfasına git
        },
      ),
    );
  }

  void _showErrorDialog(final String message) {
    showDialog(
      context: context,
      builder: (final context) => CustomErrorDialog(
        message: message,
        onConfirm: () => Navigator.pop(context), // Error dialog'u kapat
      ),
    );
  }
}

// ✅ Helper class for user data
class _UserData {
  final String displayName;
  final String email;
  final String photoURL;
  final String loginMethod;
  final bool isGuest;

  _UserData({
    required this.displayName,
    required this.email,
    required this.photoURL,
    required this.loginMethod,
    required this.isGuest,
  });
}
