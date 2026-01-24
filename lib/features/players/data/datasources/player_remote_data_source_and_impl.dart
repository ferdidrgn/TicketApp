import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

abstract class PlayerRemoteDataSource {
  Future<List<PlayerModel>> getPlayers(final bool isLimit);
  Future<List<PlayerModel>> getPlayersByIds(final List<String> playerIds);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'Player';

  const PlayerRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<PlayerModel>> getPlayers(final bool isLimit) async {
    try {
      final collectionRef = _firestore.collection(_collectionPath);

      Query<Map<String, dynamic>> query = collectionRef;

      if (isLimit)
        query = query.orderBy('_createdAt', descending: true).limit(20);

      final snapshot = await query.get();

      return _mapSnapshot(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayers): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncular alınamadı: $e');
    }
  }

  @override
  Future<List<PlayerModel>> getPlayersByIds(
      final List<String> playerIds) async {
    if (playerIds.isEmpty) return [];

    try {
      // Firestore 'whereIn' sorgusu en fazla 30 ID destekler.
      // Daha fazlası için chunk logic gerekir ama şimdilik standart kullanım:
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where(FieldPath.documentId, whereIn: playerIds)
          .get();

      return _mapSnapshot(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayersByIds): ${e.message}');
    } catch (e) {
      throw Exception('Belirtilen ID\'lerdeki oyuncular alınamadı: $e');
    }
  }

  /// 🔥 KRİTİK METOT: Firestore dökümanlarını modele çevirirken
  /// döküman ID'sini (_id) verinin içine enjekte eder.
  List<PlayerModel> _mapSnapshot(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] =
            doc.id; // Firestore Document ID'yi modelin içine koyuyoruz
        return PlayerModel.fromFirestore(data);
      }).toList();
}
