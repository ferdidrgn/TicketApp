import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;

  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 20),
          _buildElevatedButton(context, 'Profil Düzenleme', Icons.edit, () {}),
          _buildElevatedButton(context, 'Biletlerim', Icons.theaters_rounded, () {}),
          _buildElevatedButton(context, 'Bilgi Ayarları', Icons.info, () {}),
          _buildElevatedButton(context, 'Favorilerim', Icons.favorite, () {}),
          _buildElevatedButton(context, 'Bağış Yap', Icons.coffee, () {}),
          _buildElevatedButton(context, 'Gizlilik Sözleşmeleri', Icons.privacy_tip, () {}),
          _buildElevatedButton(context, 'Sıkça Sorulan Sorular', Icons.question_answer, () {}),
          const SizedBox(height: 20),
          _buildThemeSelectorButton(context),
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
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Profil fotoğrafı URL'si
            ),
            SizedBox(height: 10),
            Text(
              'Kullanıcı Adı',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text('user@example.com', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(text, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }

  Widget _buildThemeSelectorButton(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.palette, color: Colors.blue),
        title: const Text('Tema Seçimi', style: TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showThemeSelectionDialog(context);
        },
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tema Seçimi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sistem Teması'),
                onTap: () {
                  Navigator.of(context).pop();
                  onThemeChanged(ThemeMode.system);
                },
              ),
              ListTile(
                title: const Text('Açık Tema'),
                onTap: () {
                  Navigator.of(context).pop();
                  onThemeChanged(ThemeMode.light);
                },
              ),
              ListTile(
                title: const Text('Koyu Tema'),
                onTap: () {
                  Navigator.of(context).pop();
                  onThemeChanged(ThemeMode.dark);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}