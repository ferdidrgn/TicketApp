import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ticket.dart';

class TicketService {
  final CollectionReference _ticketService =
      FirebaseFirestore.instance.collection('Ticket');

// Ticket ID ile gösterileri getiren fonksiyon
  Future<Ticket?> getTicketById(final String ticketId) async {
    try {
      final QuerySnapshot result =
          await _ticketService.where('_id', isEqualTo: ticketId).limit(1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToTicket(result.docs.first);
    } catch (error) {
      throw Exception('Bilet Getirme Hatası: $error');
    }
  }

// Bilet kaydetme fonksiyonu
  Future<void> createTicket(final Ticket ticket) async {
    try {
      await _ticketService.add({
        '_createdAt': ticket.createdAt,
        '_updatedAt': ticket.updatedAt,
        '_id': _ticketService.doc().id,
        'showId': ticket.showId,
        'customerId': ticket.customerId,
        'stageId': ticket.stageId,
        'eventId': ticket.eventId,
        'orderMethod': ticket.orderMethod,
        'orderPrice': ticket.orderPrice
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
        orderPrice: _getFieldAsString(doc, 'orderPrice'));
  }

// Helper to get field as a string
  String _getFieldAsString(
      final DocumentSnapshot document, final String fieldName) {
    return document[fieldName].toString();
  }
}
