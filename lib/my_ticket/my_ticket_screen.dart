import 'package:flutter/material.dart';

class Ticket {
  final String title;
  final String date;
  final String time;
  final String location;
  final bool isPast; // Belirtilen bilet geçmiş mi?

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
    // Daha fazla bilet ekleyebilirsiniz
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
        child: ListView(
          children: [
            if (upcomingTickets.isNotEmpty) ...[
              _buildSectionTitle('Gelecek Biletler'),
              ...upcomingTickets.map((ticket) => _buildTicketCard(ticket)),
              const SizedBox(height: 20),
            ],
            if (pastTickets.isNotEmpty) ...[
              _buildSectionTitle('Geçmiş Biletler'),
              ...pastTickets.map((ticket) => _buildTicketCard(ticket)),
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

  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(ticket.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarih: ${ticket.date}', style: const TextStyle(fontSize: 16)),
            Text('Saat: ${ticket.time}', style: const TextStyle(fontSize: 16)),
            Text('Lokasyon: ${ticket.location}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        trailing: ticket.isPast
            ? const Icon(Icons.history, color: Colors.grey)
            : const Icon(Icons.event, color: Colors.green),
      ),
    );
  }
}
