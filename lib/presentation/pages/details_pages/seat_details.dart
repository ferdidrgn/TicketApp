import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repository/seat_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String stageId;
  final String eventId;

  const SeatSelectionScreen({
    super.key,
    required this.stageId,
    required this.eventId,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<String, List<String>> seats = {};
  Map<String, String> seatStatus = {};
  Set<String> selectedSeats = {};
  Timer? reservationTimer;
  int remainingTime = 600; // 10 dakika = 600 saniye

  @override
  void initState() {
    super.initState();
    _fetchSeats();
    _startReservationTimer();
  }

  @override
  void dispose() {
    reservationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSeats() async {
    Map<String, List<String>> fetchedSeats =
        await SeatService().getSeatsByStage(widget.stageId);
    Map<String, String> fetchedSeatStatus =
        await SeatService().getSeatStatusByEvent(widget.eventId);

    setState(() {
      seats = fetchedSeats;
      seatStatus = fetchedSeatStatus;
    });
  }

  void _startReservationTimer() {
    reservationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _showTimeUpDialog();
          timer.cancel();
          _cancelReservations();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İşlem Süresi Doldu'),
          content: const Text('Oyun bilgilerine yönlendiriliyorsunuz.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.of(context).pop(); // Önceki sayfaya dön
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelReservations() {
    for (String seatId in selectedSeats) {
      SeatService().updateSeatStatus(widget.eventId, seatId, 'available');
    }
    setState(() {
      selectedSeats.clear();
    });
  }

  void _toggleSeatSelection(String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
        SeatService().updateSeatStatus(widget.eventId, seatId, 'available');
      } else if (selectedSeats.length < 3) {
        selectedSeats.add(seatId);
        SeatService().updateSeatStatus(widget.eventId, seatId, 'reserved');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 3 koltuk seçebilirsiniz.')),
        );
      }
    });
  }

  String _formatRemainingTime() {
    int minutes = remainingTime ~/ 60;
    int seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koltuk Seçimi'),
      ),
      body: seats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset('assets/images/stage_diagram.jpg',
                      fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kalan Süre: ${_formatRemainingTime()}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Seçilen Koltuklar: ${selectedSeats.join(", ")}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey[400],
                            child: const Center(
                              child: Text('SAHNE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            )),
                        const SizedBox(height: 20),
                        Expanded(child: _buildSeatLayout()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedSeats.isNotEmpty ? _showPaymentBottomSheet : null,
        label: const Text('Ödemeye Geç'),
        icon: const Icon(Icons.payment),
      ),
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PaymentBottomSheet(
          selectedSeats: selectedSeats.toList(),
          eventId: widget.eventId,
          onPaymentSuccess: _handlePaymentSuccess,
        );
      },
    );
  }

  void _handlePaymentSuccess() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ödeme Başarılı'),
          content: const Text('Ödemeniz başarıyla tamamlandı.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Anasayfa'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            TextButton(
              child: const Text('Biletlerim'),
              onPressed: () {
                // Biletlerim sayfasına yönlendirme
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const TicketsScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeatLayout() {
    Map<String, List<String>> seatsByRow = {};
    for (String seat in seats.values.expand((element) => element)) {
      String row = seat[0];
      seatsByRow.putIfAbsent(row, () => []).add(seat);
    }

    List<String> rows = seatsByRow.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rows
                .map((row) => _buildSeatRow(row, seatsByRow[row]!))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatRow(String row, List<String> rowSeats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child:
                Text(row, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Row(
            children: rowSeats.map((seatId) => _buildSeat(seatId)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(String seatId) {
    String status = seatStatus[seatId] ?? 'available';
    bool isAvailable = status == 'available';
    bool isSelected = selectedSeats.contains(seatId);

    return GestureDetector(
        onTap: isAvailable ? () => _toggleSeatSelection(seatId) : null,
        child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : (isAvailable ? Colors.green : Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                seatId.substring(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )));
  }

// Diğer widget'lar (_buildSeatLayout, _buildSeatRow, _buildSeat) aynı kalacak
}

class PaymentBottomSheet extends StatelessWidget {
  final List<String> selectedSeats;
  final String eventId;
  final VoidCallback onPaymentSuccess;

  const PaymentBottomSheet({
    Key? key,
    required this.selectedSeats,
    required this.eventId,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Seçilen Koltuklar: ${selectedSeats.join(", ")}'),
          const SizedBox(height: 16),
          // Burada ödeme bilgileri için form alanları eklenebilir
          ElevatedButton(
            onPressed: () {
              // Ödeme işlemi gerçekleştirme
              for (String seatId in selectedSeats) {
                SeatService().updateSeatStatus(eventId, seatId, 'sold');
              }
              Navigator.pop(context); // BottomSheet'i kapat
              onPaymentSuccess(); // Başarılı ödeme dialogunu göster
            },
            child: const Text('Ödemeyi Tamamla'),
          ),
        ],
      ),
    );
  }
}

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biletlerim'),
      ),
      body: const Center(
        child: Text('Biletlerim Sayfası'),
      ),
    );
  }
}
