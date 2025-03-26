import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/player_model.dart';

abstract class PlayerRemoteDataSource {
  Future<List<PlayerModel?>?> getPlayers( isLimit);
  Future<List<PlayerModel?>?> getPlayersByIds(final List<String> playersIds);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final FirebaseFirestore firestore;

  PlayerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<PlayerModel>> getPlayers(isLimit) async {
    try {
      final querySnapshot = isLimit
          ? await firestore
              .collection('Player')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Player').get();

      if (querySnapshot.docs.isEmpty) return [];
      return _convertQuerySnapshotToPlayerList(querySnapshot);
    } catch (e) {
      throw Exception('Error fetching players: ${e.toString()}');
    }
  }

  @override
  Future<List<PlayerModel?>?> getPlayersByIds(final List<String> playersIds) async {

    try {
      if (playersIds.isEmpty) throw Exception('Players IDs cannot be empty.');

      final querySnapshot = await firestore
          .collection('Player')
          .where(FieldPath.documentId, whereIn: playersIds)
          .get();

      if (querySnapshot.docs.isEmpty) return [];
      return _convertQuerySnapshotToPlayerList(querySnapshot);
    } catch (error) {
      throw Exception('Error fetching players by IDs: ${error.toString()}');
    }
  }

  // Convert Firestore document to Player model
  List<PlayerModel> _convertQuerySnapshotToPlayerList(
      final QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((final doc) => PlayerModel.fromFirestore(doc.data()))
        .toList();
  }
}
