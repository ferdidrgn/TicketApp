class Ticket {
  final String id;
  final String title;
  final String customerName;
  final String customerSurname;
  final String showName;
  final DateTime date;
  final String time;
  final String? seat;
  final String? row;
  final String? gate;
  final String? stageName;
  final String? stageLocation;
  final double price;

  Ticket({
    required this.id,
    required this.title,
    required this.customerName,
    required this.customerSurname,
    required this.showName,
    required this.date,
    required this.time,
    this.seat,
    this.row,
    this.gate,
    this.stageName,
    this.stageLocation,
    required this.price,
  });
}