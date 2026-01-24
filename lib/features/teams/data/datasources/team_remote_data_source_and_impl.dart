import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel>> getTeams(final bool isLimit);

  Future<List<TeamModel>> getTeamsByIds(final List<String> teamsIds);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TeamModel>> getTeams(final bool isLimit) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection('Team');

      if (isLimit)
        query = query.orderBy('_createdAt', descending: true).limit(20);

      final snapshot = await query.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  @override
  Future<List<TeamModel>> getTeamsByIds(final List<String> teamsIds) async {
    if (teamsIds.isEmpty) return [];

    try {
      final snapshot = await firestore
          .collection('Team')
          .where(FieldPath.documentId, whereIn: teamsIds)
          .get();

      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Error fetching teams by IDs: $e');
    }
  }

  /// 🔥 Yardımcı Metot: ID enjeksiyonu ve Model Dönüşümü
  List<TeamModel> _mapSnapshot(
      final QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((final doc) {
      final data = doc.data();
      data['_id'] = doc.id;
      return TeamModel.fromFirestore(data);
    }).toList();
  }
}
