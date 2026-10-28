import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/fcm_manager_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/providers/navigation_keys.dart';
import 'preference_widgets.dart';

/// "Sessizdeyken de sesli hatırlat" metinleri (platforma göre, abartısız).
///
/// KURAL (sahibin kararı): telefonun sessiz/zil modunu ASLA DEĞİŞTİRMEYİZ.
/// Yalnız kullanıcı AÇIKÇA izin verirse seans hatırlatması sessiz moddayken de
/// duyulur (Android: alarm ses akışı); sesten sonra telefon olduğu gibi kalır.
/// Telefon sessizde değilse hiçbir şeyi sessize almayız.
@visibleForTesting
class LoudAlarmCopy {
  final String title;
  final String what;
  final String wontDo;
  final String limits;
  const LoudAlarmCopy(
      {required this.title,
      required this.what,
      required this.wontDo,
      required this.limits});

  static LoudAlarmCopy of(final bool en, final TargetPlatform platform) {
    final bool ios = platform == TargetPlatform.iOS;
    if (ios) {
      return en
          ? const LoudAlarmCopy(
              title: 'Remind me loudly before the show',
              what:
                  'Show reminders arrive as “Time Sensitive”: they can break through Focus / Do Not Disturb and vibrate.',
              wontDo:
                  'We never change your phone settings or switch your ring/silent switch.',
              limits:
                  'On iPhone, an app cannot make sound while the silent switch is on (Apple allows that only for specially approved apps). You can turn off “Time Sensitive” per app in iOS Settings.')
          : const LoudAlarmCopy(
              title: 'Seans öncesi dikkat çekici hatırlat',
              what:
                  'Seans hatırlatmaları “Zamana duyarlı” gelir: Odak / Rahatsız Etme modunu aşabilir ve titreşim verir.',
              wontDo:
                  'Telefonunun ayarlarını ya da sessiz anahtarını DEĞİŞTİRMEYİZ.',
              limits:
                  'iPhone’da sessiz anahtarı açıkken uygulamalar ses çıkaramaz (Apple bunu yalnız özel onaylı uygulamalara verir). “Zamana duyarlı” bildirimi iOS Ayarları’ndan uygulama bazında kapatabilirsin.');
    }
    return en
        ? const LoudAlarmCopy(
            title: 'Remind me loudly, even on silent',
            what:
                'Right before your show, an important reminder plays once even if your phone is on silent (it uses the alarm sound channel).',
            wontDo:
                'We do NOT change your phone’s silent/ring setting. After the sound, your phone stays exactly as it was. If your phone is not on silent, we never silence it.',
            limits:
                'If you turned on Do Not Disturb yourself, the system rule applies and the app does not try to override it. Some phone brands (Xiaomi, Huawei…) limit background notifications; check the app’s notification settings. You can turn this off any time.')
        : const LoudAlarmCopy(
            title: 'Sessizdeyken de sesli hatırlat',
            what:
                'Seans başlamadan önce gelen önemli hatırlatma, telefonun sessizde olsa bile bir kez çalar (alarm ses akışı kullanılır).',
            wontDo:
                'Telefonunun sessiz ayarını DEĞİŞTİRMEYİZ; yalnız seans hatırlatması bir kez çalar. Sesten sonra telefonun olduğu gibi kalır. Telefon sessizde değilse hiçbir şeyi sessize almayız.',
            limits:
                '“Rahatsız Etme”yi kendin açtıysan sistemin kuralı geçerlidir; uygulama onu aşmaya çalışmaz. Bazı telefon markaları (Xiaomi, Huawei…) arka plan bildirimini kısıtlar; uygulamanın bildirim ayarlarına bak. İstediğin an kapatabilirsin.');
  }
}

/// Açıklama + onay ekranı. Varsayılan KAPALI; yalnız "Aç"a basınca etkinleşir.
abstract final class LoudAlarmSheet {
  /// Kullanıcı tercihi açtıysa true.
  static Future<bool> show(final BuildContext context) async {
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (final BuildContext ctx) => const _LoudAlarmSheetBody(),
    );
    return ok ?? false;
  }

  /// İlk bilet alma sonrası (bir kez): tercih kapalıysa nazikçe sorar.
  /// Alışveriş diyaloğu kapandıktan sonra kök navigator bağlamıyla açılır.
  static Future<void> maybePromptAfterPurchase() async {
    if (kIsWeb) return;
    try {
      final service = FCMManager.instance.service;
      if (await service.loudAlarmPromptSeen()) return;
      if (await service.loudAlarmEnabled()) return;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final BuildContext? ctx = NavigationKeys.rootNavigator.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await service.markLoudAlarmPromptSeen();
      await show(ctx);
    } catch (e) {
      debugPrint('Sesli hatırlatma önerisi gösterilemedi: $e');
    }
  }
}

class _LoudAlarmSheetBody extends ConsumerStatefulWidget {
  const _LoudAlarmSheetBody();

  @override
  ConsumerState<_LoudAlarmSheetBody> createState() =>
      _LoudAlarmSheetBodyState();
}

class _LoudAlarmSheetBodyState extends ConsumerState<_LoudAlarmSheetBody> {
  bool _busy = false;
  String? _error;

  Future<void> _enable(final bool en) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final LoudAlarmResult r =
        await ref.read(loudAlarmEnabledProvider.notifier).set(true);
    if (!mounted) return;
    if (r == LoudAlarmResult.enabled) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = r == LoudAlarmResult.permissionDenied
          ? (en
              ? 'Notification permission is off. Allow notifications for TiyatRol in system settings first.'
              : 'Bildirim izni kapalı. Önce telefon ayarlarından TiyatRol için bildirimlere izin ver.')
          : (en
              ? 'Could not save your choice. Try again.'
              : 'Tercih kaydedilemedi. Tekrar dene.');
    });
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool en = Localizations.localeOf(context).languageCode == 'en';
    final LoudAlarmCopy c = LoudAlarmCopy.of(en, defaultTargetPlatform);

    Widget block(final IconData icon, final String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(text,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurface))),
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.xs, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 32, color: cs.primary),
            const SizedBox(height: AppSpacing.md),
            Text(c.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.lg),
            block(Icons.volume_up_outlined, c.what),
            block(Icons.shield_outlined, c.wontDo),
            block(Icons.info_outline_rounded, c.limits),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.error)),
              ),
            if (_error != null && !kIsWeb)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: openAppSettings,
                  child: Text(en ? 'Open system settings' : 'Telefon ayarlarını aç'),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_enable(en)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.massive + 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text(en ? 'Turn on' : 'Aç'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text(en ? 'Not now' : 'Şimdi değil'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ayarlar > İzinler satırı: "Sessizdeyken de sesli hatırlat" anahtarı.
/// AÇMAK açıklama ekranını gösterir; KAPATMAK doğrudan uygulanır.
class LoudAlarmSwitchRow extends ConsumerWidget {
  const LoudAlarmSwitchRow({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool enabled = ref.watch(loudAlarmEnabledProvider).value ?? false;
    final bool ios = defaultTargetPlatform == TargetPlatform.iOS;

    Future<void> toggle(final bool want) async {
      if (want) {
        await LoudAlarmSheet.show(context);
      } else {
        await ref.read(loudAlarmEnabledProvider.notifier).set(false);
      }
    }

    return PreferenceRow(
      icon: Icons.notifications_active_outlined,
      title: ios
          ? prefText(context, 'Seans öncesi dikkat çekici hatırlat',
              'Attention-grabbing show reminders')
          : prefText(context, 'Sessizdeyken de sesli hatırlat',
              'Remind loudly, even on silent'),
      subtitle: ios
          ? prefText(
              context,
              'Hatırlatma “Zamana duyarlı” gelir. iPhone’da sessiz anahtarı açıkken ses çıkmaz.',
              'Reminders arrive as “Time Sensitive”. No sound while the silent switch is on.')
          : prefText(
              context,
              'Yalnız seans hatırlatması bir kez çalar. Telefonunun sessiz ayarını değiştirmeyiz.',
              'Only the show reminder plays once. We never change your silent setting.'),
      onTap: () => unawaited(toggle(!enabled)),
      trailing: Switch(
        value: enabled,
        onChanged: (final bool v) => unawaited(toggle(v)),
      ),
    );
  }
}
