import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/tickets/presentation/pages/ticket_details_modal.dart';
import '../../../../shared/widgets/top_header_with_back_button.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../providers/my_ticket_provider.dart';

class MyTicketPage extends ConsumerStatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  ConsumerState<MyTicketPage> createState() => _MyTicketPageState();
}

class _MyTicketPageState extends ConsumerState<MyTicketPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final ticketsAsync = ref.watch(myTicketsProvider(widget.userId));

    return Scaffold(
        backgroundColor: context.colors.surface,
        body: CustomAppBackground(
            child: SafeArea(
          child: Column(
            children: [
              TopHeaderWithBackButton(
                title: 'Sanat Ajandan',
                subtitle: 'Unutulmaz anların koleksiyonu...',
                rightIcon: Icons.theater_comedy_rounded,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _TabSelector(controller: _tabController),
              ),
              Expanded(
                child: RefreshIndicator(
                  // Listeyi yenilemek için invalidate yeterli
                  onRefresh: () async =>
                      ref.invalidate(myTicketsProvider(widget.userId)),
                  color: context.colors.primary,
                  child: ticketsAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: 3,
                      itemBuilder: (final _, final __) => const ShimmerCard(),
                    ),
                    error: (final err, final stack) =>
                        Center(child: Text('Hata: $err')),
                    data: (final tickets) {
                      if (tickets.isEmpty) return const _EmptyState();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _TicketList(
                            // Extension sayesinde filtreleme
                            tickets: tickets.upcoming,
                            onTicketTap: _showTicketDetails,
                          ),
                          _TicketList(
                            tickets: tickets.past,
                            isPast: true,
                            onTicketTap: _showTicketDetails,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        )));
  }

  void _showTicketDetails(final DetailedTicket ticket) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) => TicketDetailsModal(ticket: ticket));
  }
}

class _TicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _TicketCard(
      {required this.detailedTicket, required this.onTap, this.isPast = false});

  @override
  Widget build(final BuildContext context) =>
      GestureDetector(onTap: onTap, child: _buildBaseCard(context));

  Widget _buildBaseCard(final BuildContext context) {
    final dateInfo =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _ArtDateSidebar(
                day: dateInfo['day'] ?? '00',
                month: (dateInfo['monthName'] ?? '---').toUpperCase(),
                isPast: isPast,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detailedTicket.show?.name ?? 'Sanat Eseri',
                          style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color:
                                  isPast ? colors.outline : colors.onSurface)),
                      const SizedBox(height: 12),
                      _ArtInfoLine(
                          icon: Icons.castle_rounded,
                          text: detailedTicket.stage?.name ?? 'Sahne'),
                      const Spacer(),
                      const Divider(height: 20, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isPast ? "SERGİLENDİ" : "SAHNELENİYOR",
                              style: context.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary)),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: colors.outline),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtDateSidebar extends StatelessWidget {
  final String day;
  final String month;
  final bool isPast;
  final bool isMagic;

  const _ArtDateSidebar(
      {required this.day,
      required this.month,
      required this.isPast,
      this.isMagic = false});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      width: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isMagic
              ? [themeColors.primary, themeColors.tertiary]
              : (isPast
                  ? [Colors.grey.shade400, Colors.grey.shade600]
                  : [
                      themeColors.primary,
                      themeColors.primary.withOpacity(0.7)
                    ]),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotatedBox(
            quarterTurns: 3,
            child: Text(month,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4)),
          ),
          const SizedBox(height: 8),
          Text(day,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final TabController controller;

  const _TabSelector({required this.controller});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: themeColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColors.outlineVariant.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [themeColors.primary, themeColors.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: themeColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: themeColors.onPrimary,
        unselectedLabelColor: themeColors.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.auto_awesome, size: 16),
                SizedBox(width: 8),
                Text("Sıradakiler")
              ])),
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.history_edu, size: 16),
                SizedBox(width: 8),
                Text("Anılar")
              ])),
        ],
      ),
    );
  }
}

class _ArtInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;

  const _ArtInfoLine(
      {required this.icon, required this.text, this.isBold = false});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 14,
              color: context.colors.onSurfaceVariant.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _TicketList extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final bool isPast;
  final Function(DetailedTicket) onTicketTap;

  const _TicketList(
      {required this.tickets, required this.onTicketTap, this.isPast = false});

  @override
  Widget build(final BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        itemCount: tickets.length,
        itemBuilder: (final context, final index) => _TicketCard(
          detailedTicket: tickets[index],
          isPast: isPast,
          onTap: () => onTicketTap(tickets[index]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined,
                size: 60, color: context.colors.outline),
            const SizedBox(height: 16),
            const Text("Sahne henüz boş...",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
