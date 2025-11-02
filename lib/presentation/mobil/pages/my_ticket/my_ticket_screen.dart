import 'dart:async'; // unawaited için
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

class MyTicketPage extends ConsumerStatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  ConsumerState<MyTicketPage> createState() => _MyTicketPageState();
}

class _MyTicketPageState extends ConsumerState<MyTicketPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

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

  /// 1. Adım: Biletleri ve tüm detaylarını 'customerId' (userId) kullanarak yükle
  Future<void> _loadTicketData() async {
    final currentState = ref.read(ticketProvider);
    // Eğer biletler zaten yükleniyorsa tekrar tetikleme
    if (currentState.isLoading) return;

    await ref
        .read(ticketProvider.notifier)
        .loadTicketsAndDetailsByCustomerId(widget.userId);
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    final ticketState = ref.watch(ticketProvider);

    // VERİ BİRLEŞTİRME (AGGREGATION). Verileri artık ticketState'in içinden al
    final List<Ticket> userTickets = ticketState.dataList ?? [];

    // Hızlı erişim için Map'leri TICKET STATE'den oluştur
    final showMap = {for (final s in ticketState.relatedShows ?? []) s.id: s};
    final eventMap = {for (final e in ticketState.relatedEvents ?? []) e.id: e};
    final stageMap = {for (final s in ticketState.relatedStages ?? []) s.id: s};

    final List<DetailedTicket> detailedTickets = [];
    final now = DateTime.now();

    for (final ticket in userTickets) {
      final event = eventMap[ticket.eventId];
      final eventDate = DateFormatter.parseDateString(event?.date);
      final bool isPast = eventDate != null ? eventDate.isBefore(now) : false;

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

    // Biletleri 'gelecek' ve 'geçmiş' olarak ayır
    final upcomingTickets =
        detailedTickets.where((final t) => !t.isPast).toList();
    final pastTickets = detailedTickets.where((final t) => t.isPast).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biletlerim'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // Arka plan rengini tema yüzey renginden biraz farklı yapalım
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              // Aktif indicator'ın şekli
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'AKTİF BİLETLER'),
                Tab(text: 'GEÇMİŞ BİLETLER'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTicketData,
        child: Builder(
          builder: (final context) {
            // Yükleniyorsa
            // (relatedShows == null kontrolü, detayların yüklendiğinden emin olmak için)
            if (ticketState.isLoading && ticketState.relatedShows == null) {
              return _buildLoadingShimmer();
            }
            // Hata varsa
            if (ticketState.errorMessage != null && userTickets.isEmpty) {
              return _buildErrorWidget(ticketState.errorMessage!);
            }
            // Bilet yoksa
            if (userTickets.isEmpty && !ticketState.isLoading) {
              return _buildEmptyWidget();
            }
            // Veri varsa
            return TabBarView(
              controller: _tabController,
              children: [
                _buildTicketListView(upcomingTickets),
                _buildTicketListView(pastTickets, isPast: true),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Yükleniyor durumunda gösterilecek Shimmer widget'ı
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (final context, final index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ShimmerLoading(width: double.infinity, height: 120),
      ),
    );
  }

  /// Hata durumunda gösterilecek widget
  Widget _buildErrorWidget(final String error) {
    return SingleChildScrollView(
      // Hata mesajı da kaydırılabilir olmalı
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 60, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Bir Hata Oluştu',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Hata: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar Dene"),
              onPressed: _loadTicketData,
            )
          ],
        ),
      ),
    );
  }

  /// Boş liste durumunda gösterilecek widget
  Widget _buildEmptyWidget() {
    return SingleChildScrollView(
      // Yenileme (pull-to-refresh) için bu da kaydırılabilir olmalı
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height:
            MediaQuery.of(context).size.height * 0.7, // Ekranı kaplaması için
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_activity_outlined,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Bilet Bulunamadı',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Henüz satın alınmış bir biletiniz bulunmamaktadır.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bilet listesini (dikey) oluşturan widget
  Widget _buildTicketListView(final List<DetailedTicket> tickets,
      {final bool isPast = false}) {
    if (tickets.isEmpty && !ref.read(ticketProvider).isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            isPast
                ? 'Geçmiş bilet bulunmamaktadır.'
                : 'Aktif bilet bulunmamaktadır.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tickets.length,
      itemBuilder: (final context, final index) {
        return _ModernTicketCard(
          detailedTicket: tickets[index],
          isPast: isPast,
          onTap: () => _showTicketDetailsModal(context, tickets[index]),
        );
      },
    );
  }

  /// Bilet detaylarını gösteren modern, kaydırılabilir modal pop-up
  void _showTicketDetailsModal(
      final BuildContext context, final DetailedTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // true olmalı
      backgroundColor: Colors.transparent, // Arka planı transparan yap
      builder: (final _) {
        // Yüksekliğin ekranın %90'ını kaplamasını sağlar
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (final _, final scrollController) {
            return _TicketDetailsModalContent(
              controller: scrollController,
              ticket: ticket,
            );
          },
        );
      },
    );
  }
}

/// Bilet listesi için modern kart tasarımı
class _ModernTicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _ModernTicketCard({
    required this.detailedTicket,
    required this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Map<String, String> formattedDate =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');

    final String dayText = formattedDate['day'] ?? '?';
    final String monthText = formattedDate['monthName'] ?? '---';
    final String timeText = formattedDate['time'] ?? '--:--';

    // Verilerin yüklenip yüklenmediğini kontrol et
    final String showName =
        detailedTicket.show?.name ?? 'Gösteri Yükleniyor...';
    final String stageName =
        detailedTicket.stage?.name ?? 'Sahne Yükleniyor...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isPast ? theme.cardColor.withOpacity(0.5) : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPast
                ? []
                : [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // 1. Tarih Bölümü
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.shade400
                      : colorScheme.primary.withOpacity(0.8),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      monthText.toUpperCase(),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Colors.white70, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              // 2. Bilet Detay Bölümü
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        showName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration:
                              isPast ? TextDecoration.lineThrough : null,
                          color: isPast ? Colors.grey.shade600 : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      _buildInfoRow(
                          context, Icons.location_on_outlined, stageName,
                          isPast: isPast),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                          context,
                          Icons.airline_seat_recline_normal_outlined,
                          'Koltuk: ${detailedTicket.ticket.buySeats.join(", ")}',
                          isPast: isPast),
                    ],
                  ),
                ),
              ),
              // 3. İkon Bölümü
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPast
                      ? Colors.grey.shade400
                      : colorScheme.primary.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      final BuildContext context, final IconData icon, final String text,
      {final bool isPast = false}) {
    final theme = Theme.of(context);
    final color =
        isPast ? Colors.grey.shade500 : theme.textTheme.bodySmall?.color;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TicketDetailsModalContent extends StatelessWidget {
  final ScrollController controller;
  final DetailedTicket ticket;

  const _TicketDetailsModalContent({
    required this.controller,
    required this.ticket,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Map<String, String> formattedDate =
        DateFormatter.formatForEventCard(ticket.event?.date ?? '');

    final String dateText =
        "${formattedDate['day']} ${formattedDate['monthName']} ${DateTime.now().year}";
    final String timeText = formattedDate['time'] ?? '--:--';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Üst Kısım (Resim ve Başlık)
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Arka plan resim
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: ticket.show?.imageUrl ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (final context, final url) =>
                      const ShimmerLoading(height: 200),
                  errorWidget: (final context, final url, final error) =>
                      Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
              // Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // Başlık
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  ticket.show?.name ?? 'Gösteri Adı',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. QR Kod Bölümü
          Text('Bilet Kodu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white, // QR kodun arka planı hep beyaz olmalı
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: ticket.ticket.id,
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bu kodu girişte gösterin',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bilet ID: ${ticket.ticket.id}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Detaylar Bölümü
          Text('Detaylar', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildDetailTile(
            theme,
            icon: Icons.airline_seat_recline_normal_outlined,
            title: 'Koltuklar',
            subtitle: ticket.ticket.buySeats.join(", "),
            color: colorScheme.primary,
          ),
          _buildDetailTile(
            theme,
            icon: Icons.location_on_outlined,
            title: 'Sahne',
            subtitle: ticket.stage?.name ?? '...',
          ),
          _buildDetailTile(
            theme,
            icon: Icons.calendar_today_outlined,
            title: 'Tarih',
            subtitle: dateText,
          ),
          _buildDetailTile(
            theme,
            icon: Icons.access_time_outlined,
            title: 'Saat',
            subtitle: timeText,
          ),
          _buildDetailTile(
            theme,
            icon: Icons.payment_outlined,
            title: 'Ödeme',
            subtitle:
                '${ticket.ticket.orderPrice} TL (${ticket.ticket.orderMethod})',
          ),
          _buildDetailTile(
            theme,
            icon: Icons.person_outline,
            title: 'Müşteri ID',
            subtitle: ticket.ticket.customerId,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    final ThemeData theme, {
    required final IconData icon,
    required final String title,
    required final String subtitle,
    final Color? color,
  }) {
    final bool isHeavy = color != null;
    final tileColor = isHeavy ? color!.withOpacity(0.1) : theme.cardColor;
    final iconColor = isHeavy ? color : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isHeavy ? FontWeight.bold : FontWeight.normal,
                    color: isHeavy ? color : theme.colorScheme.onSurface,
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
