import 'package:flutter/material.dart';
import '../../../data/repository/seat_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String stageId;
  final String eventId;

  const SeatSelectionScreen(
      {super.key, required this.stageId, required this.eventId});

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<String, List<String>> seats = {};
  Map<String, String> seatStatus = {};
  Set<String> selectedSeats = {};

  @override
  void initState() {
    super.initState();
    _fetchSeats();
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

  void _toggleSeatSelection(String seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
      } else {
        selectedSeats.add(seatId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koltuk Seçimi'),
      ),
      body: seats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildSeatLayout(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Seçilen koltuklar: $selectedSeats');
        },
        child: const Icon(Icons.check),
      ),
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
            child: Text(row,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}
