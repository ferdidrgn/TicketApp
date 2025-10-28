import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketIds);

  Future<bool> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Ticket';

  TicketRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketIds) async {
    if (ticketIds.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: ticketIds)
          .get();

      return snapshot.docs
          .map((final doc) => TicketModel.fromFirestore(doc.data()))
          .toList();
    } catch (e, s) {
      throw Exception('Failed to fetch tickets → $e\n$s');
    }
  }

  @override
  Future<bool> createTicket(final Ticket ticket) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final ticketMap = {
        ...TicketModel.fromEntity(ticket).toFirestore(),
        '_id': docRef.id,
      };
      await docRef.set(ticketMap);
      return true;
    } catch (e, s) {
      throw Exception('Failed to create ticket → $e\n$s');
    }
  }
}
