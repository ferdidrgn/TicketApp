import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/push/notif_prefs.dart';
import '../../../../core/services/push/notif_prefs_provider.dart';
import 'preference_widgets.dart';

/// Ayarlar > Bildirimler: kategori anahtarları + sessiz saatler.
/// Sözleşme: docs/BILDIRIM-TERCIHLERI.md. Oturum yoksa hiçbir şey çizilmez.
/// ("Sessizdeyken de sesli hatırlat" anahtarı ayrı satırdır ve korunur.)
class NotificationPrefsRows extends ConsumerWidget {
  const NotificationPrefsRows({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final NotifPrefs? p = ref.watch(notifPrefsProvider).value;
    if (p == null) return const SizedBox.shrink();
    final NotifPrefsNotifier n = ref.read(notifPrefsProvider.notifier);

    Future<void> change(
        final NotifPrefs Function(NotifPrefs) fn) async {
      final bool ok = await n.change(fn);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(prefText(context, 'Tercih kaydedilemedi, tekrar dene.',
                'Could not save, please try again.'))));
      }
    }

    Widget row(final IconData icon, final String tr, final String en,
        final String subTr, final String subEn, final bool value,
        final NotifPrefs Function(NotifPrefs, bool) apply) {
      return Semantics(
        label: prefText(context, tr, en),
        child: PreferenceRow(
          icon: icon,
          title: prefText(context, tr, en),
          subtitle: prefText(context, subTr, subEn),
          onTap: () => change((final NotifPrefs o) => apply(o, !value)),
          trailing: Switch(
            value: value,
            onChanged: (final bool v) =>
                change((final NotifPrefs o) => apply(o, v)),
          ),
        ),
      );
    }

    final List<Widget> items = [
        row(Icons.alarm_outlined, 'Seans hatırlatmaları', 'Show reminders',
            'Seansa yaklaşık 24 saat ve 2 saat kala.',
            'About 24 hours and 2 hours before the show.',
            p.reminders, (o, v) => o.copyWith(reminders: v)),
        row(Icons.event_busy_outlined, 'İptal ve değişiklikler',
            'Cancellations and changes',
            'Seans iptal, erteleme ve saat değişikliği. Açık kalması önerilir.',
            'Cancelled, postponed or rescheduled shows. We recommend keeping this on.',
            p.changes, (o, v) => o.copyWith(changes: v)),
        row(Icons.rate_review_outlined, 'Teşekkür ve yorum daveti',
            'Thank-you and review invite',
            'İzlediğin seanstan sonra “Nasıldı?” bildirimi.',
            'A “How was it?” note after a show you attended.',
            p.thankYou, (o, v) => o.copyWith(thankYou: v)),
        row(Icons.theater_comedy_outlined, 'Yeni oyunlar ve seanslar',
            'New shows and sessions',
            'Yeni oyun ya da seans eklendiğinde (varsayılan kapalı).',
            'When a new show or session is added (off by default).',
            p.newShows, (o, v) => o.copyWith(newShows: v)),
        row(Icons.local_offer_outlined, 'Kampanya ve duyurular',
            'Campaigns and offers',
            'İndirim ve kampanya haberleri (varsayılan kapalı).',
            'Discounts and campaign news (off by default).',
            p.marketing, (o, v) => o.copyWith(marketing: v)),
        row(Icons.bedtime_outlined, 'Sessiz saatler', 'Quiet hours',
            'Bu saatlerde teşekkür, yeni oyun ve kampanya bildirimi gelmez. İptal/değişiklik ve seansa 2 saat kala hatırlatma yine gelir.',
            'No thank-you, new-show or campaign pushes in this window. Cancellations and the 2-hour reminder still arrive.',
            p.hasQuiet, (o, v) => v
                ? o.copyWith(quietStart: '23:00', quietEnd: '08:00')
                : o.copyWith(clearQuiet: true)),
        if (p.hasQuiet) ...[
          _TimeRow(
            label: prefText(context, 'Başlangıç', 'From'),
            value: p.quietStart!,
            onPick: (final String t) => change((final NotifPrefs o) =>
                t == o.quietEnd ? o : o.copyWith(quietStart: t)),
          ),
          _TimeRow(
            label: prefText(context, 'Bitiş', 'Until'),
            value: p.quietEnd!,
            onPick: (final String t) => change((final NotifPrefs o) =>
                t == o.quietStart ? o : o.copyWith(quietEnd: t)),
          ),
        ],
    ];
    final Color line = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: line),
          items[i],
        ],
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onPick;
  const _TimeRow(
      {required this.label, required this.value, required this.onPick});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $value',
      child: PreferenceRow(
        icon: Icons.schedule_outlined,
        title: label,
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
        onTap: () async {
          final List<String> hm = value.split(':');
          final TimeOfDay? t = await showTimePicker(
            context: context,
            initialTime:
                TimeOfDay(hour: int.parse(hm[0]), minute: int.parse(hm[1])),
            builder: (final BuildContext c, final Widget? w) => MediaQuery(
              data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
              child: w!,
            ),
          );
          if (t != null) onPick(NotifPrefs.formatTime(t.hour, t.minute));
        },
      ),
    );
  }
}
