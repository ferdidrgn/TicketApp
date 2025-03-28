import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel?>?> getTeams(final isLimit);
  Future<List<TeamModel?>?> getTeamsByIds(final List<String> teamsIds);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeamModel?>?> getTeams(final isLimit) async {
    try {
      final snapshot = isLimit
          ? await firestore
          .collection('Team')
          .orderBy('_createdAt', descending: true)
          .limit(20)
          .get()
          : await firestore.collection('Team').get();

      if (snapshot.docs.isEmpty) return [];
      return snapshot.docs.map((final doc) {
        return TeamModel.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  @override
  Future<List<TeamModel?>?> getTeamsByIds(final List<String> teamsIds) async {

    try {
      if (teamsIds.isEmpty) throw Exception('Team ID cannot be empty.');

      final result = await firestore
          .collection('Team')
          .where(FieldPath.documentId, whereIn: teamsIds)
          .get();

      if (result.docs.isEmpty) return null;
      return result.docs.map((final doc) {
        return TeamModel.fromFirestore(doc.data());
      }).toList();
    } catch (error) {
      throw Exception('Error fetching team: $error');
    }
  }

}
