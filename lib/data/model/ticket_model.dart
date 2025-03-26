import '../../domain/entities/ticket.dart';

class TicketModel {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? customerId;
  final String? showId;
  final String? stageId;
  final String? eventId;
  final String? orderMethod;
  final String? orderPrice;
  final bool? isPast;

  const TicketModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.customerId,
    this.showId,
    this.stageId,
    this.eventId,
    this.orderMethod,
    this.orderPrice,
    this.isPast,
  });

  factory TicketModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const TicketModel();
    return TicketModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
      customerId: data['customerId'] as String?,
      showId: data['showId'] as String?,
      stageId: data['stageId'] as String?,
      eventId: data['eventId'] as String?,
      orderMethod: data['orderMethod'] as String?,
      orderPrice: data['orderPrice'] as String?,
      isPast: data['isPast'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'showId': showId,
        'stageId': stageId,
        'eventId': eventId,
        'orderMethod': orderMethod,
        'orderPrice': orderPrice,
        'isPast': isPast,
      };

  Ticket toEntity() => Ticket(
        id: id ?? '0',
        createdAt: createdAt ?? 'Tarih bulunamadı',
        updatedAt: updatedAt ?? 'Tarih bulunamadı',
        customerId: customerId ?? '0',
        showId: showId ?? '0',
        stageId: stageId ?? '0',
        eventId: eventId ?? '0',
        orderMethod: orderMethod ?? '0',
        orderPrice: orderPrice ?? '0',
        isPast: isPast ?? false,
      );

  factory TicketModel.fromEntity(final Ticket ticket) => TicketModel(
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
