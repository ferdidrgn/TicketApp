import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final theme = Theme.of(context);
    final viewModel = ref.watch(ticketViewModelProvider);

    // Debug için - istersek kaldırabiliriz
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (viewModel.isSuccess) viewModel.debugTicketDates();
    });

    return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: RefreshIndicator(
            onRefresh: _loadTicketData,
            color: theme.colorScheme.primary,
            child: _buildBody(viewModel, theme)));
  }

  PreferredSizeWidget _buildAppBar(final ThemeData theme) {
    return AppBar(
      elevation: 10,
      backgroundColor: theme.colorScheme.surface,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        'Biletlerim',
        style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
      ),
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _ElegantTabBar(controller: _tabController, theme: theme))),
    );
  }

  Widget _buildBody(final TicketViewModel viewModel, final ThemeData theme) {
    // VIEWMODEL PROPERTIES KULLANIMI
    if (viewModel.isLoading && viewModel.isEmpty) return const ShimmerLoading();

    if (viewModel.hasError && viewModel.isEmpty)
      return _ElegantErrorWidget(
          error: viewModel.errorMessage!, onRetry: _loadTicketData);

    if (viewModel.isEmpty) return const _ElegantEmptyState();

    if (viewModel.isLoading)
      return Column(
        children: [
          Expanded(
              child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 3, // 3 adet shimmer kart
                  itemBuilder: (final context, final index) =>
                      ShimmerLoading())),
        ],
      );

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

  void _showTicketDetails(final DetailedTicket ticket) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (final _) => TicketDetailsModal(ticket: ticket));
  }
}

// ============================================================
// ELEGANT TAB BAR - SİYAH ÇİZGİ KALDIRILDI
// ============================================================

class _ElegantTabBar extends StatelessWidget {
  final TabController controller;
  final ThemeData theme;

  const _ElegantTabBar({required this.controller, required this.theme});

  @override
  Widget build(final BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16)),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8)
              ],
            ),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.textTheme.titleMedium,
          // Alt çizgiyi kaldırmak için
          dividerColor: Colors.transparent,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Yaklaşan Etkinlikler'),
            Tab(text: 'Geçmiş Etkinlikler'),
          ],
        ),
      );
}

class _ElegantErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ElegantErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.errorContainer,
                      theme.colorScheme.errorContainer.withOpacity(0.7)
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: theme.colorScheme.error.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 48, color: theme.colorScheme.onErrorContainer)),
            const SizedBox(height: 24),
            Text('Bir Sorun Oluştu',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(error,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: Text('Tekrar Dene',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElegantEmptyState extends StatelessWidget {
  const _ElegantEmptyState();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withOpacity(0.6)
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(Icons.confirmation_num_outlined,
                    size: 48, color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 24),
            Text('Henüz Biletiniz Yok',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Satın aldığınız biletler burada görünecek',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ElegantTicketList extends StatefulWidget {
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
  _ElegantTicketListState createState() => _ElegantTicketListState();
}

class _ElegantTicketListState extends State<_ElegantTicketList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(final BuildContext context) {
    super.build(context); // keep alive için gerekli
    if (widget.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (final context, final index) => ShimmerLoading(),
      );
    }

    if (widget.tickets.isEmpty) return _ElegantEmptyTab(isPast: widget.isPast);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.tickets.length,
      itemBuilder: (final context, final index) => _LuxuryTicketCard(
        detailedTicket: widget.tickets[index],
        isPast: widget.isPast,
        onTap: () => widget.onTicketTap(widget.tickets[index]),
      ),
    );
  }
}

class _ElegantEmptyTab extends StatelessWidget {
  final bool isPast;

  const _ElegantEmptyTab({required this.isPast});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isPast
                  ? Icons.history_toggle_off_rounded
                  : Icons.event_available_rounded,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(isPast ? 'Geçmiş bilet bulunmuyor' : 'Yaklaşan bilet bulunmuyor',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    final dateInfo =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Ana Kart
          Card(
            elevation: 6,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPast
                        ? [
                            theme.colorScheme.surfaceVariant,
                            theme.colorScheme.surfaceVariant.withOpacity(0.8),
                          ]
                        : [
                            theme.colorScheme.surface,
                            theme.colorScheme.surfaceContainer,
                          ],
                  ),
                ),
                child: Row(
                  children: [
                    // Tarih Bölümü
                    Container(
                      width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPast
                              ? [
                                  Colors.grey.shade600,
                                  Colors.grey.shade800,
                                ]
                              : [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primaryContainer,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: isPast
                                  ? Colors.grey.withOpacity(0.4)
                                  : theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dateInfo['day'] ?? '??',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 24)),
                          const SizedBox(height: 4),
                          Text((dateInfo['monthName'] ?? '---').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              detailedTicket.show?.name ??
                                  'Gösteri Yükleniyor...',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 18),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          _ElegantInfoRow(
                              icon: Icons.location_on_rounded,
                              text: detailedTicket.stage?.name ??
                                  'Sahne Yükleniyor...',
                              theme: theme),
                          const SizedBox(height: 6),
                          _ElegantInfoRow(
                              icon: Icons.event_seat_rounded,
                              text: detailedTicket.ticket.buySeats.join(", "),
                              theme: theme,
                              isHighlighted: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sağ Üst Köşe Sanatsal Element - PARTİKÜL EFEKTİ
          Positioned(
              top: 12,
              right: 12,
              child: ParticleDecoration(isPast: isPast, theme: theme))
        ],
      ),
    );
  }
}

class _ElegantInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  final bool isHighlighted;

  const _ElegantInfoRow({
    required this.icon,
    required this.text,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: isHighlighted
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon,
                size: 14,
                color: isHighlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isHighlighted ? FontWeight.w600 : FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis))
      ],
    );
  }
}
