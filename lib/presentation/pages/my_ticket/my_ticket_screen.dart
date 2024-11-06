import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_title.dart';
import 'package:ticketapp/data/repository/ticket_service.dart';
import 'package:ticketapp/data/repository/user_service.dart';
import '../../../core/custom_views/custom_art_words_card.dart';
import '../../../data/model/event.dart';
import '../../../data/model/show.dart';
import '../../../data/model/stage.dart';
import '../../../data/model/ticket.dart';
import '../../../data/repository/event_service.dart';
import '../../../data/repository/show_service.dart';
import '../../../data/repository/stage_service.dart';
import '../details_pages/ticket_details.dart';

class MyTicketPage extends StatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  _MyTicketPageState createState() => _MyTicketPageState();
}

class _MyTicketPageState extends State<MyTicketPage> {
  late Future<List<Ticket?>> _ticketsFuture;
  late List<String> purchasedSeats = [];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  Future<List<Ticket?>> _fetchTickets() async {
    final user = await UserService().getUserById(widget.userId);
    if (user == null || user.ticketsId == null) {
      return [];
    }

    final tickets = await Future.wait(
      user.ticketsId!.map((id) => TicketService().getTicketById(id)),
    );

    final ticketsWithDetails = await Future.wait(
      tickets.where((t) => t != null).map((ticket) async {
        final eventDate = await EventService().getEventDate(ticket!.eventId);
        final data = eventDate?.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        final isPast =
            data != null && DateTime.parse(data).isBefore(DateTime.now());
        return ticket.copyWith(isPast: isPast);
      }),
    );

    return ticketsWithDetails;
  }

  Future _fetchPurchasedSeat(String eventId) async {
    final fetchPurchasedSeats = await EventService()
        .getPurchasedSeatsByCustomerId(eventId, widget.userId);
    setState(() {
      purchasedSeats = fetchPurchasedSeats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biletlerim')),
      body: FutureBuilder<List<Ticket?>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz biletiniz yok.'));
          }

          final tickets = snapshot.data!;
          final upcomingTickets =
              tickets.where((t) => t?.isPast == false).toList();
          final pastTickets = tickets.where((t) => t?.isPast == true).toList();

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
      ),
    );
  }

  Widget _buildTicketList(List<Ticket?> tickets) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final eventId = tickets[index]?.eventId;
          _fetchPurchasedSeat(eventId ?? '');
          _buildTicketCard(tickets[index]!);
        },
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        EventService().getEventDate(ticket.eventId),
        EventService().getEventPrice(ticket.eventId),
        ShowService().getShowById(ticket.showId),
        StageService().getStageById(ticket.stageId),
      ]),
      builder: (context, snapshot) {
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
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        final event = Event(
            id: '', stageId: '', date: date ?? '', price: eventPrice ?? '');
        final show = snapshot.data![2] as Show?;
        final stage = snapshot.data![3] as Stage?;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TicketDetailPage(ticket: ticket)),
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
