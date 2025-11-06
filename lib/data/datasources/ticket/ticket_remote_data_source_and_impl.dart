import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel?>?> getTicketsByIds(final List<String> ticketIds);
  Future<List<TicketModel?>?> getTicketsByCustomerId(final String customerId);
  Future<bool> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Ticket';

  TicketRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<TicketModel?>?> getTicketsByIds(
      final List<String> ticketIds) async {
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
        'customerId': ticket.customerId
      };
      await docRef.set(ticketMap);
      return true;
    } catch (e, s) {
      throw Exception('Failed to create ticket → $e\n$s');
    }
  }

  @override
  Future<List<TicketModel?>?> getTicketsByCustomerId(
      final String customerId) async {
    if (customerId.isEmpty) throw Exception('Customer ID cannot be empty.');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .get();

      // Bilet bulunamadıysa boş liste dön.
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((final doc) => TicketModel.fromFirestore(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      // Firebase'e özgü hataları yakala
      throw Exception(
          'Firestore hatası (getTicketsByCustomerId): ${e.message}');
    } catch (e, s) {
      // Diğer hataları yakala
      throw Exception('Failed to fetch tickets by customerId → $e\n$s');
    }
  }
}
