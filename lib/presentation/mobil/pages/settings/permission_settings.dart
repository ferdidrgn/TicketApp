import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/custom_art_inspirational_quote_view.dart';
import '../../../../core/widgets/custom_art_words_card.dart';

class PermissionSettingsScreen extends StatelessWidget {
  const PermissionSettingsScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InspirationalQuoteView(
              word: "Hayal gücü, bilmekten daha önemlidir.",
              author: "Albert Einstein",
              imageUrl:
                  'https://avatars.mds.yandex.net/get-entity_search/10349888/1168254232/SUx150_2x', // Farklı bir görsel
            ),
            const CustomArtWordsCard(
                word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
            const SizedBox(height: 30),
            _buildPermissionCard(
                title: 'Konum İzni',
                description:
                    'Uygulamanızın konum özelliklerini kullanabilmesi için konum izni vermeniz gerekmektedir.',
                permission: Permission.location,
                onTap: () => _handlePermission(Permission.location),
                context: context),
            const SizedBox(height: 20),
            _buildPermissionCard(
              title: 'Bildirim İzni',
              description:
                  'Uygulamanız bildirimleri gösterebilmesi için bildirim izni vermeniz gerekmektedir.',
              permission: Permission.notification,
              onTap: () => _handlePermission(Permission.notification),
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required final BuildContext context,
    required final String title,
    required final String description,
    required final Permission permission,
    required final VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Icon(Icons.settings,
            color:
                Theme.of(context).bottomNavigationBarTheme.selectedItemColor),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handlePermission(final Permission permission) async {
    if (await permission.isDenied) await permission.request();
    await openAppSettings();
  }
}
