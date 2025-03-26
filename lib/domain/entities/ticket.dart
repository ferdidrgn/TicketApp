import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String customerId;
  final String showId;
  final String stageId;
  final String eventId;
  final String orderMethod;
  final String orderPrice;
  final bool isPast;

  const Ticket({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.showId,
    required this.stageId,
    required this.eventId,
    required this.orderMethod,
    required this.orderPrice,
    required this.isPast,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        customerId,
        showId,
        stageId,
        eventId,
        orderMethod,
        orderPrice,
        isPast,
      ];

  factory Ticket.fromMap(final Map<String, dynamic>? data) => Ticket(
        id: data?['_id'] as String? ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        customerId: data?['customerId'] as String? ?? '0',
        showId: data?['showId'] as String? ?? '0',
        stageId: data?['stageId'] as String? ?? '0',
        eventId: data?['eventId'] as String? ?? '0',
        orderMethod: data?['orderMethod'] as String? ?? '0',
        orderPrice: data?['orderPrice'] as String? ?? '0',
        isPast: data?['isPast'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'customerId': customerId,
        'showId': showId,
        'stageId': stageId,
        'eventId': eventId,
        'orderMethod': orderMethod,
        'orderPrice': orderPrice,
        'isPast': isPast,
      };
}
