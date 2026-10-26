import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/fcm_manager_service.dart';
import 'preference_widgets.dart';

/// Ayarlar > İzinler grubuna eklenen iki satır (yalnız mobil):
/// "Duyuruları al" anahtarı (topic `all_users`) ve sistem bildirim
/// ayarlarına kısayol (Android'de "Sahne alarmı" kanalının sesi ve
/// Rahatsız Etme davranışı buradan kullanıcı tarafından seçilir).
List<Widget> announcementPreferenceRows(final BuildContext context) {
  if (kIsWeb) return const [];
  return [
    const _AnnouncementSwitchRow(),
    PreferenceRow(
      icon: Icons.volume_up_outlined,
      title: prefText(context, 'Alarm sesi ve sistem ayarları',
          'Alarm sound & system settings'),
      subtitle: prefText(
          context,
          'Sahne alarmının sesini ve “Rahatsız Etme” davranışını telefon ayarlarından seç.',
          'Choose the stage alarm sound and Do Not Disturb behaviour in system settings.'),
      onTap: openAppSettings,
    ),
  ];
}

class _AnnouncementSwitchRow extends ConsumerWidget {
  const _AnnouncementSwitchRow();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool enabled = ref.watch(announcementsEnabledProvider).value ?? true;
    final String title = prefText(context, 'Duyuruları al', 'Receive announcements');
    return PreferenceRow(
      icon: Icons.campaign_outlined,
      title: title,
      subtitle: prefText(
          context,
          'Yeni oyunlar, kampanyalar ve sahneden gelen duyurular.',
          'New shows, campaigns and announcements from the stage.'),
      onTap: () =>
          ref.read(announcementsEnabledProvider.notifier).set(!enabled),
      trailing: Switch(
        value: enabled,
        onChanged: (final bool v) =>
            ref.read(announcementsEnabledProvider.notifier).set(v),
      ),
    );
  }
}
