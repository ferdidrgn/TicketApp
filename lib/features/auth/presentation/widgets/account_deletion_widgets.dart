import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/account_deletion_service.dart';
import '../providers/account_deletion_provider.dart';

/// Onay diyalogundaki metin: bekleme süresini ve kesin tarihi söyler.
String deletionConfirmMessage(final DateTime scheduledAt) =>
    'Hesabınız $kAccountDeletionGraceDays gün sonra, '
    '${formatDeletionDate(scheduledAt)} tarihinde kalıcı olarak silinecek. '
    'Bu süre içinde giriş yapıp vazgeçebilirsiniz. Süre dolunca hesabınız '
    've kişisel verileriniz kalıcı olarak silinir; bilet kayıtları yasal '
    'saklama gereği kişisel bilgiler olmadan tutulur.';

/// "2 bilet · en yakın: Hamlet, 12 Kasım 2026" satırı.
String upcomingTicketsSummary(final UpcomingTicketsException e) {
  final parts = <String>['${e.count} bilet'];
  final title = e.nextEventTitle;
  final date = e.nextEventDate;
  if (title != null || date != null) {
    final next = [
      if (title != null) title,
      if (date != null) formatDeletionDate(date),
    ].join(', ');
    parts.add('en yakın: $next');
  }
  return parts.join(' · ');
}

/// Gelecek bileti olan kullanıcının silme isteğinin reddi.
/// Tek birincil eylem: Biletlerim'e git.
class UpcomingTicketsSheet extends StatelessWidget {
  final UpcomingTicketsException reason;
  final VoidCallback onGoToTickets;

  const UpcomingTicketsSheet(
      {super.key, required this.reason, required this.onGoToTickets});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 32, color: cs.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Gelecek etkinlik biletiniz var',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(upcomingTicketsSummary(reason),
                style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'Hesabınızı silebilmek için önce biletlerinizi kullanmanız '
                'ya da iptal etmeniz gerekir. Online ödenmiş biletler '
                'uygulamadan iptal edilemez; iptal için bizimle iletişime '
                'geçin.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onGoToTickets,
                child: const Text("Biletlerim'e git"),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Silme beklerken uygulamanın üstünde kalıcı şerit:
/// "Hesabınız <tarih> tarihinde silinecek" + "Silmeyi iptal et".
class AccountDeletionBanner extends ConsumerStatefulWidget {
  const AccountDeletionBanner({super.key});

  @override
  ConsumerState<AccountDeletionBanner> createState() =>
      _AccountDeletionBannerState();
}

class _AccountDeletionBannerState extends ConsumerState<AccountDeletionBanner> {
  bool _busy = false;

  Future<void> _cancel() async {
    setState(() => _busy = true);
    final error =
        await ref.read(accountDeletionControllerProvider).cancel();
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(error ?? 'Hesap silme iptal edildi.'),
      ));
  }

  @override
  Widget build(final BuildContext context) {
    final info = ref.watch(accountDeletionInfoProvider).value;
    if (info == null) return const SizedBox.shrink();
    return AccountDeletionBannerView(
      scheduledAt: info.scheduledAt,
      busy: _busy,
      onCancel: _cancel,
    );
  }
}

/// Saf görünüm (test edilebilir).
class AccountDeletionBannerView extends StatelessWidget {
  final DateTime scheduledAt;
  final bool busy;
  final VoidCallback onCancel;

  const AccountDeletionBannerView({
    super.key,
    required this.scheduledAt,
    required this.onCancel,
    this.busy = false,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Hesabınız ${formatDeletionDate(scheduledAt)} tarihinde silinecek',
      child: Material(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded,
                  size: 20, color: cs.onErrorContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Hesabınız ${formatDeletionDate(scheduledAt)} tarihinde silinecek',
                  style: tt.bodyMedium?.copyWith(
                      color: cs.onErrorContainer, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(
                      foregroundColor: cs.onErrorContainer),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Silmeyi iptal et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
