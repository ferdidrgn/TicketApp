import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import 'show_detail_data.dart';

/// Sayfanın TEK birincil aksiyonu, damga butonu olarak.
/// - Başka platformda satılan oyun → o platformun bilet sayfası.
/// - Satışta seans var → "Bilet al" (seanslara götürür).
/// - Seans yok → buton yerine açık bir not (sahte/ölü buton yok).
class ShowPrimaryStamp extends StatelessWidget {
  final ShowDetailData data;
  final VoidCallback onBuy;
  final VoidCallback onExternal;
  final bool busy;

  /// Dar koçanda (tablet) daha kısa etiket.
  final bool compact;

  const ShowPrimaryStamp({
    super.key,
    required this.data,
    required this.onBuy,
    required this.onExternal,
    this.busy = false,
    this.compact = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (data.isExternal) {
      return TicketStampButton(
        label: compact ? 'Bilet sayfasına git' : 'Başka platformda bilet al',
        leading: const Icon(Icons.open_in_new_rounded),
        onTap: onExternal,
        loading: busy,
        loadingLabel: 'Açılıyor…',
      );
    }
    if (data.sessions.isEmpty) return const ShowNoSessionNote();
    return TicketStampButton(
      label: 'Bilet al',
      leading: const Icon(Icons.confirmation_number_outlined),
      onTap: onBuy,
    );
  }
}

/// Satışta seans olmadığında aksiyon yerine basılan not.
class ShowNoSessionNote extends StatelessWidget {
  const ShowNoSessionNote({super.key});

  @override
  Widget build(final BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: TicketInk.inkSoft(0.3), width: 1.2),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 18, color: TicketInk.inkSoft(0.6)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Şu an satışta seans yok',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TicketInk.value(size: 13.5)
                    .copyWith(color: TicketInk.inkSoft(0.75)),
              ),
            ),
          ],
        ),
      );
}
