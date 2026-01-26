import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel>> getTeams(final bool isLimit);
  Future<List<TeamModel>> getTeamsByIds(final List<String> teamsIds);
  Future<List<TeamModel>> searchTeams(final String query);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _teamCollection =>
      firestore.collection('Team');

  @override
  Future<List<TeamModel>> getTeams(final bool isLimit) async {
    try {
      var query = _teamCollection.orderBy('_createdAt', descending: true);
      if (isLimit) query = query.limit(20);

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
      final snapshot = await _teamCollection
          .where(FieldPath.documentId, whereIn: teamsIds)
          .get();

      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Error fetching teams by IDs: $e');
    }
  }

  @override
  Future<List<TeamModel>> searchTeams(final String query) async {
    try {
      final firebaseQuery = _teamCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff');

      final snapshot = await firebaseQuery.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Error searching teams: $e');
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
