import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/player.dart';

class PlayerService {
  final CollectionReference _playerCollection =
      FirebaseFirestore.instance.collection('Player');

  //all players
  Future<List<Player?>> getPlayers() async {
    try {
      QuerySnapshot snapshot = await _playerCollection.get();
      return snapshot.docs.map((doc) => _mapDocumentToPlayer(doc)).toList();
    } catch (e) {
      SnackBar(content: Text('Error fetching players: $e'));
    }
    return [];
  }

  // player by ID
  Future<Player?> getPlayerById(String playerId) async {
    try {
      QuerySnapshot result =
          await _playerCollection.where('_id', isEqualTo: playerId).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToPlayer(result.docs.first);
    } catch (error) {
      SnackBar(content: Text('Error fetching players: $error'));
      return null;
    }
  }

  // Convert Firestore document to Player model
  Player _mapDocumentToPlayer(DocumentSnapshot document) {
    return Player(
      createdAt: _getStringField(document, '_createdAt'),
      updateAt: _getStringField(document, '_updateAt'),
      id: _getStringField(document, '_id'),
      name: _getStringField(document, 'name'),
      surname: _getStringField(document, 'surname'),
      bio: _getStringField(document, 'bio'),
      imageUrl: _getStringField(document, 'imageUrl'),
      showsId: _getListField(document, 'showsId'),
    );
  }

  String _getStringField(DocumentSnapshot document, String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(DocumentSnapshot document, String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
