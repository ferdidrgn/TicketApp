import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketIds);

  Future<bool> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore firestore;

  TicketRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TicketModel?>?> getTicketsByIds(
      final List<String> ticketIds) async {
    if (ticketIds.isEmpty) return [];

    try {
      final snapshot = await firestore
          .collection('Ticket')
          .where(FieldPath.documentId, whereIn: ticketIds)
          .get();

      return snapshot.docs
          .map((final doc) => TicketModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching tickets: $e');
    }
  }

  @override
  Future<bool> createTicket(final Ticket ticket) async {
    try {
      final docRef = firestore.collection('Ticket').doc();
      final ticketMap = TicketModel.fromEntity(ticket).toFirestore()
        ..['_id'] = docRef.id;
      await docRef.set(ticketMap);
      return true;
    } catch (e) {
      throw Exception('Error saving ticket: $e');
    }
  }
}
