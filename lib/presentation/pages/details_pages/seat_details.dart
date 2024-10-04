import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../../../data/model/ticket.dart';
import '../../../data/repository/seat_service.dart';
import '../../../data/repository/ticket_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String showId;
  final String stageId;
  final String eventId;

  const SeatSelectionScreen({
    super.key,
    required this.showId,
    required this.stageId,
    required this.eventId,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final SeatService seatService = SeatService();
  Map<String, List<String>> seats = {};
  Map<String, Map<String, dynamic>> seatStatus = {};
  Set<String> selectedSeats = {};
  Timer? reservationTimer;
  int remainingTime = 600; // 10 dakika
  double totalPrice = 0.0;
  double seatPrice = 0.0;

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
    await seatService.initializeEventSeats(widget.eventId, widget.stageId);

    final fetchedSeats = await seatService.getSeatsByStage(widget.stageId);
    final fetchedSeatStatus =
        await seatService.getSeatStatusByEvent(widget.eventId);

    setState(() {
      seats = fetchedSeats;
      seatStatus = fetchedSeatStatus;
    });
  }

  void _startReservationTimer() {
    reservationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        _handleTimeUp(timer);
      }
    });
  }

  void _handleTimeUp(Timer timer) {
    _showTimeUpDialog();
    timer.cancel();
    _cancelReservations();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('İşlem Süresi Doldu'),
          content: const Text('Oyun bilgilerine yönlendiriliyorsunuz.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelReservations() {
    for (String seatId in selectedSeats) {
      seatService.updateSeatStatus(widget.eventId, seatId, 'available');
    }
    setState(() => selectedSeats.clear());
  }

  void _toggleSeatSelection(String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        _removeSeat(seatId);
      } else if (selectedSeats.length < 3) {
        _addSeat(seatId);
      } else {
        _showMaxSeatsSnackbar();
      }
    });
  }

  void _removeSeat(String seatId) {
    selectedSeats.remove(seatId);
    seatService.updateSeatStatus(widget.eventId, seatId, 'available');
    totalPrice -= seatPrice;
  }

  void _addSeat(String seatId) {
    selectedSeats.add(seatId);
    seatService.updateSeatStatus(widget.eventId, seatId, 'reserved');
    totalPrice += seatPrice;
  }

  void _showMaxSeatsSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('En fazla 3 koltuk seçebilirsiniz.')),
    );
  }

  String _formatRemainingTime() {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koltuk Seçimi')),
      body: seats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildSeatSelectionView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedSeats.isNotEmpty ? _showPaymentBottomSheet : null,
        label: const Text('Ödemeye Geç'),
        icon: const Icon(Icons.payment),
      ),
    );
  }

  Widget _buildSeatSelectionView() {
    return Column(
      children: [
        _buildStageImage(),
        const SizedBox(height: 20),
        _buildRemainingTimeText(),
        const SizedBox(height: 10),
        _buildSelectedSeatsText(),
        const SizedBox(height: 10),
        _buildTotalPriceText(),
        const SizedBox(height: 20),
        _buildSeatLayout(),
      ],
    );
  }

  Widget _buildStageImage() {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildRemainingTimeText() {
    return Text(
      'Kalan Süre: ${_formatRemainingTime()}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSelectedSeatsText() {
    return Text(
      'Seçilen Koltuklar: ${selectedSeats.join(", ")}',
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildTotalPriceText() {
    return Text(
      'Toplam Fiyat: $totalPrice TL',
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildSeatLayout() {
    final seatsByRow = _groupSeatsByRow();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _buildStageLabel(),
            const SizedBox(height: 20),
            _buildRows(seatsByRow),
          ],
        ),
      ),
    );
  }

  Map<String, List<String>> _groupSeatsByRow() {
    final seatsByRow = <String, List<String>>{};

    for (String seat in seats.values.expand((element) => element)) {
      String row = seat[0];
      seatsByRow.putIfAbsent(row, () => []).add(seat);
    }

    return seatsByRow;
  }

  Widget _buildStageLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey[400],
      child: const Center(
        child: Text(
          'SAHNE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildRows(Map<String, List<String>> seatsByRow) {
    final rows = seatsByRow.keys.toList()..sort();

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: rows
                        .map((row) => _buildSeatRow(row, seatsByRow[row]!))
                        .toList()))));
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
          Row(children: rowSeats.map((seatId) => _buildSeat(seatId)).toList()),
        ],
      ),
    );
  }

  Widget _buildSeat(String seatId) {
    final status = seatStatus[seatId]?['status'] ?? 'available';
    final reservedById = seatStatus[seatId]?['customerId'];

    final isAvailable = status == 'available' ||
        (status == 'reserved' && reservedById == 'test');
    final isSelected = selectedSeats.contains(seatId);
    final seatColor = _getSeatColor(status, reservedById, isSelected);

    return GestureDetector(
      onTap: isAvailable ? () => _toggleSeatSelection(seatId) : null,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            seatId.substring(1),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _getSeatColor(String status, String? reservedById, bool isSelected) {
    if (status == 'sold') {
      return Colors.white30; // Satılmış koltuk
    } else if (status == 'reserved' &&
        reservedById != null &&
        reservedById != 'test') {
      return Colors.purple; // Başka biri tarafından rezerve edilmiş koltuk
    } else if (isSelected) {
      return Colors.blue; // Seçili koltuk
    } else {
      return Colors.green; // Boş koltuk
    }
  }

  Future<void> _showPaymentBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ödeme Bilgileri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Seçilen Koltuklar: ${selectedSeats.join(", ")}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _confirmPayment,
                child: const Text('Ödemeyi Tamamla'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmPayment() async {
    final confirmed = await _showConfirmationDialog();
    if (confirmed == true) {
      try {
        // 1. Koltukları satıldı olarak güncelle
        for (String seatId in selectedSeats) {
          try {
            await seatService.updateSeatStatus(widget.eventId, seatId, 'sold',
                customerId: "test");
          } catch (e) {
            throw Exception('Koltuk güncellenemedi: $seatId - $e');
          }
        }

        // 2. Koltuklar başarıyla güncellendikten sonra kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Koltuklar sisteme kaydedildi. Bilet oluşturuluyor...")));

        // 3. Bilet oluşturma işlemi
        await TicketService().createTicket(_createNewTicket());

        // 4. Başarılı mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bilet başarıyla oluşturuldu")));
      } catch (e) {
        throw Exception(e);
      }
    }

    Navigator.pop(context); // BottomSheet'i kapat
    _handlePaymentSuccess(); // Başarılı ödeme dialogunu göster
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Onay'),
          content: const Text('Ödeme işlemini onaylıyor musunuz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet'),
            ),
          ],
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
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  Ticket _createNewTicket() {
    var uuid = const Uuid();
    final nowTime = DateTime.now().toString();
    return Ticket(
      createdAt: nowTime,
      updatedAt: nowTime,
      id: uuid.v4(),
      showId: widget.showId,
      customerId: 'customer_id',
      stageId: widget.stageId,
      eventId: widget.eventId,
      orderPrice: '20',
      orderMethod: 'google_play',
    );
  }
}
