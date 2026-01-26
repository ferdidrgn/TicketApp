import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel>> getSearchStage(final String query);

  Future<List<StageModel>> getStages(final bool isLimit);

  Future<List<StageModel>> getStagesByIds(final List<String> stageIds);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore _firestore;

  const StageRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _stageCollection =>
      _firestore.collection('Stage');

  @override
  Future<List<StageModel>> getSearchStage(final String query) async {
    try {
      final firebaseQuery = await _stageCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff');

      final snapshot = await firebaseQuery.get();
      return _mapToStages(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getSearchStage): ${e.message}');
    } catch (e) {
      throw Exception('Sahneler alınamadı: $e');
    }
  }

  @override
  Future<List<StageModel>> getStages(final bool isLimit) async {
    try {
      var query = _stageCollection.orderBy('_createdAt', descending: true);
      if (isLimit) query = query.limit(20);

      final snapshot = await query.get();
      return _mapToStages(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getStages): ${e.message}');
    } catch (e) {
      throw Exception('Sahneler alınamadı: $e');
    }
  }

  @override
  Future<List<StageModel>> getStagesByIds(final List<String> stageIds) async {
    if (stageIds.isEmpty) return [];

    try {
      final snapshot = await _stageCollection
          .where(FieldPath.documentId, whereIn: stageIds)
          .get();

      return _mapToStages(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getStagesByIds): ${e.message}');
    } catch (e) {
      throw Exception('Belirtilen sahneler alınamadı: $e');
    }
  }

  List<StageModel> _mapToStages(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return StageModel.fromFirestore(data);
      }).toList();
}
