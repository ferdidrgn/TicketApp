import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticketapp/data/model/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel?>> getTeams(final bool isLimit);

  Future<TeamModel?> getTeamById(final String teamId);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeamModel?>> getTeams(final bool isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await firestore
              .collection('Team')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Team').get();

      return snapshot.docs
          .map((final doc) =>
              TeamModel.fromFirestore(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  @override
  Future<TeamModel?> getTeamById(final String teamId) async {
    try {
      final QuerySnapshot result = await firestore
          .collection('Team')
          .where('_id', isEqualTo: teamId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return TeamModel.fromFirestore(
          result.docs.first.data()! as Map<String, dynamic>);
    } catch (error) {
      throw Exception('Error fetching team: $error');
    }
  }
}
