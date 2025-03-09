import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel?>> getSearchStage(final String query);

  Future<List<StageModel?>> getStages(final isLimit);

  Future<StageModel?> getStageById(final String stageId);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore firestore;

  StageRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<StageModel?>> getSearchStage(final String query) async {
    try {
      final QuerySnapshot snapshot = await firestore
          .collection('Stage')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((final doc) =>
              StageModel.fromFirestore(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  @override
  Future<List<StageModel?>> getStages(final isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await firestore
              .collection('Stage')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Stage').get();

      return snapshot.docs
          .map((final doc) =>
              StageModel.fromFirestore(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  @override
  Future<StageModel?> getStageById(final String stageId) async {
    try {
      final QuerySnapshot result = await firestore
          .collection('Stage')
          .where('_id', isEqualTo: stageId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return StageModel.fromFirestore(
          result.docs.first.data()! as Map<String, dynamic>);
    } catch (error) {
      throw Exception('Error fetching stage: $error');
    }
  }
}
