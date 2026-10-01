import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/team_model.dart';

abstract class TeamRemoteDataSource {
  Future<List<TeamModel>> getTeams(final bool isLimit);
  Future<List<TeamModel>> getTeamsByIds(final List<String> teamsIds);
  Future<List<TeamModel>> searchTeams(final String query);

  /// ➕ Admin panelinden yeni bir topluluk (Team) oluşturur.
  Future<bool> addTeam(final TeamModel team, final File? imageFile);

  /// 🔄 Admin panelinden bir topluluğu günceller (Phase 2).
  Future<bool> updateTeam(final String teamId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir topluluğu siler (Phase 2).
  Future<bool> deleteTeam(final String teamId);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  TeamRemoteDataSourceImpl({required this.firestore, required this.storage});

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

  @override
  Future<bool> addTeam(final TeamModel team, final File? imageFile) async {
    try {
      final data = team.toFirestore()
        ..['_createdAt'] = FieldValue.serverTimestamp()
        ..['_updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _teamCollection.add(data);
      await docRef.update({'_id': docRef.id});

      if (imageFile != null) {
        final ref = storage.ref('TeamImages/${docRef.id}.jpg');
        await ref.putFile(imageFile);
        final downloadUrl = await ref.getDownloadURL();
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } catch (e) {
      throw Exception('Error adding team: $e');
    }
  }

  @override
  Future<bool> updateTeam(final String teamId,
      final Map<String, dynamic> updatedData, final File? imageFile) async {
    try {
      final data = Map<String, dynamic>.from(updatedData);

      if (imageFile != null) {
        final ref = storage.ref('TeamImages/$teamId.jpg');
        await ref.putFile(imageFile);
        data['imageUrl'] = await ref.getDownloadURL();
      }

      await _teamCollection.doc(teamId).update({
        ...data,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Error updating team: $e');
    }
  }

  @override
  Future<bool> deleteTeam(final String teamId) async {
    try {
      try {
        await storage.ref('TeamImages/$teamId.jpg').delete();
      } catch (_) {
        // Resim yoksa hatayı yut, sorun değil.
      }
      await _teamCollection.doc(teamId).delete();
      return true;
    } catch (e) {
      throw Exception('Error deleting team: $e');
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
