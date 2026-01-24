import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel>> getSearchStage(final String query);
  Future<List<StageModel>> getStages(final bool isLimit);
  Future<List<StageModel>> getStagesByIds(final List<String> stageIds);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Stage';

  const StageRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<StageModel>> getSearchStage(final String query) async {
    if (query.isEmpty) throw Exception('Arama sorgusu boş olamaz.');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

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
      final queryRef = _firestore.collection(_collection);
      final snapshot = isLimit
          ? await queryRef
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await queryRef.get();

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
      final result = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: stageIds)
          .get();

      return _mapToStages(result);
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
