import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel?>?> getSearchStage(final String query);

  Future<List<StageModel?>?> getStages(final bool isLimit);

  Future<List<StageModel?>?> getStagesByIds(final List<String> stageIds);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Stage';

  const StageRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<StageModel?>?> getSearchStage(final String query) async {
    if (query.isEmpty) throw Exception('Arama sorgusu boş olamaz.');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.isEmpty ? [] : _mapToStages(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getSearchStage): ${e.message}');
    } catch (e) {
      throw Exception('Sahneler alınamadı: $e');
    }
  }

  @override
  Future<List<StageModel?>?> getStages(final bool isLimit) async {
    try {
      final query = _firestore.collection(_collection);
      final snapshot = isLimit
          ? await query.orderBy('_createdAt', descending: true).limit(20).get()
          : await query.get();

      return snapshot.docs.isEmpty ? [] : _mapToStages(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getStages): ${e.message}');
    } catch (e) {
      throw Exception('Sahneler alınamadı: $e');
    }
  }

  @override
  Future<List<StageModel?>?> getStagesByIds(final List<String> stageIds) async {
    try {
      if (stageIds.isEmpty) throw Exception('Stage ID cannot be empty.');

      final result = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: stageIds)
          .get();

      return result.docs.isEmpty ? [] : _mapToStages(result);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getStagesByIds): ${e.message}');
    } catch (e) {
      throw Exception('Belirtilen sahneler alınamadı: $e');
    }
  }

  /// Firestore belgelerini [StageModel] listesine dönüştürür
  List<StageModel> _mapToStages(final QuerySnapshot snapshot) => snapshot.docs
      .map((final doc) =>
          StageModel.fromFirestore(doc.data()! as Map<String, dynamic>))
      .toList();
}
