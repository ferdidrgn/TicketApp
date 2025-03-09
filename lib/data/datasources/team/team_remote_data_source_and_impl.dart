import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/team.dart';

abstract class TeamRemoteDataSource {

  Future<List<Team?>> getTeams(final isLimit);
  Future<Team?> getTeamById(final String teamId);

}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<Team?>> getTeams(final isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await firestore.collection('Team')
          .orderBy('_createdAt', descending: true)
          .limit(20)
          .get()
          : await firestore.collection('Team').get();
      return snapshot.docs.map((final doc) => _mapDocumentToTeam(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  @override
  Future<Team?> getTeamById(final String teamId) async {
    try {
      final QuerySnapshot result =
      await firestore.collection('Team').where('_id', isEqualTo: teamId).limit(
          1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToTeam(result.docs.first);
    } catch (error) {
      throw Exception('Error fetching team: $error');
    }
  }

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

  String _getStringField(final DocumentSnapshot document,
      final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(final DocumentSnapshot document,
      final String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
