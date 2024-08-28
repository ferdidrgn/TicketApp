import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  _PermissionSettingsScreenState createState() => _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPermissionCard(
              title: 'Konum İzni',
              description: 'Uygulamanızın konum özelliklerini kullanabilmesi için konum izni vermeniz gerekmektedir.',
              permission: Permission.location,
              onTap: () async {
                if (await Permission.location.isDenied) {
                  await Permission.location.request();
                }
                openAppSettings();
              },
            ),
            const SizedBox(height: 20),
            _buildPermissionCard(
              title: 'Bildirim İzni',
              description: 'Uygulamanız bildirimleri gösterebilmesi için bildirim izni vermeniz gerekmektedir.',
              permission: Permission.notification,
              onTap: () async {
                if (await Permission.notification.isDenied) {
                  await Permission.notification.request();
                }
                openAppSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required Permission permission,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Icon(Icons.settings, color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor),
        onTap: onTap,
      ),
    );
  }
}
