import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../purchase/domain/entities/purchase_entities.dart';
import '../../../purchase/presentation/providers/purchase_provider.dart';
import '../providers/my_ticket_provider.dart';

/// Biletin ödeme/kullanım durumu (rozet + iptal kuralı). Yalnızca gösterim;
/// kesin kural (iptal edilebilir mi) sunucuda denetlenir.
enum TicketPayState { free, venue, paid, noShow, cancelled, unknown }

TicketPayState ticketPayState(final DetailedTicket t) {
  final tk = t.ticket;
  if (tk.isCancelled) return TicketPayState.cancelled;
  if (tk.isNoShow) return TicketPayState.noShow;
  if (tk.paymentStatus == 'paid') return TicketPayState.paid;
  if (tk.isPayAtVenue) return TicketPayState.venue;
  if (tk.orderMethod == 'free') return TicketPayState.free;
  if (tk.orderMethod == 'card') return TicketPayState.paid;
  return TicketPayState.unknown;
}

String ticketPayStateLabel(final TicketPayState s) => switch (s) {
      TicketPayState.free => 'Ücretsiz',
      TicketPayState.venue => 'Rezervasyon · ödeme sahnede',
      TicketPayState.paid => 'Ödendi',
      TicketPayState.noShow => 'Gelmedi',
      TicketPayState.cancelled => 'İptal',
      TicketPayState.unknown => '',
    };

/// Bu bilet kullanıcı tarafından iptal edilebilir görünüyor mu?
/// (rezervasyon/ücretsiz, kullanılmamış, başlangıca >= [iptalSaat] saat var.)
bool canCancelTicket(
    final DetailedTicket t, final int iptalSaat, final DateTime now) {
  final tk = t.ticket;
  if (tk.isCancelled || tk.isNoShow || tk.usedAt.isNotEmpty || t.isPast) {
    return false;
  }
  if (tk.paymentStatus == 'paid') return false;
  if (tk.orderMethod != 'venue' && tk.orderMethod != 'free') return false;
  final DateTime? start = DateFormatter.parseDateString(t.dateText);
  if (start == null) return false;
  return start.difference(now) >= Duration(hours: iptalSaat);
}

/// Küçük, kenarlıklı durum rozeti (bilet mürekkebi diliyle).
class TicketStatusBadge extends StatelessWidget {
  final TicketPayState state;

  const TicketStatusBadge({super.key, required this.state});

  @override
  Widget build(final BuildContext context) {
    final String label = ticketPayStateLabel(state);
    if (label.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final Color color = switch (state) {
      TicketPayState.venue => TicketInk.accentOf(context),
      TicketPayState.cancelled || TicketPayState.noShow => cs.error,
      _ => TicketInk.inkSoft(0.75),
    };
    return Semantics(
      label: 'Bilet durumu: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// İptal akışı: onay diyaloğu → `cancelTicket`. Başarılıysa `true` döner;
/// sunucu hatası diyalogda gösterilir.
Future<bool> confirmAndCancelTicket(
  final BuildContext context,
  final WidgetRef ref,
  final DetailedTicket t,
) async {
  final cancel = ref.read(cancelTicketUseCaseProvider);
  final ok = await showDialog<bool>(
    context: context,
    builder: (final _) => _CancelTicketDialog(
      seats: t.ticket.buySeats,
      run: () => cancel(t.ticket.id),
    ),
  );
  return ok ?? false;
}

class _CancelTicketDialog extends StatefulWidget {
  final List<String> seats;
  final Future<Either<Failure, void>> Function() run;

  const _CancelTicketDialog({required this.seats, required this.run});

  @override
  State<_CancelTicketDialog> createState() => _CancelTicketDialogState();
}

class _CancelTicketDialogState extends State<_CancelTicketDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.run();
    if (!mounted) return;
    r.fold(
      (final f) => setState(() {
        _busy = false;
        _error = f.message;
      }),
      (final _) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String seats = widget.seats.isEmpty
        ? 'koltuğun'
        : (widget.seats.length > 1
            ? 'koltukların (${widget.seats.join(", ")})'
            : 'koltuğun (${widget.seats.first})');
    return AlertDialog(
      title: const Text('Bileti iptal et?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bileti iptal edersen $seats serbest kalır ve başkası '
              'alabilir. Bu işlem geri alınamaz.'),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _busy ? null : _go,
          style: FilledButton.styleFrom(
              backgroundColor: cs.error, foregroundColor: cs.onError),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Bileti iptal et'),
        ),
      ],
    );
  }
}

/// Biletlerim detayında: iptal edilebiliyorsa sessiz "İptal et" bağlantısı.
class TicketCancelLink extends ConsumerWidget {
  final DetailedTicket ticket;
  final VoidCallback onCancelled;

  const TicketCancelLink(
      {super.key, required this.ticket, required this.onCancelled});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final SalesConfig cfg = ref.watch(salesConfigProvider);
    if (!canCancelTicket(ticket, cfg.iptalSaat, DateTime.now())) {
      return const SizedBox.shrink();
    }
    return TicketTextLink(
      label: 'İptal et',
      onTap: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final done = await confirmAndCancelTicket(context, ref, ticket);
        if (!done) return;
        ref.invalidate(myTicketsProvider(ticket.ticket.customerId));
        messenger?.showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Biletin iptal edildi.')));
        onCancelled();
      },
    );
  }
}
