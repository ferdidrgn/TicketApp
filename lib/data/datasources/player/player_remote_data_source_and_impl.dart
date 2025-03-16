import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/player_model.dart';

abstract class PlayerRemoteDataSource {
  Future<List<PlayerModel>> getPlayers(final isLimit);

  Future<PlayerModel?> getPlayerById(final String playerId);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final FirebaseFirestore firestore;

  PlayerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<PlayerModel>> getPlayers(final isLimit) async {
    try {
      final querySnapshot = isLimit
          ? await firestore
              .collection('Player')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Player').get();

      return _mapQuerySnapshotToPlayers(querySnapshot);
    } catch (e) {
      throw Exception('Error fetching players: ${e.toString()}');
    }
  }

  @override
  Future<PlayerModel?> getPlayerById(final String playerId) async {
    if (playerId.isEmpty) throw Exception('Player ID cannot be empty.');

    try {
      final result = await firestore
          .collection('Player')
          .where('_id', isEqualTo: playerId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;
      return PlayerModel.fromFirestore(result.docs.first.data());
    } catch (error) {
      throw Exception('Error fetching player by ID: ${error.toString()}');
    }
  }

  // Convert Firestore document to Player model
  List<PlayerModel> _mapQuerySnapshotToPlayers(
      final QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((final doc) => PlayerModel.fromFirestore(doc.data()))
        .toList();
  }
}
