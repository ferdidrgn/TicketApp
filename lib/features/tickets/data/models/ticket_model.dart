import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? customerId;
  final String? showId, stageId, eventId;
  final String? orderPrice, orderMethod;
  final List<String>? buySeats;
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
    this.buySeats,
    this.isPast,
  });

  /// 🔥 Firestore'dan güvenli okuma
  factory TicketModel.fromFirestore(final Map<String, dynamic> data) =>
      TicketModel(
        id: data['_id'] as String?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        customerId: data['customerId'] as String?,
        showId: data['showId'] as String?,
        stageId: data['stageId'] as String?,
        eventId: data['eventId'] as String?,
        orderMethod: data['orderMethod'] as String?,
        orderPrice: data['orderPrice'] as String?,
        buySeats:
            (data['buySeats'] as List?)?.map((e) => e.toString()).toList(),
        isPast: data['isPast'] as bool?,
      );

  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'customerId': customerId,
        'showId': showId,
        'stageId': stageId,
        'eventId': eventId,
        'orderMethod': orderMethod,
        'orderPrice': orderPrice,
        'buySeats': buySeats,
        'isPast': isPast,
      };
}
