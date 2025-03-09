import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<TicketModel?> getTicketById(final String ticketId);
  Future<void> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore firestore;

  TicketRemoteDataSourceImpl({required this.firestore});

  @override
  Future<TicketModel?> getTicketById(final String ticketId) async {
    try {
      final QuerySnapshot result = await firestore
          .collection('Ticket')
          .where('_id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return TicketModel.fromFirestore(result.docs.first.data()! as Map<String, dynamic>);
    } catch (error) {
      throw Exception('Bilet Getirme Hatası: $error');
    }
  }

  @override
  Future<void> createTicket(final Ticket ticket) async {
    try {
      await firestore.collection('Ticket').add({
        '_createdAt': ticket.createdAt,
        '_updatedAt': ticket.updatedAt,
        '_id': firestore.collection('Ticket').doc().id,
        'showId': ticket.showId,
        'customerId': ticket.customerId,
        'stageId': ticket.stageId,
        'eventId': ticket.eventId,
        'orderMethod': ticket.orderMethod,
        'orderPrice': ticket.orderPrice,
      });
    } catch (error) {
      throw Exception('Bilet Kaydetme Hatası: $error');
    }
  }
}
