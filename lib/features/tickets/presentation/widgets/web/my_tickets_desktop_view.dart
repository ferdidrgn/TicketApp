import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../providers/my_ticket_provider.dart';
import '../wallet_ticket.dart';

// =============================================================================
// MASAÜSTÜ (WEB) BİLETLERİM
// =============================================================================
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR (mobil çatısı: geri tuşlu
// başlık, "yukarı kaydır" FAB'ı, parçacık zemin). Bu yüzden sayfa kendi
// `Scaffold`'unu kurar — önceden kurmuyordu ve rota bir kabuğun (shell)
// içinde olmadığı için metinler Material atası olmadan (sarı çift alt
// çizgili) çiziliyordu.
//
// Yerleşim: "kenar çubuğu + sütun" — solda yaklaşan biletler (büyük
// koçanlar, en yakın seans en üstte), sağda dar sütunda geçmiş biletler
// (kopuk koçan + OYNANDI damgası). Veri mobille BİREBİR aynı:
// `myTicketsProvider(userId)` + `.upcoming` / `.past`.
class MyTicketsDesktopPage extends StatelessWidget {
  final String userId;
  final void Function(DetailedTicket ticket) onTicketTap;

  const MyTicketsDesktopPage({
    super.key,
    required this.userId,
    required this.onTicketTap,
  });

  @override
  Widget build(final BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: TicketStage(
          themed: true,
          child: SafeArea(
            child: _MyTicketsDesktopBody(
                userId: userId, onTicketTap: onTicketTap),
          ),
        ),
      );
}

class _MyTicketsDesktopBody extends ConsumerStatefulWidget {
  final String userId;
  final void Function(DetailedTicket ticket) onTicketTap;

  const _MyTicketsDesktopBody({required this.userId, required this.onTicketTap});

  @override
  ConsumerState<_MyTicketsDesktopBody> createState() =>
      _MyTicketsDesktopBodyState();
}

class _MyTicketsDesktopBodyState extends ConsumerState<_MyTicketsDesktopBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline =
      CurvedAnimation(parent: _reveal, curve: AppMotion.dramatic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ticketsAsync = ref.watch(myTicketsProvider(widget.userId));
    final cs = Theme.of(context).colorScheme;
    final tickets = ticketsAsync.value;

    String? summary;
    if (tickets != null && tickets.isNotEmpty) {
      final int up = tickets.upcoming.length, past = tickets.past.length;
      summary = up == 0
          ? 'Yaklaşan biletin yok; $past geçmiş bilet.'
          : '$up yaklaşan, $past geçmiş bilet.';
    }

    final Widget header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Geri',
          onPressed: () => NavigationHandler.smartGoBack(context),
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: AuthWipeReveal(
                  reveal: _headline,
                  child: Text(
                    'Biletlerim',
                    style: GoogleFonts.playfairDisplay(
                      color: cs.onSurface,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final Widget content = ticketsAsync.when(
      loading: () => const _DesktopColumns(
        upcoming: [
          WalletTicketSkeleton(large: true),
          SizedBox(height: AppSpacing.xl),
          WalletTicketSkeleton(large: true),
        ],
        past: [WalletTicketSkeleton()],
      ),
      error: (final err, final stack) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.section),
        child: TicketsErrorState(
          onRetry: () => ref.invalidate(myTicketsProvider(widget.userId)),
        ),
      ),
      data: (final tickets) {
        if (tickets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.section),
            child: TicketsEmptyState(),
          );
        }
        final upcoming = tickets.upcoming;
        final past = tickets.past;
        return _DesktopColumns(
          upcoming: [
            if (upcoming.isEmpty)
              const TicketsEmptyState(
                title: 'Yaklaşan biletin yok',
                message: 'Yeni bir oyun seçtiğinde biletin burada, QR '
                    'koduyla seni bekler.',
              )
            else
              for (int i = 0; i < upcoming.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xl),
                WalletTicket(
                  key: ValueKey('ticket-${upcoming[i].ticket.id}'),
                  ticket: upcoming[i],
                  large: true,
                  onTap: () => widget.onTicketTap(upcoming[i]),
                ),
              ],
          ],
          past: [
            if (past.isEmpty)
              Text(
                'Seansı geçen biletlerin burada saklanır.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              )
            else
              for (int i = 0; i < past.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.lg),
                WalletTicket(
                  key: ValueKey('ticket-${past[i].ticket.id}'),
                  ticket: past[i],
                  onTap: () => widget.onTicketTap(past[i]),
                ),
              ],
          ],
        );
      },
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl, AppSpacing.xxxl,
              AppSpacing.xxxl, AppSpacing.section),
          children: [
            header,
            const SizedBox(height: AppSpacing.huge),
            content,
          ],
        ),
      ),
    );
  }
}

/// Solda yaklaşan (geniş), sağda geçmiş (dar) sütun.
class _DesktopColumns extends StatelessWidget {
  final List<Widget> upcoming;
  final List<Widget> past;

  const _DesktopColumns({required this.upcoming, required this.past});

  Widget _heading(final BuildContext context, final String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_heading(context, 'Yaklaşan'), ...upcoming],
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_heading(context, 'Geçmiş'), ...past],
            ),
          ),
        ],
      );
}
