import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/data/repository/user_service.dart';
import 'package:ticketapp/presentation/pages/contracts/contracts.dart';
import '../../../core/custom_views/custom_elevated_button.dart';
import '../profile_edit/user_profile_edit.dart';
import '../my_favorites/favorite_screen.dart';
import '../my_ticket/my_ticket_screen.dart';
import '../settings/app_settings.dart';
import '../settings/permission_settings.dart';

class ProfilePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? firebaseUser;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      setState(() {
        firebaseUser = UserService().currentUser;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kullanıcı veri alınırken bir hata oluştu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(padding: const EdgeInsets.all(20.0), children: [
      _buildProfileCard(),
      const SizedBox(height: 20),
      if (firebaseUser != null) ...[
        CustomElevatedButton(
          text: 'Profilini Düzenle',
          icon: Icons.edit,
          onPressed: () => _navigateTo(const UserProfileEditScreen()),
        ),
        CustomElevatedButton(
          text: 'Biletlerim',
          icon: Icons.theaters_rounded,
          onPressed: () => _navigateTo(MyTicketPage()),
        ),
        CustomElevatedButton(
          text: 'Favori Etkinliklerim',
          icon: Icons.favorite,
          onPressed: () => _navigateTo(FavoritesPage()),
        ),
      ],
      const SizedBox(height: 20),
      CustomElevatedButton(
        text: 'Bildirim Ayarları',
        icon: Icons.notifications,
        onPressed: () => _navigateTo(const PermissionSettingsScreen()),
      ),
      CustomElevatedButton(
        text: 'Uygulama Ayarları',
        icon: Icons.settings,
        onPressed: () => _navigateTo(const AppSettingsPage()),
      ),
      const SizedBox(height: 20),
      CustomElevatedButton(
        text: 'Gizlilik ve Güvenlik',
        icon: Icons.privacy_tip,
        onPressed: () => _navigateTo(const ContractsPage()),
      ),
      CustomElevatedButton(
        text: 'Sıkça Sorulan Sorular',
        icon: Icons.help,
        onPressed: () {},
      ),
      const SizedBox(height: 20),
      CustomElevatedButton(
        text: 'Destek ve Bağış',
        icon: Icons.coffee,
        onPressed: () {},
      ),
      const SizedBox(height: 20),
      _buildThemeSelectorCard(),
      if (firebaseUser != null)
        CustomElevatedButton(
          text: 'Çıkış Yap',
          icon: Icons.logout,
          onPressed: _signOut,
        ),
      const SizedBox(height: 50)
    ]));
  }

  Widget _buildProfileCard() {
    if (firebaseUser == null) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(children: [
              Icon(Icons.account_circle, size: 100, color: Colors.grey),
              SizedBox(height: 10),
              Text('Giriş Yap',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('Lütfen giriş yapın',
                  style: TextStyle(fontSize: 16, color: Colors.grey))
            ])),
      );
    } else {
      return Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(firebaseUser!.photoURL ??
                    'https://via.placeholder.com/150'),
              ),
              const SizedBox(height: 10),
              Text(
                firebaseUser!.displayName ?? 'İsimsiz Kullanıcı',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(firebaseUser!.email ?? 'Mail bilgisi bulunamadı',
                  style: const TextStyle(fontSize: 16, color: Colors.grey))
            ]),
          ));
    }
  }

  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Tema Seçimi'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _themeOption('Açık Tema', ThemeMode.light),
              _themeOption('Koyu Tema', ThemeMode.dark),
              _themeOption('Sistem Varsayılanı', ThemeMode.system)
            ]),
          );
        });
  }

  Widget _themeOption(String title, ThemeMode mode) {
    return ListTile(
        title: Text(title),
        onTap: () {
          widget.onThemeChanged(mode);
          Navigator.of(context).pop();
        });
  }

  Widget _buildThemeSelectorCard() {
    return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showThemeSelectionDialog(context),
          child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.color_lens, color: Colors.blue),
                SizedBox(width: 16),
                Expanded(
                    child: Text(
                  'Tema Seçimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                )),
                Icon(Icons.arrow_forward_ios, size: 20)
              ])),
        ));
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  void _signOut() async {
    try {
      await UserService.signOut();
      setState(() {
        firebaseUser = null;
      });
    }catch(e){
      throw Exception('Çıkış yaparken bir hata oluştu: $e');
    }
  }
}
