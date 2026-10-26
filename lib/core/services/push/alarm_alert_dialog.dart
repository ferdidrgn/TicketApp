import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ön plandayken gelen ALARM için belirgin, kapatılana dek duran uyarı.
/// Renkler temadan (`colorScheme`) gelir; yeni sabit renk yok.
/// Ses + titreşim yerel bildirimin alarm kanalından gelir; burada ek
/// olarak dokunsal geri bildirim verilir.
abstract final class AlarmAlertDialog {
  static bool _open = false;

  /// [onOpen] verilirse "Aç" düğmesi de çıkar.
  static Future<void> show(
    final BuildContext context, {
    required final String title,
    required final String body,
    final VoidCallback? onOpen,
  }) async {
    if (_open || !context.mounted) return;
    _open = true;
    HapticFeedback.heavyImpact();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (final BuildContext ctx) {
          final ColorScheme cs = Theme.of(ctx).colorScheme;
          return Semantics(
            liveRegion: true,
            child: AlertDialog(
              icon: Icon(Icons.notifications_active_rounded,
                  size: 36, color: cs.error),
              title: Text(title, textAlign: TextAlign.center),
              content: body.isEmpty
                  ? null
                  : SingleChildScrollView(
                      child: Text(body, textAlign: TextAlign.center)),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (onOpen != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onOpen();
                    },
                    child: const Text('Aç'),
                  ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _open = false;
    }
  }
}
