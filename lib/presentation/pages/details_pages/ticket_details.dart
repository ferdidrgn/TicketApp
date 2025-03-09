import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/model/ticket_model.dart';

class TicketDetailPage extends StatelessWidget {
  final Ticket? ticket;

  const TicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.id??''),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Art related quote
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '“Sanat, ruhun yemek için yediği havadır.” — John A. Diamond',
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Ticket details
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Başlık: ${ticket?.id??''}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text('Tarih: ${ticket?.id??''}', style: const TextStyle(fontSize: 18)),
                    Text('Saat: ${ticket?.id??''}', style: const TextStyle(fontSize: 18)),
                    Text('Lokasyon: ${ticket?.id??''}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    Center(
                      child: QrImageView(
                        data:ticket?.id??'',
                        size: 130,
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Additional ticket details
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sahne Yeri: Örnek Sahne',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sahne Konumu: Şehir Merkezi, Cadde No:1',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Nasıl Gidilir: [Harita bağlantısı]',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Fiyat: 150₺',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Yaş Sınırı: 12 yaş ve üstü',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Etkinlik Kuralları: [Kurallar detaylı olarak buraya gelecek]',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Alınan Koltuk/kişi Adetleri: [Koltuk numaraları ve isimler]',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
