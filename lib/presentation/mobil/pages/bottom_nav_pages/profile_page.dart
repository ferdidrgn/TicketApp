import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../data/providers/login/login_provider.dart';
import '../../../../data/providers/login/login_state.dart';
import '../contracts/contracts.dart';
import '../my_favorites/favorite_screen.dart';
import '../my_ticket/my_ticket_page.dart';
import '../profile_edit/user_profile_edit.dart';
import '../settings/app_settings.dart';
import '../settings/permission_settings.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final theme = Theme.of(context);

    if (loginState.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(loginState.user, theme, loginState, context),
          const SizedBox(height: 20),
          if (loginState.user != null) ...[
            _btn(
                'Profilini Düzenle',
                Icons.edit,
                () => _navigateTo(
                    UserProfileEditScreen(userId: loginState.user!.uid),
                    context)),
            _btn(
                'Biletlerim',
                Icons.theaters_rounded,
                () => _navigateTo(
                    MyTicketPage(userId: loginState.user!.uid), context)),
            _btn('Favori Etkinliklerim', Icons.favorite,
                () => _navigateTo(FavoritesPage(), context)),
            const SizedBox(height: 20),
          ],
          _btn('Bildirim Ayarları', Icons.notifications,
              () => _navigateTo(const PermissionSettingsScreen(), context)),
          _btn('Uygulama Ayarları', Icons.settings,
              () => _navigateTo(const AppSettingsPage(), context)),
          const SizedBox(height: 20),
          _btn('Gizlilik ve Güvenlik', Icons.privacy_tip,
              () => _navigateTo(const ContractsPage(), context)),
          _btn('Sıkça Sorulan Sorular', Icons.help, () {}),
          const SizedBox(height: 20),
          _btn('Destek ve Bağış', Icons.coffee, () {}),
          const SizedBox(height: 20),
          _themeSelectorCard(context, ref, theme),

          // HESAP SİLME BUTONU - Sadece giriş yapmış ve misafir olmayan kullanıcılar görebilir
          if (loginState.user != null && !loginState.isGuest)
            _deleteAccountButton(context, ref),

          _btn(
            loginState.user != null ? 'Çıkış Yap' : 'Giriş Yap',
            loginState.user != null ? Icons.logout : Icons.login,
            loginState.user != null
                ? () => _signOut(context, ref)
                : () => _navigateToLogin(context),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _profileCard(final User? firebaseUser, final ThemeData theme,
      final LoginState loginState, final BuildContext context) {
    final textTheme = theme.textTheme;
    final radius = BorderRadius.circular(15);

    if (firebaseUser == null) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.account_circle,
                  size: 100,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                child: Text('Giriş Yap',
                    style: textTheme.headlineSmall?.copyWith(
                        color: Colors.pink, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 5),
              Text('Lütfen giriş yapın',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      );
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
              backgroundImage: NetworkImage(
                  firebaseUser.photoURL ?? 'https://via.placeholder.com/150'),
            ),
            const SizedBox(height: 10),
            Text(firebaseUser.displayName ?? 'İsimsiz Kullanıcı',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(firebaseUser.email ?? 'Mail bilgisi bulunamadı',
                style: textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (loginState.isGuest) ...[
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _themeSelectorCard(
      final BuildContext context, final WidgetRef ref, final ThemeData theme) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showThemeDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.color_lens, color: Colors.blue),
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

  Widget _deleteAccountButton(final BuildContext context, final WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: CustomElevatedButton(
        text: 'Hesabı Sil',
        iconData: Icons.delete_forever,
        backgroundColor: Colors.red,
        onPressed: () => _showDeleteAccountDialog(context, ref),
      ),
    );
  }

  void _showThemeDialog(final BuildContext context, final WidgetRef ref) {
    showDialog(
      context: context,
      builder: (final _) {
        return AlertDialog(
          title: Text('Tema Seçimi',
              style: Theme.of(context).textTheme.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeOption(context, ref, 'Açık Tema', ThemeMode.light),
              _themeOption(context, ref, 'Koyu Tema', ThemeMode.dark),
              _themeOption(
                  context, ref, 'Sistem Varsayılanı', ThemeMode.system),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(
      final BuildContext context, final WidgetRef ref) {
    showDialog(
      context: context,
      builder: (final context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
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
              SizedBox(height: 8),
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
              child: Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Dialog'u kapat
                await _deleteAccount(context, ref);
              },
              child: Text(
                'HESABI SİL',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _themeOption(final BuildContext context, final WidgetRef ref,
      final String title, final ThemeMode mode) {
    return ListTile(
      title: Text(title),
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
    );
  }

  void _navigateTo(final Widget page, final BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (final _) => page));

  void _navigateToLogin(final BuildContext context) =>
      Navigator.of(context).pushReplacementNamed('/login');

  Future<void> _signOut(final BuildContext context, final WidgetRef ref) async {
    try {
      await ref.read(loginProvider.notifier).signOut();
      _navigateToLogin(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
      );
    }
  }

  Future<void> _deleteAccount(
      final BuildContext context, final WidgetRef ref) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Hesap siliniyor...'),
            ],
          ),
        ),
      );

      await ref.read(loginProvider.notifier).deleteAccount();

      // Loading'i kapat (context mounted kontrolü)
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
      }
    } catch (e) {
      // Hata durumunda loading'i kapat ve hatayı göster
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog'unu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
