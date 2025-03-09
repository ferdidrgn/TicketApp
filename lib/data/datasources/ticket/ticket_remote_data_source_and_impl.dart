import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/ticket.dart';

abstract class TicketRemoteDataSource {
  Future<Ticket?> getTicketById(final String ticketId);

  Future<void> createTicket(final Ticket ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore firestore;

  TicketRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Ticket?> getTicketById(final String ticketId) async {
    try {
      final QuerySnapshot result = await firestore
          .collection('Ticket')
          .where('_id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToTicket(result.docs.first);
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

  Ticket _mapDocumentToTicket(final DocumentSnapshot doc) {
    return Ticket(
      createdAt: _getFieldAsString(doc, '_createdAt'),
      updatedAt: _getFieldAsString(doc, '_updatedAt'),
      id: _getFieldAsString(doc, '_id'),
      showId: _getFieldAsString(doc, 'showId'),
      customerId: _getFieldAsString(doc, 'customerId'),
      stageId: _getFieldAsString(doc, 'stageId'),
      eventId: _getFieldAsString(doc, 'eventId'),
      orderMethod: _getFieldAsString(doc, 'orderMethod'),
      orderPrice: _getFieldAsString(doc, 'orderPrice'),
    );
  }

  String _getFieldAsString(
      final DocumentSnapshot document, final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }
}
