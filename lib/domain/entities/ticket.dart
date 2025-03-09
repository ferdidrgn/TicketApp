import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
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

  const Ticket({
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

  Ticket copyWith({
    final String? id,
    final String? createdAt,
    final String? updatedAt,
    final String? customerId,
    final String? showId,
    final String? stageId,
    final String? eventId,
    final String? orderMethod,
    final String? orderPrice,
    final bool? isPast,
  }) {
    return Ticket(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      showId: showId ?? this.showId,
      stageId: stageId ?? this.stageId,
      eventId: eventId ?? this.eventId,
      orderMethod: orderMethod ?? this.orderMethod,
      orderPrice: orderPrice ?? this.orderPrice,
      isPast: isPast ?? this.isPast,
    );
  }

  factory Ticket.fromMap(final Map<String, dynamic> data) {
    return Ticket(
      id:  data['_id'],
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

  Map<String, dynamic> toMap() {
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
}
