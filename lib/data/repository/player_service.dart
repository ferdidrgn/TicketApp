import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/player.dart';

class PlayerService {
  final CollectionReference _playerCollection =
      FirebaseFirestore.instance.collection('Player');

  // Oyuncuları getiren fonksiyon
  Future<List<Map<String, dynamic>>> getPlayers() async {
    List<Map<String, dynamic>> players = [];
    try {
      QuerySnapshot snapshot = await _playerCollection.get();
      for (var doc in snapshot.docs) {
        players.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting games: $e');
    }
    return players;
  }

  // Oyuncu ID ile getiren fonksiyon
  Future<Player?> getPlayerById(String playerId) async {
    try {
      QuerySnapshot result =
          await _playerCollection.where('_id', isEqualTo: playerId).get();

      if (result.docs.isEmpty) {
        return null;
      } else {
        return getAllHashMap(result);
      }
    } catch (error) {
      return null;
    }
  }

  // Map Firestore document to Player model
  Player? getAllHashMap(QuerySnapshot result) {
    var document = result.docs.first;
    String createdAt =
        document['_createdAt'] != null ? document['_createdAt'].toString() : '';
    String updateAt =
        document['_updateAt'] != null ? document['_updateAt'].toString() : '';
    String id = document['_id'] != null ? document['_id'] as String : '';
    String name = document['name'] != null ? document['name'] as String : '';
    String surname =
        document['surname'] != null ? document['surname'] as String : '';
    String bio = document['bio'] != null ? document['bio'] as String : '';
    String? imageUrl =
        document['imageUrl'] != null ? document['imageUrl'] as String : null;

    List<dynamic> showIdRaw =
        document['showsId'] != null ? document['showsId'] as List<dynamic> : [];
    List<String> showsId =
        showIdRaw.isNotEmpty ? List<String>.from(showIdRaw) : [];

    return Player(
      createdAt: createdAt,
      updateAt: updateAt,
      id: id,
      name: name,
      surname: surname,
      bio: bio,
      imageUrl: imageUrl,
      showsId: showsId,
    );
  }
}
