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

    if (loginState.isLoading || _isLoadingLocalData)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(loginState.user, theme, loginState),
          const SizedBox(height: 20),
          if (loginState.user != null)
            ..._buildUserSpecificButtons(loginState.user!.uid),
          ..._buildGeneralButtons(),
          _themeSelectorCard(ref, theme),
          _buildAuthButton(loginState),
          if (loginState.user != null) ..._buildDangerZone(loginState),
          _buildLocalStorageInfo(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  List<Widget> _buildUserSpecificButtons(final String userId) {
    return [
      _btn(
        'Profilini Düzenle',
        Icons.edit,
        () => _navigateTo(UserProfileEditScreen(userId: userId)),
      ),
      _btn(
        'Biletlerim',
        Icons.theaters_rounded,
        () => _navigateTo(MyTicketPage(userId: userId)),
      ),
      _btn(
        'Favori Etkinliklerim',
        Icons.favorite,
        () => _navigateTo(FavoritesPage()),
      ),
      const SizedBox(height: 20),
    ];
  }

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

  Widget _buildAuthButton(final LoginState loginState) {
    return _btn(
      loginState.user != null ? 'Çıkış Yap' : 'Giriş Yap',
      loginState.user != null ? Icons.logout : Icons.login,
      loginState.user != null ? () => _signOut() : () => _navigateToLogin(),
    );
  }

  List<Widget> _buildDangerZone(final LoginState loginState) {
    return [
      const SizedBox(height: 30),
      if (loginState.user?.uid != null)
        _deleteAccountButton(loginState.user!.uid),
    ];
  }

  // 🎨 TEMİZ VE ORTALANMIŞ TASARIM
  Widget _profileCard(
    final User? firebaseUser,
    final ThemeData theme,
    final LoginState loginState,
  ) {
    final textTheme = theme.textTheme;
    final userData = _getUserData(firebaseUser);

    // 🐛 DEBUG: Misafir durumunu kontrol et
    print('🔍 DEBUG Profile Card:');
    print('  - loginState.isGuest: ${loginState.isGuest}');
    print('  - firebaseUser: ${firebaseUser?.uid}');
    print('  - localUserData isGuest: ${_localUserData?['isGuest']}');
    print('  - userData.isGuest: ${userData.isGuest}');

    if (firebaseUser == null && _localUserData == null)
      return _buildLoginPromptCard(theme, textTheme);

    final bool isGuest = loginState.isGuest;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isGuest
                ? [Colors.orange.shade100, Colors.white]
                : [theme.primaryColor.withOpacity(0.1), Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isGuest ? Colors.orange : theme.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 47,
                  backgroundImage: NetworkImage(userData.photoURL),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İsim
            Text(
              userData.displayName,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              userData.email,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Login Method Badge (sadece misafir değilse)
                if (!isGuest)
                  _buildLoginMethodChip(userData.loginMethod, theme),

                // Guest Badge (sadece misafir ise)
                if (isGuest) _buildGuestChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Login Method Chip
  Widget _buildLoginMethodChip(
      final String loginMethod, final ThemeData theme) {
    final color = _getLoginMethodColor(loginMethod);
    final icon = _getLoginMethodIcon(loginMethod);
    final text = _getLoginMethodText(loginMethod);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Guest Chip
  Widget _buildGuestChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 6),
          Text(
            'Misafir Modu',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildLoginPromptCard(
      final ThemeData theme, final TextTheme textTheme) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.account_circle,
              size: 100,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Hoş Geldiniz',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Devam etmek için giriş yapın',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToLogin,
              icon: const Icon(Icons.login),
              label: const Text('Giriş Yap'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
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
        return 'Google';
      case 'phone':
        return 'Telefon';
      case 'anonymous':
        return 'Misafir';
      default:
        return 'Bilinmeyen';
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
              Navigator.pop(context);
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
      Navigator.of(context).pushReplacementNamed('/home');

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

  // ✅ FIX: executeWithInternetCheck kullanmıyoruz, direkt siliyoruz
  Future<void> _deleteAccount(final String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => const CustomLoadingDialog(
        message: 'Hesap siliniyor...',
      ),
    );

    try {
      print('🗑️ Hesap silme başlatıldı: $userId');

      // 1. Firestore'dan kullanıcı verilerini sil (direkt çağır)
      final userNotifier = ref.read(userProvider.notifier);
      final bool isDeleteUserDocument = await userNotifier.deleteUser(userId);

      print('📦 Firestore silme sonucu: $isDeleteUserDocument');

      if (!isDeleteUserDocument) {
        _closeDialogAndShowError('Kullanıcı verileri silinemedi');
        return;
      }

      // 2. Firebase Auth'tan hesabı sil (direkt çağır)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('🔥 Firebase Auth silme başlatıldı');
        await currentUser.delete();
        print('✅ Firebase Auth silindi');

        // 3. Local storage temizle
        await LocalStorageService.clearAllUserData();
        print('💾 Local storage temizlendi');

        // 4. Provider state'i sıfırla
        ref.read(loginProvider.notifier).clearLoginState();
        print('🔄 Provider state sıfırlandı');
        ref.read(userProvider.notifier).clearUserState();
      }

      // 5. Başarılı
      print('🎉 Hesap silme tamamlandı');
      _closeDialogAndShowSuccess();
    } catch (e) {
      print('❌ Delete Account Error: $e');
      _closeDialogAndShowError('Hesap silinirken hata: $e');
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => CustomSuccessDialog(
        message: 'Hesabınız başarıyla silindi',
        onConfirm: () => _navigateToLogin(),
      ),
    );
  }

  void _showErrorDialog(final String message) {
    showDialog(
      context: context,
      builder: (final context) => CustomErrorDialog(
        message: message,
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }
}

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
