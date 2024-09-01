import 'package:flutter/material.dart';
import '../details_pages/ticket_details.dart';

class Ticket {
  final String title;
  final String date;
  final String time;
  final String location;
  final bool isPast;

  Ticket({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    this.isPast = false,
  });
}

class MyTicketPage extends StatelessWidget {
  // Örnek bilet verileri
  final List<Ticket> tickets = [
    Ticket(
      title: 'Konser Bileti',
      date: '2024-09-15',
      time: '20:00',
      location: 'Stadyum A',
      isPast: false,
    ),
    Ticket(
      title: 'Sergi Girişi',
      date: '2024-08-20',
      time: '15:00',
      location: 'Sanat Galerisi B',
      isPast: true,
    ),
    Ticket(
      title: 'Stand Up Gösterisi',
      date: '2024-10-01',
      time: '21:00',
      location: 'Küçük Tiyatro',
      isPast: false,
    ),
    Ticket(
      title: 'Müzik Festivali',
      date: '2024-07-10',
      time: '14:00',
      location: 'Park Alanı C',
      isPast: true,
    ),
    Ticket(
      title: 'Sinemaya Giriş',
      date: '2024-09-25',
      time: '18:00',
      location: 'Sinema Salon X',
      isPast: false,
    ),
    Ticket(
      title: 'Çocuk Tiyatrosu',
      date: '2024-08-30',
      time: '11:00',
      location: 'Tiyatro E',
      isPast: false,
    ),
    Ticket(
      title: 'Festival Bileti',
      date: '2024-06-15',
      time: '12:00',
      location: 'Festival Alanı Y',
      isPast: true,
    ),
    Ticket(
      title: 'Tiyatro Bileti',
      date: '2024-09-05',
      time: '19:00',
      location: 'Büyük Tiyatro',
      isPast: false,
    ),
    Ticket(
      title: 'Konferans Bileti',
      date: '2024-11-20',
      time: '09:00',
      location: 'Konferans Merkezi',
      isPast: false,
    ),
    Ticket(
      title: 'Dans Gösterisi',
      date: '2024-10-15',
      time: '20:00',
      location: 'Dans Salonu',
      isPast: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pastTickets = tickets.where((ticket) => ticket.isPast).toList();
    final upcomingTickets = tickets.where((ticket) => !ticket.isPast).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biletlerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuoteSection(),
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

  Widget _buildQuoteSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“Sanat, ruhun en derin yerlerine dokunan bir dil konuşur.”',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '- Pablo Picasso',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
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

  Widget _buildTicketList(List<Ticket> tickets, BuildContext context) {
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
                        ticket.isPast ? Icons.history : Icons.event,
                        color: ticket.isPast ? Colors.grey : Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tarih: ${ticket.date}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Saat: ${ticket.time}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Lokasyon: ${ticket.location}',
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
