import 'package:flutter/material.dart';
import 'package:ticketapp/data/repository/ticket_service.dart';
import 'package:ticketapp/data/repository/user_service.dart';
import '../../../core/custom_views/custom_art_words_card.dart';
import '../../../data/model/event.dart';
import '../../../data/model/show.dart';
import '../../../data/model/stage.dart';
import '../../../data/model/ticket.dart';
import '../../../data/model/user.dart';
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
  late final User userData;
  List<Ticket?> ticketDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userInfo = await UserService().getUserById(widget.userId);
      if (userInfo != null) {
        setState(() {
          userData = userInfo;
        });
        _fetchTicketsData(userData.ticketsId);
      }
    } catch (e) {
      throw Exception("Kullanıcı bilgilerinde bir hata oluştu.");
    }
  }

  Future<void> _fetchTicketsData(List<String>? ticketsId) async {
    try {
      if (ticketsId != null) {
        for (String ticketId in ticketsId) {
          final ticket = await TicketService().getTicketById(ticketId);
          if (ticket != null) {
            setState(() {
              ticketDataList.add(ticket);
            });
          }
        }
      }
    } catch (e) {
      throw Exception("Bilet bilgilerinde bir hata oluştu.");
    }
  }

  Future<Show?> _fetchShowData(String showId) async {
    try {
      final show = await ShowService().getShowById(showId);
      return show;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınırken bir hata oluştu: $error')));
      return null;
    } finally {
      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  Future<Stage?> _fetchStageData(String stageId) async {
    try {
      final stage = await StageService().getStageById(stageId);
      return stage;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sahne verisi alınırken bir hata oluştu: $error')));
      return null;
    }
  }

  Future<Event?> _fetchEventData(String eventId, String stageId) async {
    try {
      final eventService = EventService();
      await eventService.initializeAndGetEventSeats(eventId, stageId);
      final event = eventService.getEvent();
      return event;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sahne verisi alınırken bir hata oluştu: $error')));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biletlerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomArtWordsCard(
                word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
            const SizedBox(height: 20),
            if (upcomingTickets.isNotEmpty) ...[
              _buildSectionTitle('Gelecek Biletler'),
              _buildTicketList(upcomingTickets, context),
              const SizedBox(height: 20),
            ],
            if (pastTickets.isNotEmpty) ...[
              _buildSectionTitle('Geçmiş Biletler'),
              _buildTicketList(pastTickets, context),
            ],
            if (pastTickets.isEmpty && upcomingTickets.isEmpty) ...[
              const Center(
                child: Text('Henüz biletiniz yok.'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTicketList(List<Ticket?> tickets, BuildContext context) {
    return SizedBox(
      height: 200, // Kartların yüksekliği
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDetailPage(ticket: ticket),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        ticket?.isPast == true ? Icons.history : Icons.event,
                        color:
                            ticket?.isPast == true ? Colors.grey : Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket?.title ?? 'Başlık Yok',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tarih: ${ticket?.date ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Saat: ${ticket?.time ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Lokasyon: ${ticket?.location ?? 'Belirtilmemiş'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
