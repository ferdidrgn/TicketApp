import '../../domain/entities/ticket.dart';

class TicketModel {
  final String id;
  final String? createdAt;
  final String? updatedAt;
  final String customerId;
  final String showId;
  final String stageId;
  final String eventId;
  final String orderMethod;
  final String orderPrice;
  final bool isPast;

  const TicketModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.customerId,
    required this.showId,
    required this.stageId,
    required this.eventId,
    required this.orderMethod,
    required this.orderPrice,
    this.isPast = false,
  });

  factory TicketModel.fromFirestore(final Map<String, dynamic> data) {
    return TicketModel(
      id: data['_id'] ?? '',
      createdAt: data['_createdAt'],
      updatedAt: data['_updatedAt'],
      customerId: data['customerId'] ?? '',
      showId: data['showId'] ?? '',
      stageId: data['stageId'] ?? '',
      eventId: data['eventId'] ?? '',
      orderMethod: data['orderMethod'] ?? '',
      orderPrice: data['orderPrice'] ?? '',
      isPast: data['isPast'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'customerId': customerId,
      'showId': showId,
      'stageId': stageId,
      'eventId': eventId,
      'orderMethod': orderMethod,
      'orderPrice': orderPrice,
      'isPast': isPast,
    };
  }

  Ticket toEntity() {
    return Ticket(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerId: customerId,
      showId: showId,
      stageId: stageId,
      eventId: eventId,
      orderMethod: orderMethod,
      orderPrice: orderPrice,
      isPast: isPast,
    );
  }

  factory TicketModel.fromEntity(final Ticket ticket) {
    return TicketModel(
      id: ticket.id,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      customerId: ticket.customerId,
      showId: ticket.showId,
      stageId: ticket.stageId,
      eventId: ticket.eventId,
      orderMethod: ticket.orderMethod,
      orderPrice: ticket.orderPrice,
      isPast: ticket.isPast,
    );
  }
}
