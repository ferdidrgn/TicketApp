import 'package:flutter/material.dart';
import '../../../data/repository/seat_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String stageId;
  final String eventId;

  const SeatSelectionScreen({super.key, required this.stageId, required this.eventId});

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<String, List<String>> seats = {};
  Map<String, String> seatStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchSeats();
  }

  // Koltuk ve doluluk durumlarını Firestore'dan çekme
  Future<void> _fetchSeats() async {
    Map<String, List<String>> fetchedSeats = await SeatService().getSeatsByStage(widget.stageId);
    Map<String, String> fetchedSeatStatus = await SeatService().getSeatStatusByEvent(widget.eventId);

    setState(() {
      seats = fetchedSeats;
      seatStatus = fetchedSeatStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koltuk Seçimi'),
      ),
      body: seats.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Veri yüklenirken loading göstergesi
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: seats.keys.map((row) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sıra başlığını göster
                  Text(
                    'Row $row',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sıra içerisindeki koltukları yatay olarak göster
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Ortala
                    children: seats[row]!.map((seatId) {
                      String status = seatStatus[seatId] ?? 'available';
                      bool isAvailable = status == 'available';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: isAvailable ? () => print('Selected: $seatId') : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                seatId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16), // Her sıradan sonra boşluk
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}