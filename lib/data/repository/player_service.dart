import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/player.dart';

class PlayerService {
  final CollectionReference _playerCollection =
      FirebaseFirestore.instance.collection('Player');

  //all players
  Future<List<Player?>> getPlayers(bool isLimit) async {
    try {
      QuerySnapshot snapshot = isLimit
          ? await _playerCollection.orderBy('_createdAt', descending: true).limit(20).get()
          : await _playerCollection.get();
      return snapshot.docs.map((doc) => _mapDocumentToPlayer(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching players: $e');
    }
  }

  // player by ID
  Future<Player?> getPlayerById(String playerId) async {
    try {
      QuerySnapshot result =
          await _playerCollection.where('_id', isEqualTo: playerId).limit(1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToPlayer(result.docs.first);
    } catch (error) {
      throw Exception('Error fetching players: $error');
    }
  }

// Convert Firestore document to Player model
  Player _mapDocumentToPlayer(DocumentSnapshot document) {
    return Player(
      createdAt: _getStringField(document, '_createdAt'),
      updatedAt: _getStringField(document, '_updatedAt'),
      id: _getStringField(document, '_id'),
      firstName: _getStringField(document, 'firstName'),
      lastName: _getStringField(document, 'lastName'),
      bio: _getStringField(document, 'bio'),
      imageUrl: _getStringField(document, 'imageUrl'),
      nowShowsId: _getListField(document, 'nowShowsId'),
      oldShowsId: _getListField(document,'oldShowsId')
    );
  }

  String _getStringField(DocumentSnapshot document, String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(DocumentSnapshot document, String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
