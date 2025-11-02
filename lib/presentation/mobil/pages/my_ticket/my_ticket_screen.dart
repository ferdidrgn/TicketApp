import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import 'package:ticketapp/data/providers/ticket/ticket_provider.dart';
import 'package:ticketapp/domain/entities/event.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/domain/entities/ticket.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../data/providers/ticket/ticket_notifier.dart';
import '../../../../data/providers/ticket/ticket_state.dart';

// ============================================================
// MAIN PAGE
// ============================================================

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
    final ticketState = ref.watch(ticketProvider);

    final (upcomingTickets, pastTickets) = _processTickets(ticketState);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: _loadTicketData,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: _buildBody(ticketState, upcomingTickets, pastTickets),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(final ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Biletlerim',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _GlassmorphicTabBar(
          controller: _tabController,
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildBody(
    final TicketState state,
    final List<DetailedTicket> upcomingTickets,
    final List<DetailedTicket> pastTickets,
  ) {
    if (state.isLoading && state.relatedShows == null) {
      return const _LoadingShimmer();
    }

    if (state.errorMessage != null && (state.dataList?.isEmpty ?? true)) {
      return _ErrorWidget(
        error: state.errorMessage!,
        onRetry: _loadTicketData,
      );
    }

    if ((state.dataList?.isEmpty ?? true) && !state.isLoading) {
      return const _EmptyStateWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _TicketListView(
          tickets: upcomingTickets,
          isLoading: state.isLoading,
          onTicketTap: _showTicketDetails,
        ),
        _TicketListView(
          tickets: pastTickets,
          isPast: true,
          isLoading: state.isLoading,
          onTicketTap: _showTicketDetails,
        ),
      ],
    );
  }

  (List<DetailedTicket>, List<DetailedTicket>) _processTickets(
    final TicketState state,
  ) {
    final tickets = state.dataList ?? [];
    if (tickets.isEmpty) return ([], []);

    final showMap = {
      for (final s in state.relatedShows ?? []) s.id: s,
    };
    final eventMap = {
      for (final e in state.relatedEvents ?? []) e.id: e,
    };
    final stageMap = {
      for (final s in state.relatedStages ?? []) s.id: s,
    };

    final now = DateTime.now();
    final detailedTickets = <DetailedTicket>[];

    for (final ticket in tickets) {
      final event = eventMap[ticket.eventId];
      final eventDate = event?.date != null
          ? DateFormatter.parseDateString(event!.date)
          : null;
      final isPast = eventDate?.isBefore(now) ?? false;

      detailedTickets.add(
        DetailedTicket(
          ticket: ticket,
          show: showMap[ticket.showId],
          event: event,
          stage: stageMap[ticket.stageId],
          isPast: isPast,
        ),
      );
    }

    detailedTickets.sort((final a, final b) {
      final aDate = DateFormatter.parseDateString(a.event?.date ?? '');
      final bDate = DateFormatter.parseDateString(b.event?.date ?? '');
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });

    final upcoming = detailedTickets.where((final t) => !t.isPast).toList();
    final past = detailedTickets.where((final t) => t.isPast).toList();

    return (upcoming, past);
  }

  void _showTicketDetails(final DetailedTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (final _) => _TicketDetailsModal(ticket: ticket),
    );
  }
}

// ============================================================
// GLASSMORPHIC TAB BAR
// ============================================================

class _GlassmorphicTabBar extends StatelessWidget {
  final TabController controller;
  final ThemeData theme;

  const _GlassmorphicTabBar({
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor:
              theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'AKTİF'),
            Tab(text: 'GEÇMİŞ'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOADING SHIMMER
// ============================================================

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(final BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 5,
      itemBuilder: (final context, final index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: const ShimmerLoading(
            width: double.infinity,
            height: 160,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR WIDGET
// ============================================================

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.errorContainer,
                        theme.colorScheme.errorContainer.withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.error.withOpacity(0.2),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Bir Hata Oluştu',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Tekrar Dene',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE WIDGET
// ============================================================

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primaryContainer.withOpacity(0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.confirmation_num_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Bilet Bulunamadı',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Henüz satın alınmış bir biletiniz\nbulunmamaktadır.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TICKET LIST VIEW
// ============================================================

class _TicketListView extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final bool isPast;
  final bool isLoading;
  final Function(DetailedTicket) onTicketTap;

  const _TicketListView({
    required this.tickets,
    required this.onTicketTap,
    this.isPast = false,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (tickets.isEmpty && !isLoading) {
      return _EmptyTabContent(isPast: isPast);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (final context, final index) => _PremiumTicketCard(
        detailedTicket: tickets[index],
        isPast: isPast,
        onTap: () => onTicketTap(tickets[index]),
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  final bool isPast;

  const _EmptyTabContent({required this.isPast});

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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isPast ? Icons.history_rounded : Icons.event_available_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPast
                  ? 'Geçmiş bilet bulunmamaktadır'
                  : 'Aktif bilet bulunmamaktadır',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM TICKET CARD
// ============================================================

class _PremiumTicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _PremiumTicketCard({
    required this.detailedTicket,
    required this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final dateInfo = DateFormatter.formatForEventCard(
      detailedTicket.event?.date ?? '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isPast
              ? []
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  // Background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPast
                              ? [
                                  theme.colorScheme.surfaceContainerHigh,
                                  theme.colorScheme.surfaceContainer,
                                ]
                              : [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.surfaceContainerLow,
                                ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Row(
                    children: [
                      _ArtisticDateSection(
                        dateInfo: dateInfo,
                        isPast: isPast,
                        theme: theme,
                      ),
                      Expanded(
                        child: _TicketContent(
                          detailedTicket: detailedTicket,
                          isPast: isPast,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),

                  // Decorative pattern overlay
                  if (!isPast)
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.03,
                        child: Icon(
                          Icons.confirmation_num_rounded,
                          size: 120,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtisticDateSection extends StatelessWidget {
  final Map<String, String> dateInfo;
  final bool isPast;
  final ThemeData theme;

  const _ArtisticDateSection({
    required this.dateInfo,
    required this.isPast,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPast
              ? [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHigh,
                ]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isPast
                ? Colors.transparent
                : theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ),

          // Date content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateInfo['day'] ?? '?',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isPast
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    shadows: isPast
                        ? []
                        : [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPast
                        ? theme.colorScheme.surfaceContainer
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (dateInfo['monthName'] ?? '---').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPast
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPast
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPast
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isPast
                            ? theme.colorScheme.onSurfaceVariant
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateInfo['time'] ?? '--:--',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isPast
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketContent extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final ThemeData theme;

  const _TicketContent({
    required this.detailedTicket,
    required this.isPast,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    final showName = detailedTicket.show?.name ?? 'Gösteri Yükleniyor...';
    final stageName = detailedTicket.stage?.name ?? 'Sahne Yükleniyor...';
    final seats = detailedTicket.ticket.buySeats.join(", ");

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                    decorationThickness: 2,
                    color: isPast
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isPast
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                          ],
                        ),
                  color:
                      isPast ? theme.colorScheme.surfaceContainerHighest : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isPast
                      ? []
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isPast
                      ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _InfoChip(
            icon: Icons.location_on_rounded,
            text: stageName,
            isPast: isPast,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _InfoChip(
            icon: Icons.event_seat_rounded,
            text: seats,
            isPast: isPast,
            theme: theme,
            highlighted: !isPast,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPast;
  final ThemeData theme;
  final bool highlighted;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isPast,
    required this.theme,
    this.highlighted = false,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted && !isPast
            ? theme.colorScheme.primaryContainer.withOpacity(0.6)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted && !isPast
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted && !isPast
                ? theme.colorScheme.primary
                : isPast
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                    : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlighted && !isPast
                    ? theme.colorScheme.onPrimaryContainer
                    : isPast
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TICKET DETAILS MODAL
// ============================================================

class _TicketDetailsModal extends StatelessWidget {
  final DetailedTicket ticket;

  const _TicketDetailsModal({required this.ticket});

  @override
  Widget build(final BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (final context, final scrollController) {
        return _TicketDetailsContent(
          controller: scrollController,
          ticket: ticket,
        );
      },
    );
  }
}

class _TicketDetailsContent extends StatelessWidget {
  final ScrollController controller;
  final DetailedTicket ticket;

  const _TicketDetailsContent({
    required this.controller,
    required this.ticket,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final dateInfo = DateFormatter.formatForEventCard(ticket.event?.date ?? '');
    final dateText =
        "${dateInfo['day']} ${dateInfo['monthName']} ${DateTime.now().year}";
    final timeText = dateInfo['time'] ?? '--:--';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Artistic drag handle
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.3),
                        theme.colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bilet Detayları',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _HeroImageSection(
                  imageUrl: ticket.show?.imageUrl ?? '',
                  title: ticket.show?.name ?? 'Gösteri Adı',
                  theme: theme,
                ),
                const SizedBox(height: 32),
                _LuxuryQRSection(
                  ticketId: ticket.ticket.id,
                  theme: theme,
                ),
                const SizedBox(height: 32),
                _DetailsSection(
                  ticket: ticket,
                  dateText: dateText,
                  timeText: timeText,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImageSection extends StatelessWidget {
  final String imageUrl;
  final String title;
  final ThemeData theme;

  const _HeroImageSection({
    required this.imageUrl,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Image with shimmer
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (final context, final url) =>
                  const ShimmerLoading(height: 240),
              errorWidget: (final context, final url, final error) => Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.surfaceContainer,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 72,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
            ),

            // Artistic gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Title with backdrop blur
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxuryQRSection extends StatelessWidget {
  final String ticketId;
  final ThemeData theme;

  const _LuxuryQRSection({
    required this.ticketId,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bilet QR Kodu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.8),
                theme.colorScheme.primaryContainer.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // QR Code with artistic frame
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: ticketId,
                      version: QrVersions.auto,
                      size: 110,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: theme.colorScheme.primary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'GİRİŞ KODU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bu kodu girişte\ngösterin',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            ticketId,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final DetailedTicket ticket;
  final String dateText;
  final String timeText;
  final ThemeData theme;

  const _DetailsSection({
    required this.ticket,
    required this.dateText,
    required this.timeText,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.tertiary,
                    theme.colorScheme.tertiary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.tertiary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.onTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bilet Bilgileri',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _LuxuryDetailTile(
          icon: Icons.event_seat_rounded,
          title: 'Koltuk Numaraları',
          subtitle: ticket.ticket.buySeats.join(", "),
          color: theme.colorScheme.primary,
          theme: theme,
        ),
        _LuxuryDetailTile(
          icon: Icons.location_on_rounded,
          title: 'Sahne',
          subtitle: ticket.stage?.name ?? 'Yükleniyor...',
          theme: theme,
        ),
        _LuxuryDetailTile(
          icon: Icons.calendar_month_rounded,
          title: 'Tarih',
          subtitle: dateText,
          theme: theme,
        ),
        _LuxuryDetailTile(
          icon: Icons.access_time_filled_rounded,
          title: 'Saat',
          subtitle: timeText,
          theme: theme,
        ),
        _LuxuryDetailTile(
          icon: Icons.payments_rounded,
          title: 'Ödenen Tutar',
          subtitle: '${ticket.ticket.orderPrice} TL',
          theme: theme,
        ),
        _LuxuryDetailTile(
          icon: Icons.credit_card_rounded,
          title: 'Ödeme Yöntemi',
          subtitle: ticket.ticket.orderMethod,
          theme: theme,
          isLast: true,
        ),
      ],
    );
  }
}

class _LuxuryDetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final ThemeData theme;
  final bool isLast;

  const _LuxuryDetailTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.color,
    this.isLast = false,
  });

  @override
  Widget build(final BuildContext context) {
    final isHighlighted = color != null;
    final tileColor = isHighlighted
        ? color!.withOpacity(0.12)
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6);
    final iconColor = isHighlighted ? color! : theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted
              ? color!.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color!.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor,
                  iconColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isHighlighted ? color : theme.colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
