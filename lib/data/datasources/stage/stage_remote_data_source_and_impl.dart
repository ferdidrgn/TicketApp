import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel?>?> getSearchStage(final String query);
  Future<List<StageModel?>?> getStages(final isLimit);
  Future<List<StageModel?>?> getStagesByIds(final List<String> stagesIds);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore firestore;

  StageRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<StageModel?>?> getSearchStage(final String query) async {

    try {
      if (query.isEmpty) throw Exception('Query cannot be empty.');

      final snapshot = await firestore
          .collection('Stage')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      if (snapshot.docs.isEmpty) return [];
      return _convertQuerySnapshotToStageList(snapshot);
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  @override
  Future<List<StageModel?>?> getStages(final isLimit) async {
    try {
      final snapshot = isLimit
          ? await firestore
          .collection('Stage')
          .orderBy('_createdAt', descending: true)
          .limit(20)
          .get()
          : await firestore.collection('Stage').get();

      if (snapshot.docs.isEmpty) return [];
      return _convertQuerySnapshotToStageList(snapshot);
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  @override
  Future<List<StageModel?>?> getStagesByIds(final List<String> stagesIds) async {

    try {
      if (stagesIds.isEmpty) throw Exception('Stage ID cannot be empty.');

      final result = await firestore
          .collection('Stage')
          .where(FieldPath.documentId, whereIn: stagesIds)
          .get();

      if (result.docs.isEmpty) return [];
      return _convertQuerySnapshotToStageList(result);
    } catch (error) {
      throw Exception('Error fetching stage: $error');
    }
  }

// Convert Firestore document to StageModel
  List<StageModel> _convertQuerySnapshotToStageList(
      final QuerySnapshot snapshot) {
    return snapshot.docs.map((final doc) {
      return StageModel.fromFirestore(doc.data()! as Map<String, dynamic>);
    }).toList();
  }
}
