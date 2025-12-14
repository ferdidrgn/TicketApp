import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/features/teams/data/models/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel?>?> getTeams(final bool isLimit);

  Future<List<TeamModel?>?> getTeamsByIds(final List<String> teamsIds);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeamModel?>?> getTeams(final bool isLimit) async {
    try {
      final snapshot = isLimit
          ? await firestore
              .collection('Team')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Team').get();

      return _convertQuerySnapshotToTeamList(snapshot);
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  @override
  Future<List<TeamModel?>?> getTeamsByIds(final List<String> teamsIds) async {
    try {
      if (teamsIds.isEmpty) return [];

      final result = await firestore
          .collection('Team')
          .where(FieldPath.documentId, whereIn: teamsIds)
          .get();

      return _convertQuerySnapshotToTeamList(result);
    } catch (e) {
      throw Exception('Error fetching teams by IDs: $e');
    }
  }

  List<TeamModel> _convertQuerySnapshotToTeamList(
      final QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs
        .map((final doc) =>
            TeamModel.fromFirestore(doc.data()! as Map<String, dynamic>))
        .toList();
  }
}
