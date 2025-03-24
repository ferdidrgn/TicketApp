import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketsIds);
  Future<void> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore firestore;

  TicketRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketsIds) async {

    try {
      if (ticketsIds.isEmpty) throw Exception('Ticket ID cannot be empty.');

      final result = await firestore
          .collection('Ticket')
          .where(FieldPath.documentId, whereIn: ticketsIds)
          .get();

      if (result.docs.isEmpty) return null;
      return result.docs.map((final doc) {
        return TicketModel.fromFirestore(doc.data());
      }).toList();
    } catch (error) {
      throw Exception('Error fetching ticket: $error');
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
      throw Exception('Error saving ticket: $error');
    }
  }
}
