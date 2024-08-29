import 'package:flutter/material.dart';
import 'package:ticketapp/favorites/favorite_screen.dart';
import 'package:ticketapp/my_ticket/my_ticket_screen.dart';
import 'package:ticketapp/settings/app_settings.dart';
import 'package:ticketapp/settings/permission_settings.dart';
import '../custom_views/custom_elevated_button.dart';
import '../profile_edit/user_profile_edit.dart';

class ProfilePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 20),
          CustomElevatedButton(
            text: 'Profilini Düzenle',
            icon: Icons.edit,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserProfileEditScreen(),
                ),
              );
            },
          ),
          CustomElevatedButton(
            text: 'Biletlerim',
            icon: Icons.theaters_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MyTicketPage(),
                ),
              );
            },
          ),
          CustomElevatedButton(
            text: 'Favori Etkinliklerim',
            icon: Icons.favorite,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FavoritesPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          CustomElevatedButton(
            text: 'Bildirim Ayarları',
            icon: Icons.notifications,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PermissionSettingsScreen(),
                ),
              );
            },
          ),
          CustomElevatedButton(
            text: 'Uygulama Ayarları',
            icon: Icons.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppSettingsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          CustomElevatedButton(
            text: 'Gizlilik ve Güvenlik',
            icon: Icons.privacy_tip,
            onPressed: () {},
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
          _buildThemeSelectorCard(context),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150'), // Profil fotoğrafı URL'si
            ),
            SizedBox(height: 10),
            Text(
              'Kullanıcı Adı',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text('user@example.com',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tema Seçimi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: const Text('Açık Tema'),
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.light);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Koyu Tema'),
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.dark);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Sistem Varsayılanı'),
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.system);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectorCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        iconColor: Colors.blue,
        leading: const Icon(Icons.color_lens),
        title: const Text('Tema Seçimi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: () {
          _showThemeSelectionDialog(context);
        },
      ),
    );
  }
}
