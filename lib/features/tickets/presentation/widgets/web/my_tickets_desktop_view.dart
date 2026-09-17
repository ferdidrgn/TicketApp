import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/util/date_formatter.dart';
import '../../../../../shared/widgets/section_header.dart';
import '../../providers/my_ticket_provider.dart';

// =============================================================================
// MASAÜSTÜ (WEB) "SANAT AJANDAN" (BİLETLERİM) SAYFASI
// =============================================================================
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — mobil uygulama çatısıdır
// (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı, pull-to-refresh,
// `CustomAppBackground`'ın rastgele renkli parçacık noktaları). Bkz.
// `nearby_events_page.dart`'taki `_NearbyEventsDesktopPage` — aynı gerekçe.
//
// Veri kaynağı mobille BİREBİR aynı: `myTicketsProvider(userId)` ve onun
// `DetailedTicketListX.upcoming`/`.past` uzantısı — gerçek Firestore bileti +
// gerçek etkinlik tarihine göre hesaplanan `isPast`. Uydurma bilet/sayı yok.
class MyTicketsDesktopPage extends StatelessWidget {
  final String userId;
  final void Function(DetailedTicket ticket) onTicketTap;

  const MyTicketsDesktopPage({
    super.key,
    required this.userId,
    required this.onTicketTap,
  });

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: Gövde kendi `ListView`'ı ile zaten kaydırılabilir — burada
        // ikinci bir SingleChildScrollView SARMAK "unbounded height"
        // hatasına yol açar, bilerek eklenmedi.
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: _MyTicketsDesktopBody(userId: userId, onTicketTap: onTicketTap),
          ),
        ),
      );
}

class _MyTicketsDesktopBody extends ConsumerWidget {
  final String userId;
  final void Function(DetailedTicket ticket) onTicketTap;

  const _MyTicketsDesktopBody({required this.userId, required this.onTicketTap});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider(userId));

    return ticketsAsync.when(
      loading: () => const _TicketsLoadingState(),
      error: (final err, final stack) => _TicketsErrorNotice(error: err),
      data: (final tickets) {
        if (tickets.isEmpty) return const _TicketsEmptyState();

        final upcoming = tickets.upcoming;
        final past = tickets.past;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 36),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _TicketsDesktopBanner(
                  upcomingCount: upcoming.length, pastCount: past.length),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionHeader(
                title: 'Sıradaki Biletlerin',
                subtitle: upcoming.isEmpty ? null : '${upcoming.length} etkinlik',
                titleColor: Colors.white,
                accentColor: WebColors.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            upcoming.isEmpty
                ? const _SectionEmptyNotice(
                    message: 'Şu anda sırada bekleyen bir bilet yok.')
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _TicketsGrid(tickets: upcoming, onTap: onTicketTap),
                  ),
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionHeader(
                title: 'Anılar',
                subtitle: past.isEmpty ? null : '${past.length} geçmiş etkinlik',
                titleColor: Colors.white,
                accentColor: WebColors.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            past.isEmpty
                ? const _SectionEmptyNotice(
                    message: 'Henüz sahnelenmiş bir etkinliğin yok.')
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _TicketsGrid(
                        tickets: past, onTap: onTicketTap, isPast: true),
                  ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

class _TicketsGrid extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final void Function(DetailedTicket ticket) onTap;
  final bool isPast;

  const _TicketsGrid(
      {required this.tickets, required this.onTap, this.isPast = false});

  @override
  Widget build(final BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.05,
        ),
        itemCount: tickets.length,
        itemBuilder: (final context, final index) => _DesktopTicketCard(
          key: ValueKey('ticket-${tickets[index].ticket.id}'),
          detailedTicket: tickets[index],
          isPast: isPast,
          onTap: () => onTap(tickets[index]),
        ),
      );
}

class _DesktopTicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _DesktopTicketCard(
      {super.key,
      required this.detailedTicket,
      required this.onTap,
      this.isPast = false});

  @override
  Widget build(final BuildContext context) {
    final dateInfo =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          // Asimetrik köşeler — nearby/discovery kartlarıyla aynı "premium"
          // imza.
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(
              color: (isPast ? Colors.white : WebColors.primaryGold)
                  .withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih Şeridi
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: BoxDecoration(
                gradient: isPast
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          WebColors.primaryGold.withOpacity(0.16),
                          Colors.transparent,
                        ],
                      ),
                color: isPast ? Colors.white.withOpacity(0.04) : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateInfo['day'] ?? '00',
                        style: TextStyle(
                          color: isPast ? Colors.white54 : Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (dateInfo['monthName'] ?? '---').toUpperCase(),
                        style: TextStyle(
                          color: isPast
                              ? Colors.white38
                              : WebColors.primaryGoldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.white.withOpacity(0.08)
                          : WebColors.primaryGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPast ? 'SERGİLENDİ' : 'SAHNELENİYOR',
                      style: TextStyle(
                        color: isPast ? Colors.white60 : WebColors.primaryGoldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      detailedTicket.show?.name ?? 'Sanat Eseri',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPast ? Colors.white70 : Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.castle_rounded,
                                size: 15,
                                color: isPast
                                    ? Colors.white38
                                    : WebColors.primaryGoldLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detailedTicket.stage?.name ?? 'Sahne',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: WebColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Colors.white12),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateInfo['time'] ?? '--:--',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded,
                                size: 16, color: Colors.white38),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketsDesktopBanner extends StatelessWidget {
  final int upcomingCount;
  final int pastCount;

  const _TicketsDesktopBanner(
      {required this.upcomingCount, required this.pastCount});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: WebColors.cardGradient,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sanat Ajandan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.h3Size,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    upcomingCount == 0
                        ? 'Sırada bekleyen bir biletin yok, geçmişte $pastCount anın var.'
                        : '$upcomingCount yaklaşan biletin, $pastCount de geçmiş anın var.',
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.theater_comedy_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      );
}

class _TicketsLoadingState extends StatelessWidget {
  const _TicketsLoadingState();

  @override
  Widget build(final BuildContext context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
        ),
      );
}

class _TicketsErrorNotice extends StatelessWidget {
  final Object error;

  const _TicketsErrorNotice({required this.error});

  @override
  Widget build(final BuildContext context) => Center(
        child: Text(
          'Biletlerin yüklenemedi: $error',
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
}

class _TicketsEmptyState extends StatelessWidget {
  const _TicketsEmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined,
                size: 60, color: WebColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Sahne henüz boş...',
              style: TextStyle(
                color: WebColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
}

class _SectionEmptyNotice extends StatelessWidget {
  final String message;

  const _SectionEmptyNotice({required this.message});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          message,
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );
}
