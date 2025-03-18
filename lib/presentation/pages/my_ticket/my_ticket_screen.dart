import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/custom_art_words_card.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/data/providers/ticket/ticket_provider.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../data/datasources/ticket/ticket_remote_data_source_and_impl.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/show.dart';
import '../../../domain/entities/stage.dart';
import '../../../domain/entities/ticket.dart';
import '../details_pages/ticket_details.dart';

class MyTicketPage extends ConsumerStatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  _MyTicketPageState createState() => _MyTicketPageState();
}

class _MyTicketPageState extends ConsumerState<MyTicketPage> {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini yükle
    ref.read(userProvider.notifier).loadUserById(widget.userId);
  }

  Future<List<Ticket?>> _fetchTickets(final List<String?> userTicketsId) async {
    if (userTicketsId.isEmpty) return [];

    final ticketService = TicketRemoteDataSourceImpl(firestore: firestore);

     final tickets = await Future.wait(
       userTicketsId.map((final id) => ticketService.getTicketById(id!)),
    );

    final ticketsWithDetails = await Future.wait(
      tickets.where((final t) => t != null).map((final ticket) async {
        final eventDate = await EventService().getEventDate(ticket!.eventId);
        final data = eventDate?.entries
            .map((final entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        final isPast =
            data != null && DateTime.parse(data).isBefore(DateTime.now());
        return ticket.copyWith(isPast: isPast);
      }),
    );

    return ticketsWithDetails;
  }

  Future _fetchPurchasedSeat(final String eventId) async {
    final fetchPurchasedSeats = await EventService()
        .getPurchasedSeatsByCustomerId(eventId, widget.userId);
    setState(() {
      purchasedSeats = fetchPurchasedSeats;
    });
  }

    @override
    Widget build(final BuildContext context) {
      // Kullanıcı bilgisini dinle
      final userState = ref.watch(userProvider);

      if (userState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (userState.error != null) {
        return Center(child: Text('Hata: ${userState.error}'));
      }

      final user = userState.user;
      if (user == null || user.ticketsId == null) {
        return const Center(child: Text('Henüz biletiniz yok.'));
      }

      // Biletleri yüklemek için FutureProvider kullan
      final ticketsAsyncValue = ref
          .watch(ticketProvider.notifier)
          .loadTicketById(user.ticketsId!);

      return Scaffold(
        appBar: AppBar(title: const Text('Biletlerim')),
        body: ticketsAsyncValue.when(
          data: (final tickets) {
            final upcomingTickets = tickets
                .where((final ticket) => !ticket!.isPast)
                .toList();
            final pastTickets = tickets
                .where((final ticket) => ticket!.isPast)
                .toList();

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
                      _buildTicketList(upcomingTickets),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => Center(child: Text('Hata: $error')),
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
            final ticket = tickets[index]!;
            return _buildTicketCard(ticket);
          },
        ),
      );
    }

    Widget _buildTicketCard(final Ticket ticket) {
      final eventFuture = ref.watch(eventProvider(ticket.eventId));
      final showFuture = ref.watch(showProvider(ticket.showId));
      final stageFuture = ref.watch(stageProvider(ticket.stageId));

      return FutureBuilder<List<dynamic>>(
        future: Future.wait([eventFuture, showFuture, stageFuture]),
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

          final event = snapshot.data![0] as Event?;
          final show = snapshot.data![1] as Show?;
          final stage = snapshot.data![2] as Stage?;

          return GestureDetector(
            onTap: () =>
                Navigator.push(
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
                        ticket.isPast ? Icons.history : Icons.event,
                        color: ticket.isPast ? Colors.grey : Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        show?.name ?? 'Başlık Yok',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('Tarih: ${event?.date ?? 'Belirtilmemiş'}',
                          style: const TextStyle(fontSize: 14)),
                      Text('Saat: ${event?.date ?? 'Belirtilmemiş'}',
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
