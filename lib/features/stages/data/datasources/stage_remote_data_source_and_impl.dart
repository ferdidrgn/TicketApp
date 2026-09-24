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
      // 🔥 DÜZELTME: Firestore 'whereIn' sorgusu en fazla 30 eleman alır —
      // show/event datasource'larındaki aynı düzeltmeyle tutarlı (bkz.
      // show_remote_data_source_and_impl.dart/event_remote_data_source_
      // and_impl.dart). Eski kod tüm `stageIds`'i tek seferde `whereIn`'e
      // gönderiyordu; 30'dan fazla sahne olan bir sorgu (ör. "yakındakiler"
      // özelliğinin geniş bir yarıçapta çok sayıda sahneyi çözmesi
      // gerektiğinde) Firestore'un invalid-argument hatası fırlatmasına ve
      // tüm listenin sessizce boş/hatalı dönmesine yol açabiliyordu.
      const chunkSize = 30;
      final uniqueIds = stageIds.toSet().toList();
      final chunks = <List<String>>[
        for (var i = 0; i < uniqueIds.length; i += chunkSize)
          uniqueIds.sublist(
              i, i + chunkSize > uniqueIds.length ? uniqueIds.length : i + chunkSize),
      ];

      final snapshots = await Future.wait(chunks.map((final chunk) =>
          _stageCollection.where(FieldPath.documentId, whereIn: chunk).get()));

      return snapshots.expand(_mapToStages).toList();
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
