import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/data/datasources/ticket/ticket_remote_data_source_and_impl.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../domain/entities/ticket.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String showId;
  final String eventId;

  const SeatSelectionScreen({
    super.key,
    required this.showId,
    required this.eventId,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final firestore = FirebaseFirestore.instance;
  Map<String, List<String?>?>? seats = {};
  Map<String, Map<String, dynamic>>? seatStatus = {};
  Set<String> selectedSeats = {};
  String? stageId;
  Timer? reservationTimer;
  int remainingTime = 600; // 10 dakika
  double totalPrice = 0.0;
  double seatPrice = 0.0;
  String date = "";
  String time = "";

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
    try {
      await initializeAndGetEventSeats(widget.eventId);
      final fetchStageId = await getStageId(widget.eventId);

      if (fetchStageId == null) return;

      final fetchedSeats = await getSeatsByStage(fetchStageId);

      final fetchedSeatStatus =
          await getSeatStatusByEvent(widget.eventId);

      final fetchPrice = await getEventPrice(widget.eventId);

      final Map<String, String>? fetchDate = await getEventDate(widget.eventId);

      setState(() {
        stageId = fetchStageId;
        seats = fetchedSeats;
        seatStatus = fetchedSeatStatus;
        seatPrice = fetchPrice != null ? double.parse(fetchPrice) : 0.0;
        date = fetchDate?['date'].toString() ?? '';
        time = fetchDate?['time'].toString() ?? '';
      });

    } catch (e) {
      throw Exception("Error fetching stage data: ${e.toString()}");
    }
  }

  void _startReservationTimer() {
    reservationTimer =
        Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (remainingTime > 0)
        setState(() => remainingTime--);
      else
        _handleTimeUp(timer);
    });
  }

  void _handleTimeUp(final Timer timer) {
    _showTimeUpDialog();
    timer.cancel();
    _cancelReservations();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) {
        return AlertDialog(
          title: const Text('İşlem Süresi Doldu'),
          content: const Text('Oyun bilgilerine yönlendiriliyorsunuz.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).popUntil((final route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelReservations() {
    for (final String seatId in selectedSeats) {
      updateSeatStatus(widget.eventId, seatId, 'available');
    }
    setState(() => selectedSeats.clear());
  }

  void _toggleSeatSelection(final String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId))
        _removeSeat(seatId);
      else if (selectedSeats.length < 3)
        _addSeat(seatId);
      else
        _showMaxSeatsSnackbar();
    });
  }

  void _removeSeat(final String seatId) {
    selectedSeats.remove(seatId);
    updateSeatStatus(widget.eventId, seatId, 'available');
    totalPrice -= seatPrice;
  }

  void _addSeat(final String seatId) {
    selectedSeats.add(seatId);
    updateSeatStatus(widget.eventId, seatId, 'reserved', customerId: "test");
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
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koltuk Seçimi')),
      body: seats?.isEmpty ?? true
          ? const Center(child: Text('Tekrar Deneyiniz'))
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

    if (seats == null) return seatsByRow;
    for (final String seat in seats!.values.expand((final element) => element?.whereType<String>() ?? [])) {
      final String row = seat[0];
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

  Widget _buildRows(final Map<String, List<String>> seatsByRow) {
    final rows = seatsByRow.keys.toList()..sort();

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: rows
                        .map(
                            (final row) => _buildSeatRow(row, seatsByRow[row]!))
                        .toList()))));
  }

  Widget _buildSeatRow(final String row, final List<String> rowSeats) {
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
              children:
                  rowSeats.map((final seatId) => _buildSeat(seatId)).toList()),
        ],
      ),
    );
  }

  Widget _buildSeat(final String seatId) {
    final status = seatStatus?[seatId]?['status'] ?? 'available';
    final reservedById = seatStatus?[seatId]?['customerId'];

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

  Color _getSeatColor(
      final String status, final String? reservedById, final bool isSelected) {
    if (status == 'sold')
      return Colors.white30; // Satılmış koltuk
    else if (status == 'reserved' &&
        reservedById != null &&
        reservedById != 'test')
      return Colors.purple; // Başka biri tarafından rezerve edilmiş koltuk
    else if (isSelected)
      return Colors.blue; // Seçili koltuk
    else
      return Colors.green; // Boş koltuk
  }

  Future<void> _showPaymentBottomSheet() async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (final BuildContext context) {
          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ödeme Bilgileri',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Seçilen Koltuklar: ${selectedSeats.join(", ")}'),
                    Text('Tarih: $date'),
                    Text('Saat: $time'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _showPaymentMethods,
                        child: const Text('Ödeme Seçenekleri'))
                  ]));
        });
  }

  Future<void> _showPaymentMethods() async {
    final String? selectedMethod = await showDialog<String>(
      context: context,
      builder: (final BuildContext context) {
        return AlertDialog(
            title: const Text('Ödeme Yöntemi Seçin'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('Google Play'),
                  onTap: () => Navigator.of(context).pop('Google Play')),
              ListTile(
                  title: const Text('Kredi Kartı'),
                  onTap: () => Navigator.of(context).pop('Kredi Kartı')),
              ListTile(
                  title: const Text('IBAN'),
                  onTap: () => Navigator.of(context).pop('IBAN')),
            ]));
      },
    );

    if (selectedMethod != null) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed != null && confirmed == true)
        await _processPayment(selectedMethod);
    }
  }

  Future<void> _processPayment(final String method) async {
    try {
      // 1. Koltukları satıldı olarak güncelle
      for (final String seatId in selectedSeats)
        await updateSeatStatus(widget.eventId, seatId, 'sold', customerId: "test");

      // 2. Bilet oluşturma işlemi
      final ticketService = TicketRemoteDataSourceImpl(firestore: firestore);
      await ticketService.createTicket(_createNewTicket());

      // Başarılı mesajını göster
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bilet başarıyla oluşturuldu")));
      Navigator.pop(context); // BottomSheet'i kapat
      _handlePaymentSuccess(); // Başarılı ödeme dialogunu göster
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
    Navigator.pop(context); // BottomSheet'i kapat
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (final BuildContext context) {
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
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Text('Ödeme Başarılı'),
          content: const Text('Ödemeniz başarıyla tamamlandı.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Anasayfa'),
              onPressed: () {
                Navigator.of(context).popUntil((final route) => route.isFirst);
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
    final nowTime = DateFormatter.nowFormatDateTime();

    return Ticket(
      createdAt: nowTime,
      updatedAt: nowTime,
      id: '',
      showId: widget.showId,
      customerId: 'customer_id',
      stageId: stageId ?? '',
      eventId: widget.eventId,
      orderPrice: totalPrice.toString(),
      orderMethod: 'google_play',
      isPast: false,
    );
  }
}

/// ------------------- FIREBASE FUNKSIYONLARI ------------------------

Future<Map<String, List<String?>?>?> getSeatsByStage(
    final String stageId) async {
  try {
    if (stageId.isEmpty) throw Exception('Stage ID boş olamaz.');

    final DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('Seats').doc(stageId).get();

    if (doc.exists) {
      final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
      final Map<String, List<String>> seats = {};
      data.forEach((final row, final seatList) {
        seats[row] = List<String>.from(seatList);
      });

      if (seats.isEmpty) throw Exception('Sahne bulunamadı.');
      return seats;
    } else
      throw Exception('Belirtilen sahne bulunamadı.');
  } catch (e) {
    throw Exception('Error fetching seats: $e');
  }
}

Future<void> reserveSeat(
    final String eventId, final String seatId, final String customerId) async {
  await FirebaseFirestore.instance.doc(eventId).update({
    'seats.$seatId': {
      'status': 'reserved',
      'customerId': customerId,
    }
  });
}

Future<void> cancelReservation(
    final String eventId, final String seatId) async {
  await FirebaseFirestore.instance.doc(eventId).update({
    'seats.$seatId': {'status': 'available', 'customerId': null}
  });
}

Future<List<String?>?> getPurchasedSeatsByCustomerId(
    final String eventId, final String customerId) async {
  try {
    if (eventId.isEmpty || customerId.isEmpty)
      throw Exception('Event ID and Customer ID cannot be empty.');

    final DocumentSnapshot doc =
        await FirebaseFirestore.instance.doc(eventId).get();

    if (doc.exists) {
      final Map<String, dynamic> eventData =
          doc.data()! as Map<String, dynamic>;

      if (eventData['seats'] != null) {
        final List<String> purchasedSeats = [];

        eventData['seats'].forEach((final seatId, final seatInfo) {
          if (seatInfo['customerId'] == customerId) purchasedSeats.add(seatId);
        });

        return purchasedSeats;
      } else {
        throw Exception('Seat data not found.');
      }
    } else {
      throw Exception('Event not found.');
    }
  } catch (e) {
    throw Exception('Error fetching seats by customerId: ${e.toString()}');
  }
}

Future<void> updateSeatStatus(
    final String eventId, final String seatId, final String status,
    {final String? customerId}) async {
  if (eventId.isEmpty || seatId.isEmpty || status.isEmpty)
    throw Exception('Event ID, Seat ID, and Status cannot be empty.');

  try {
    final Map<String, dynamic> seatUpdate = {'status': status};

    if (customerId != null) seatUpdate['customerId'] = customerId;

    await FirebaseFirestore.instance.doc(eventId).update({
      'seats.$seatId': seatUpdate,
    });
  } catch (e) {
    throw Exception('Error updating seat status: ${e.toString()}');
  }
}

Future<String?> getStageId(final String eventId) async {
  if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

  try {
    print("Getting stageId for eventId: $eventId");

    // BURADA COLLECTİON ADINI BELİRTMENİZ GEREKİYOR!
    // Örnek: 'events', 'Events', 'performances' vb.
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
        .doc(eventId)
        .get();

    print("Document exists: ${docSnapshot.exists}");

    if (!docSnapshot.exists) {
      print("Document not found for eventId: $eventId");
      throw Exception("Stage data not found");
    }

    final eventData = docSnapshot.data()!;
    print("Full event data: $eventData");
    print("StageId from data: ${eventData['stageId']}");

    return eventData['stageId'] as String?;
  } catch (error) {
    print("getStageId ERROR: $error");
    throw Exception("Error fetching stage data: ${error.toString()}");
  }
}

Future<String?> getEventPrice(final String eventId) async {
  if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

  try {
    print("Getting price for eventId: $eventId");

    final docSnapshot = await FirebaseFirestore.instance
        .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
        .doc(eventId)
        .get();

    print("Price document exists: ${docSnapshot.exists}");

    if (!docSnapshot.exists) {
      print("Price document not found for eventId: $eventId");
      return null;
    }

    final eventData = docSnapshot.data()!;
    print("Price from data: ${eventData['price']}");

    return eventData['price'] as String?;
  } catch (error) {
    print("getEventPrice ERROR: $error");
    throw Exception("Error fetching event price: ${error.toString()}");
  }
}

Future<Map<String, String>?> getEventDate(final String eventId,
    {final bool formatWithMonthName = false}) async {
  try {
    print("Getting date for eventId: $eventId");

    final docSnapshot = await FirebaseFirestore.instance
        .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
        .doc(eventId)
        .get();

    print("Date document exists: ${docSnapshot.exists}");

    if (!docSnapshot.exists) {
      print("Date document not found for eventId: $eventId");
      return null;
    }

    final eventData = docSnapshot.data()!;
    final date = eventData['date'] as String?;

    print("Date from data: $date");

    if (date == null) {
      print("Date field is null in document");
      return null;
    }

    return DateFormatter.parseFormattedDateTime(date,
        formatWithMonthName: formatWithMonthName);
  } catch (error) {
    print("getEventDate ERROR: $error");
    throw Exception("Error fetching event date: ${error.toString()}");
  }
}

Future<Map<String, Map<String, dynamic>>?> getSeatStatusByEvent(
    final String eventId) async {
  try {
    if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

    print("Getting seat status for eventId: $eventId");

    final doc = await FirebaseFirestore.instance
        .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
        .doc(eventId)
        .get();

    print("Seat status document exists: ${doc.exists}");

    if (!doc.exists) {
      print("Seat status document not found for eventId: $eventId");
      throw Exception('Event not found.');
    }

    final data = doc.data()!;
    print("Full document data: $data");
    print("Seats field: ${data['seats']}");
    print("Seats type: ${data['seats'].runtimeType}");

    final seatStatus = <String, Map<String, dynamic>>{};

    if (data['seats'] is Map) {
      final seatsMap = data['seats'] as Map<String, dynamic>;
      print("Processing ${seatsMap.length} seats");

      seatsMap.forEach((final seatId, final seatInfo) {
        print("Processing seat: $seatId with info: $seatInfo");
        if (seatInfo is Map<String, dynamic>) {
          seatStatus[seatId] = seatInfo;
        }
      });

      print("Final seat status: $seatStatus");
    } else {
      print("Seats field is not a Map. Type: ${data['seats'].runtimeType}");
      throw Exception('Seat status is not a valid map.');
    }

    return seatStatus;
  } catch (e) {
    print("getSeatStatusByEvent ERROR: $e");
    throw Exception('Error fetching seat status: ${e.toString()}');
  }
}

Future<void> initializeAndGetEventSeats(final String eventId) async {
  try {
    if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');

    print("Initializing seats for eventId: $eventId");

    final eventDoc = await FirebaseFirestore.instance
        .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
        .doc(eventId)
        .get();

    print("Initialize document exists: ${eventDoc.exists}");

    if (!eventDoc.exists) {
      print("Initialize document not found for eventId: $eventId");
      throw Exception('Event not found.');
    }

    final eventData = eventDoc.data();
    print("Initialize event data: $eventData");

    if (eventData == null ||
        eventData['seats'] == null ||
        (eventData['seats'] as Map).isEmpty) {
      print("Seats data is empty, initializing...");

      final stageSeats = await getSeatsByStage(eventData?['stageId']);
      print("Stage seats: $stageSeats");

      if (stageSeats == null || stageSeats.isEmpty) {
        print("No stage seats found, returning");
        return;
      }

      final seatStatus = <String, Map<String, dynamic>>{};

      for (final entry in stageSeats.entries) {
        final seats = entry.value;
        if (seats is List) {
          for (final seat in seats!.whereType<String>()) {
            seatStatus[seat] = {'status': 'available', 'customerId': null};
          }
        }
      }

      print("Updating document with seat status: $seatStatus");

      await FirebaseFirestore.instance
          .collection('Event') // ← BU KISMI DEĞİŞTİRİN!
          .doc(eventId)
          .update({'seats': seatStatus});

      print("Document updated successfully");
    } else {
      print("Seats data already exists, skipping initialization");
    }
  } catch (e) {
    print("initializeAndGetEventSeats ERROR: $e");
    throw Exception('Error initializing event seats: ${e.toString()}');
  }
}
