import 'dart:async';
import 'dart:math';
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
// LÜKS & ŞIK TASARIM
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
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: _loadTicketData,
        color: theme.colorScheme.primary,
        child: _buildBody(ticketState, upcomingTickets, pastTickets),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(final ThemeData theme) {
    return AppBar(
      elevation: 0,
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
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _ElegantTabBar(
            controller: _tabController,
            theme: theme,
          ),
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
      return const _ElegantLoadingShimmer();
    }

    if (state.errorMessage != null && (state.dataList?.isEmpty ?? true)) {
      return _ElegantErrorWidget(
        error: state.errorMessage!,
        onRetry: _loadTicketData,
      );
    }

    if ((state.dataList?.isEmpty ?? true) && !state.isLoading) {
      return const _ElegantEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _ElegantTicketList(
          tickets: upcomingTickets,
          isLoading: state.isLoading,
          onTicketTap: _showTicketDetails,
        ),
        _ElegantTicketList(
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
      if (a.isPast) return bDate.compareTo(aDate);
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
      builder: (final _) => _LuxuryTicketModal(ticket: ticket),
    );
  }
}

// ============================================================
// ELEGANT TAB BAR - SİYAH ÇİZGİ KALDIRILDI
// ============================================================

class _ElegantTabBar extends StatelessWidget {
  final TabController controller;
  final ThemeData theme;

  const _ElegantTabBar({
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
}

// ============================================================
// ELEGANT LOADING SHIMMER
// ============================================================

class _ElegantLoadingShimmer extends StatelessWidget {
  const _ElegantLoadingShimmer();

  @override
  Widget build(final BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (final context, final index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const ShimmerLoading(
            width: double.infinity,
            height: 180,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ELEGANT ERROR WIDGET
// ============================================================

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
                    theme.colorScheme.errorContainer.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bir Sorun Oluştu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Tekrar Dene',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ELEGANT EMPTY STATE
// ============================================================

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
                    theme.colorScheme.primaryContainer.withOpacity(0.6),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.confirmation_num_outlined,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Biletiniz Yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Satın aldığınız biletler burada görünecek',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
// ELEGANT TICKET LIST
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
    if (tickets.isEmpty && !isLoading) {
      return _ElegantEmptyTab(isPast: isPast);
    }

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
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isPast ? 'Geçmiş bilet bulunmuyor' : 'Yaklaşan bilet bulunmuyor',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LUXURY TICKET CARD - SANATSAL TASARIM
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
    final theme = Theme.of(context);
    final dateInfo = DateFormatter.formatForEventCard(
      detailedTicket.event?.date ?? '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Ana Kart
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dateInfo['day'] ?? '??',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (dateInfo['monthName'] ?? '---').toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          _ElegantInfoRow(
                            icon: Icons.location_on_rounded,
                            text: detailedTicket.stage?.name ??
                                'Sahne Yükleniyor...',
                            theme: theme,
                          ),
                          const SizedBox(height: 6),
                          _ElegantInfoRow(
                            icon: Icons.event_seat_rounded,
                            text: detailedTicket.ticket.buySeats.join(", "),
                            theme: theme,
                            isHighlighted: true,
                          ),
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
            child: _ParticleDecoration(isPast: isPast, theme: theme),
          ),
        ],
      ),
    );
  }
}

// PARTİKÜL DECORATION WIDGET'ı
class _ParticleDecoration extends StatefulWidget {
  final bool isPast;
  final ThemeData theme;

  const _ParticleDecoration({required this.isPast, required this.theme});

  @override
  State<_ParticleDecoration> createState() => _ParticleDecorationState();
}

class _ParticleDecorationState extends State<_ParticleDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Partikülleri oluştur
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (final context, final child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isPast
                  ? [Colors.grey.shade400, Colors.grey.shade600]
                  : [
                      widget.theme.colorScheme.primary,
                      widget.theme.colorScheme.primaryContainer,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPast
                    ? Colors.grey.withOpacity(0.5)
                    : widget.theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Partiküller
              ..._particles.map((final particle) {
                final angle = particle.angle + _controller.value * 2 * pi;
                final distance = 12 + particle.distance * _controller.value * 8;
                final x = distance * cos(angle);
                final y = distance * sin(angle);

                return Positioned(
                  left: 20 + x,
                  top: 20 + y,
                  child: Container(
                    width: particle.size,
                    height: particle.size,
                    decoration: BoxDecoration(
                      color: widget.isPast
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),

              // Merkez icon
              Center(
                child: Icon(
                  widget.isPast
                      ? Icons.history_rounded
                      : Icons.celebration_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle = Random().nextDouble() * 2 * pi;
  final double distance = Random().nextDouble();
  final double size = 2 + Random().nextDouble() * 3;
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
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LUXURY TICKET MODAL - BÜYÜK VE ŞIK
// ============================================================
// ============================================================
// LUXURY TICKET MODAL - TAM KOD
// ============================================================
// ============================================================
// LUXURY TICKET MODAL - GÜNCELLENMİŞ
// ============================================================

class _LuxuryTicketModal extends StatelessWidget {
  final DetailedTicket ticket;

  const _LuxuryTicketModal({required this.ticket});

  @override
  Widget build(final BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (final context, final scrollController) {
        return _LuxuryTicketDetails(
          controller: scrollController,
          ticket: ticket,
        );
      },
    );
  }
}

class _LuxuryTicketDetails extends StatelessWidget {
  final ScrollController controller;
  final DetailedTicket ticket;

  const _LuxuryTicketDetails({
    required this.controller,
    required this.ticket,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final dateInfo = DateFormatter.formatForEventCard(ticket.event?.date ?? '');
    final eventYear = DateFormatter.parseDateString(ticket.event?.date)?.year ??
        DateTime.now().year;
    final dateText = "${dateInfo['day']} ${dateInfo['monthName']} $eventYear";
    final timeText = dateInfo['time'] ?? '--:--';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Expanded(
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                // Event Image - FULL WIDTH
                _LargeEventImage(
                  imageUrl: ticket.show?.imageUrl ?? '',
                  title: ticket.show?.name ?? 'Gösteri Adı',
                  theme: theme,
                ),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // QR Code Section
                      _LargeQRCodeSection(
                        ticketId: ticket.ticket.id,
                        theme: theme,
                      ),
                      const SizedBox(height: 32),

                      // Ticket Details - ALT ALTA
                      _DetailsSection(
                        ticket: ticket,
                        dateText: dateText,
                        timeText: timeText,
                        theme: theme,
                      ),
                      const SizedBox(height: 40),
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

class _LargeEventImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final ThemeData theme;

  const _LargeEventImage({
    required this.imageUrl,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 240,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image - FULL WIDTH
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceVariant,
                    theme.colorScheme.surfaceContainer,
                  ],
                ),
              ),
            ),
            errorWidget: (final context, final url, final error) => Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceVariant,
                    theme.colorScheme.surfaceContainer,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Görsel yüklenemedi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // BAŞLIK - ALT SOL KÖŞE
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal içindeki QR kod bölümü.
class _LargeQRCodeSection extends StatelessWidget {
  final String ticketId;
  final ThemeData theme;

  const _LargeQRCodeSection({
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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Text(
              'Bilet QR Kodu',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          // GÜNCELLENDİ: Padding 24'ten 20'ye düşürüldü
          padding: const EdgeInsets.all(20),
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
                  // QR Kod
                  Container(
                    padding: const EdgeInsets.all(15),
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
                      size: 100,
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
                  const SizedBox(width: 20),

                  // QR Kod bilgisi
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
// ============================================================
// DETAILS SECTION (YENİ TASARIM: DİKEY LİSTE)
// ============================================================

/// Modal içindeki bilet detaylarını (koltuk, sahne, tarih vb.)
/// tek bir çerçeve içinde dikey bir liste olarak gösterir.
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
        // Başlık
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bilet Bilgileri',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // QR Kod stiline sahip yeni liste çerçevesi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainer.withOpacity(0.8),
                theme.colorScheme.surfaceContainer.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _InfoListTile(
                icon: Icons.event_seat_rounded,
                title: 'Koltuk Numaraları',
                subtitle: ticket.ticket.buySeats.join(", "),
                theme: theme,
                isHighlighted: true,
              ),
              const _CustomDivider(),
              _InfoListTile(
                icon: Icons.location_on_rounded,
                title: 'Sahne',
                subtitle: ticket.stage?.name ?? 'Yükleniyor...',
                theme: theme,
              ),
              const _CustomDivider(),
              _InfoListTile(
                icon: Icons.calendar_month_rounded,
                title: 'Tarih',
                subtitle: dateText,
                theme: theme,
              ),
              const _CustomDivider(),
              _InfoListTile(
                icon: Icons.access_time_filled_rounded,
                title: 'Saat',
                subtitle: timeText,
                theme: theme,
              ),
              const _CustomDivider(),
              _InfoListTile(
                icon: Icons.payments_rounded,
                title: 'Ödenen Tutar',
                subtitle: '${ticket.ticket.orderPrice} TL',
                theme: theme,
                isHighlighted: true,
              ),
              const _CustomDivider(),
              _InfoListTile(
                icon: Icons.credit_card_rounded,
                title: 'Ödeme Yöntemi',
                subtitle: ticket.ticket.orderMethod,
                theme: theme,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Çerçeve içindeki listede kullanılacak ayırıcı (divider) widget'ı.
class _CustomDivider extends StatelessWidget {
  const _CustomDivider();

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
    );
  }
}

/// Dikey liste içindeki her bir yatay bilgi satırı.
class _InfoListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final bool isHighlighted;
  final bool isLast;

  const _InfoListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.isHighlighted = false,
    this.isLast = false,
  });

  @override
  Widget build(final BuildContext context) {
    // İkonun "arka plan" rengini belirler
    final iconBackgroundColor =
        isHighlighted ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    // Alt başlığın (değerin) rengini belirler
    final subtitleColor =
        isHighlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // İkon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Arka plan rengi koşulludur
            color: iconBackgroundColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            // İkonun "kendisi" her zaman 'primary' rengindedir
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Başlık ve Alt Başlık
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: subtitleColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
