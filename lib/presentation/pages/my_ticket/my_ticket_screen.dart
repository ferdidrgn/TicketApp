import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_title.dart';
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
  List<Ticket?> upcomingTickets = [];
  List<Ticket?> pastTickets = [];
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
        await _fetchTicketsData(userData.ticketsId);
      }
    } catch (e) {
      throw Exception("Kullanıcı bilgilerinde bir hata oluştu.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTicketsData(List<String>? ticketsId) async {
    try {
      if (ticketsId != null) {
        for (String ticketId in ticketsId) {
          final ticket = await TicketService().getTicketById(ticketId);
          if (ticket != null) {
            final event = await _fetchEventData(ticket.eventId);
            if (event != null) {
              final eventDate = DateTime.parse(event.date);
              final isPast = eventDate.isBefore(DateTime.now());

              final updatedTicket = ticket.copyWith(isPast: isPast);

              setState(() {
                ticketDataList.add(ticket);
                if (isPast) {
                  pastTickets.add(updatedTicket);
                } else {
                  upcomingTickets.add(updatedTicket);
                }
              });
            }
          }
        }
      }
    } catch (e) {
      throw Exception("Bilet bilgilerinde bir hata oluştu.");
    }
  }

  Future<Event?> _fetchEventData(String eventId) async {
    try {
      final EventService eventService = EventService();
      final eventDate = await eventService.getEventDate(eventId);
      final data = eventDate?.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
      final String eventPrice = await eventService.getEventPrice(eventId) ?? '';
      return Event(id: '', stageId: '', date: data ?? '', price: eventPrice);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Etkinlik verisi alınırken bir hata oluştu: $error')));
      return null;
    } finally {
      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
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
              const CustomSectionTitle(title: 'Gelecek Biletler'),
              _buildTicketList(upcomingTickets, context),
              const SizedBox(height: 20),
            ],
            if (pastTickets.isNotEmpty) ...[
              const CustomSectionTitle(title: 'Geçmiş Biletler'),
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
