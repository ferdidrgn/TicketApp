import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/tickets/presentation/pages/ticket_details_modal.dart';
import 'package:ticketapp/features/tickets/presentation/providers/ticket_provider.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/particle_decoration.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import 'my_ticket_viewmodel.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _loadTicketData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketData() async {
    final currentState = ref.read(ticketProvider);
    if (currentState.isLoading) return;

    await ref
        .read(ticketProvider.notifier)
        .loadTicketsAndDetailsByCustomerId(widget.userId);
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    final viewModel = ref.watch(ticketViewModelProvider);

    return Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
            onRefresh: _loadTicketData,
            color: context.theme.colorScheme.primary,
            child: _buildBody(viewModel)));
  }

  PreferredSizeWidget _buildAppBar() {
    final themeColors = context.colors;
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: themeColors.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        'Biletlerim',
        style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700, color: themeColors.onSurface),
      ),
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _ElegantTabBar(controller: _tabController))),
    );
  }

  Widget _buildBody(final TicketViewModel viewModel) {
    if (viewModel.isLoading && viewModel.isEmpty) return const ShimmerCard();

    if (viewModel.hasError && viewModel.isEmpty)
      return _ElegantErrorWidget(
          error: viewModel.errorMessage!, onRetry: _loadTicketData);

    if (viewModel.isEmpty) return const _ElegantEmptyState();

    return TabBarView(
      controller: _tabController,
      children: [
        // VIEWMODEL METHODS KULLANIMI
        _ElegantTicketList(
            tickets: viewModel.upcomingTickets,
            isLoading: viewModel.isLoading,
            onTicketTap: _showTicketDetails),
        _ElegantTicketList(
            tickets: viewModel.pastTickets,
            isPast: true,
            isLoading: viewModel.isLoading,
            onTicketTap: _showTicketDetails)
      ],
    );
  }

  void _showTicketDetails(final DetailedTicket ticket) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (final _) => TicketDetailsModal(ticket: ticket));
}

// ============================================================
// ELEGANT TAB BAR
// ============================================================

class _ElegantTabBar extends StatelessWidget {
  final TabController controller;

  const _ElegantTabBar({required this.controller});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      height: 52,
      decoration: BoxDecoration(
          color: themeColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16)),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [themeColors.primary, themeColors.primary.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
                color: themeColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: themeColors.onPrimary,
        unselectedLabelColor: themeColors.onSurfaceVariant,
        labelStyle: context.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Yaklaşanlar'),
          Tab(text: 'Geçmiş'),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR WIDGET
// ============================================================

class _ElegantErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ElegantErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: context.colors.error),
              const SizedBox(height: 24),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: onRetry, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
}

// ============================================================
// EMPTY STATE
// ============================================================

class _ElegantEmptyState extends StatelessWidget {
  const _ElegantEmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_num_outlined,
                size: 64, color: context.colors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Henüz biletiniz bulunmuyor'),
          ],
        ),
      );
}

// ============================================================
// TICKET LIST
// ============================================================

class _ElegantTicketList extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final bool isPast;
  final bool isLoading;
  final Function(DetailedTicket) onTicketTap;

  const _ElegantTicketList({
    required this.tickets,
    required this.onTicketTap,
    this.isPast = false,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading)
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (final context, final index) => const ShimmerLoading(),
      );

    if (tickets.isEmpty)
      return Center(
          child: Text(isPast ? 'Geçmiş bilet yok' : 'Yaklaşan bilet yok'));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (final context, final index) => _LuxuryTicketCard(
        detailedTicket: tickets[index],
        isPast: isPast,
        onTap: () => onTicketTap(tickets[index]),
      ),
    );
  }
}

// ============================================================
// LUXURY TICKET CARD
// ============================================================

class _LuxuryTicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _LuxuryTicketCard({
    required this.detailedTicket,
    required this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    final dateInfo =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      isPast ? themeColors.surfaceVariant : themeColors.surface,
                ),
                child: Row(
                  children: [
                    _DateBox(
                        day: dateInfo['day'] ?? '??',
                        month: dateInfo['monthName'] ?? '---',
                        isPast: isPast),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(detailedTicket.show?.name ?? 'Yükleniyor...',
                              style: context.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2),
                          const SizedBox(height: 12),
                          _ElegantInfoRow(
                              icon: Icons.location_on_rounded,
                              text: detailedTicket.stage?.name ?? 'Bilinmiyor'),
                          const SizedBox(height: 6),
                          _ElegantInfoRow(
                              icon: Icons.event_seat_rounded,
                              text: detailedTicket.ticket.buySeats.join(", "),
                              isHighlighted: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              top: 12, right: 12, child: ParticleDecoration(isPast: isPast))
        ],
      ),
    );
  }
}

// ============================================================
// HELPER COMPONENTS (CONTEXT BASED)
// ============================================================

class _DateBox extends StatelessWidget {
  final String day;
  final String month;
  final bool isPast;

  const _DateBox(
      {required this.day, required this.month, required this.isPast});

  @override
  Widget build(final BuildContext context) => Container(
        width: 80,
        decoration: BoxDecoration(
          color: isPast ? Colors.grey : context.colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            Text(month.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      );
}

class _ElegantInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isHighlighted;

  const _ElegantInfoRow(
      {required this.icon, required this.text, this.isHighlighted = false});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    final color =
        isHighlighted ? themeColors.primary : themeColors.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight:
                      isHighlighted ? FontWeight.bold : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        )
      ],
    );
  }
}
