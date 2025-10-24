import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/custom_art_words_card.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../../data/datasources/event/event_remote_data_source_and_impl.dart';
import '../../../../data/datasources/ticket/ticket_remote_data_source_and_impl.dart';
import '../../../../domain/entities/stage.dart';
import '../../../../domain/entities/ticket.dart';
import '../details_pages/ticket_details.dart';

class MyTicketPage extends ConsumerStatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  _MyTicketPageState createState() => _MyTicketPageState();
}

class _MyTicketPageState extends ConsumerState<MyTicketPage> {
  final firestore = FirebaseFirestore.instance;
  late final EventRemoteDataSourceImpl eventService;
  late Future<List<Ticket?>> tickets;
  late List<String?>? purchasedSeats = [];

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini yükle
    ref.read(userProvider.notifier).loadUserById(widget.userId);
    eventService = EventRemoteDataSourceImpl(firestore: firestore);
    tickets = _fetchTickets(); // Biletleri başlangıçta yükle
  }

  Future<List<Ticket?>> _fetchTickets() async {
    final userTicketsId = ref.read(userProvider).dataSingle?.ticketsId ?? [];
    if (userTicketsId.isEmpty) return [];

    final ticketService = TicketRemoteDataSourceImpl(firestore: firestore);

    final filteredTickets = userTicketsId.whereType<String>().toList();
    final tickets = await ticketService.getTicketsByIds(filteredTickets);

    return [];
    // Biletleri detaylarıyla birlikte al
    /*return Future.wait(
      tickets!.where((final t) => t != null).map((final ticket) async {
        final eventDate = await eventService.getEventDate(ticket!.eventId??"");
        final dateString = eventDate?.entries
            .map((final entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        final isPast = dateString != null &&
            DateTime.parse(dateString).isBefore(DateTime.now());
        return ticket.toEntity().copyWith(isPast: isPast);
      }),
    );*/
  }

  /*Future _fetchPurchasedSeat(final String eventId) async {
    final fetchPurchasedSeats = await eventService.getPurchasedSeatsByCustomerId(eventId, widget.userId);
    setState(() {
      purchasedSeats = fetchPurchasedSeats;
    });
  }*/

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biletlerim')),
      body: FutureBuilder<List<Ticket?>>(
        future: tickets,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz biletiniz yok.'));
          }

          final tickets = snapshot.data!;
          final upcomingTickets =
              tickets.where((final t) => !t!.isPast.toString().contains('true'));
          final pastTickets = tickets.where((final t) => t!.isPast.toString() == 'true').toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomArtWordsCard(
                    word: 'Sanat Sanat İçin midir',
                    author: 'Pablo Picasso',
                  ),
                  const SizedBox(height: 20),
                  if (upcomingTickets.isNotEmpty) ...[
                    const CustomSectionTitle(title: 'Gelecek Biletler'),
                    _buildTicketList(upcomingTickets.isNotEmpty
                        ? upcomingTickets as List<Ticket?>
                        : []),
                    const SizedBox(height: 20),
                  ],
                  if (pastTickets.isNotEmpty) ...[
                    const CustomSectionTitle(title: 'Geçmiş Biletler'),
                    _buildTicketList(pastTickets),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketList(final List<Ticket?> tickets) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tickets.length,
        itemBuilder: (final context, final index) {
          return _buildTicketCard(tickets[index]!);
        },
      ),
    );
  }

  Widget _buildTicketCard(final Ticket ticket) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        eventService.getEventDate(ticket.eventId),
        //eventService.getEventPrice(ticket.eventId),
        //eventService.getStageId(ticket.stageId),
      ]),
      builder: (final context, final snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Hata: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Text('Veri yok');
        }

        final eventDates = snapshot.data![0] as Map<String, String>?;
        final eventPrice = snapshot.data![1] as String?;
        final date = eventDates?.entries
                .map((final entry) => '${entry.key}: ${entry.value}')
                .join(', ') ??
            '';
        final stage = snapshot.data![2] as Stage?;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) => TicketDetailPage(ticket: ticket)),
          ),
          child: Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (ticket.isPast) ? Icons.history : Icons.event,
                      color:
                          (ticket.isPast) ? Colors.grey : Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etkinlik: ${ticket.eventId}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('Tarih: $date', style: const TextStyle(fontSize: 14)),
                    Text('Fiyat: ${eventPrice ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Lokasyon: ${stage?.address ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
