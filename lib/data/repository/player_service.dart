import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Oyuncuları getiren fonksiyon
  Future<List<Map<String, dynamic>>> getPlayers() async {
    List<Map<String, dynamic>> players = [];
    try {
      QuerySnapshot snapshot = await _firestore.collection('Player').get();
      for (var doc in snapshot.docs) {
        players.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting games: $e');
    }
    return players;
  }

  // Oyuncu ID ile getiren fonksiyon
  Future<Map<String, dynamic>?> getPlayerById(String playerId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Player').doc(playerId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting player: $e');
      return null;
    }
  }
}
