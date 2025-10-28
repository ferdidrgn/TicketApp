import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/player_model.dart';

abstract class PlayerRemoteDataSource {
  Future<List<PlayerModel?>?> getPlayers(final bool isLimit);

  Future<List<PlayerModel?>?> getPlayersByIds(final List<String> playerIds);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final FirebaseFirestore _firestore;

  const PlayerRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<PlayerModel?>?> getPlayers(final bool isLimit) async {
    try {
      final query = _firestore.collection('Player');
      final snapshot = isLimit
          ? await query.orderBy('_createdAt', descending: true).limit(20).get()
          : await query.get();

      return snapshot.docs.isEmpty ? [] : _mapToPlayers(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayers): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncular alınamadı: $e');
    }
  }

  @override
  Future<List<PlayerModel?>?> getPlayersByIds(
      final List<String> playerIds) async {
    if (playerIds.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('Player')
          .where(FieldPath.documentId, whereIn: playerIds)
          .get();

      return snapshot.docs.isEmpty ? [] : _mapToPlayers(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayersByIds): ${e.message}');
    } catch (e) {
      throw Exception('Belirtilen ID\'lerdeki oyuncular alınamadı: $e');
    }
  }

  /// Firestore belgelerini [PlayerModel] listesine dönüştürür.
  List<PlayerModel> _mapToPlayers(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((final doc) => PlayerModel.fromFirestore(doc.data()))
          .toList();
}
