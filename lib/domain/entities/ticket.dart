import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
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

  const Ticket({
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

  factory Ticket.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Ticket();
    return Ticket(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      customerId: data['customerId'] as String?,
      showId: data['showId'] as String?,
      stageId: data['stageId'] as String?,
      eventId: data['eventId'] as String?,
      orderMethod: data['orderMethod'] as String?,
      orderPrice: data['orderPrice'] as String?,
      isPast: data['isPast'] as bool?,
    );
  }

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
