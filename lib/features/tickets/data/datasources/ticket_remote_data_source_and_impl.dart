import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTicketsByIds(final List<String> ticketIds);
  Future<List<TicketModel>> getTicketsByCustomerId(final String customerId);
  Future<bool> createTicket(final TicketModel ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Ticket';

  TicketRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<TicketModel>> getTicketsByIds(
      final List<String> ticketIds) async {
    if (ticketIds.isEmpty) return [];

    try {
      // 🔥 DÜZELTME: Firestore 'whereIn' sorgusu en fazla 30 eleman alır
      // (yorum burada yanlışlıkla 10 diyordu) — show/event/stage
      // datasource'larındaki aynı düzeltmeyle tutarlı hale getirildi.
      const chunkSize = 30;
      final uniqueIds = ticketIds.toSet().toList();
      final chunks = <List<String>>[
        for (var i = 0; i < uniqueIds.length; i += chunkSize)
          uniqueIds.sublist(
              i, i + chunkSize > uniqueIds.length ? uniqueIds.length : i + chunkSize),
      ];

      final snapshots = await Future.wait(chunks.map((final chunk) =>
          _firestore
              .collection(_collection)
              .where(FieldPath.documentId, whereIn: chunk)
              .get()));

      return snapshots.expand(_mapSnapshot).toList();
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  @override
  Future<List<TicketModel>> getTicketsByCustomerId(
      final String customerId) async {
    if (customerId.isEmpty) throw Exception('Customer ID cannot be empty.');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .get();

      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Failed to fetch tickets by customerId: $e');
    }
  }

  @override
  Future<bool> createTicket(final TicketModel ticket) async {
    try {
      // Yeni bir document ID oluştur
      final docRef = _firestore.collection(_collection).doc();

      final ticketMap = {
        ...ticket.toFirestore(),
        '_id': docRef.id,
        '_createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(ticketMap);
      return true;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// 🔥 Yardımcı Metot: Kod tekrarını önler ve güvenli dönüşüm sağlar
  List<TicketModel> _mapSnapshot(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return TicketModel.fromFirestore(data);
      }).toList();
}
