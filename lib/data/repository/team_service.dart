import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/team.dart';

class TeamService {
  final CollectionReference _teamCollection =
      FirebaseFirestore.instance.collection('Team');

  // all teams
  Future<List<Team?>> getTeams(final isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await _teamCollection
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await _teamCollection.get();
      return snapshot.docs.map((final doc) => _mapDocumentToTeam(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  // Fetch a teams by ID
  Future<Team?> getTeamById(final String teamId) async {
    try {
      final QuerySnapshot result =
          await _teamCollection.where('_id', isEqualTo: teamId).limit(1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToTeam(result.docs.first);
    } catch (error) {
      throw Exception('Error fetching team: $error');
    }
  }

  // Convert Firestore document to Team model
  Team _mapDocumentToTeam(final DocumentSnapshot document) {
    return Team(
      id: _getStringField(document, '_id'),
      createdAt: _getStringField(document, '_createdAt'),
      updatedAt: _getStringField(document, '_updatedAt'),
      name: _getStringField(document, 'name'),
      imageUrl: _getStringField(document, 'imageUrl'),
      description: _getStringField(document, 'description'),
      showsId: _getListField(document, 'showsId'),
      photosId: _getListField(document, 'photosId'),
    );
  }

  // Utility method for fetching string fields
  String _getStringField(final DocumentSnapshot document, final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(final DocumentSnapshot document, final String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
