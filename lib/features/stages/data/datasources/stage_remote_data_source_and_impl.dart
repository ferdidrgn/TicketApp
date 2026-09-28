import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/stage_model.dart';

abstract class StageRemoteDataSource {
  Future<List<StageModel>> getSearchStage(final String query);

  Future<List<StageModel>> getStages(final bool isLimit);

  Future<List<StageModel>> getStagesByIds(final List<String> stageIds);

  /// ➕ Admin panelinden yeni bir sahne (mekân) oluşturur. `imageFile`
  /// verilirse `show_remote_data_source_and_impl.dart`'taki `addShow` ile
  /// AYNI desende (önce döküman, sonra Storage'a yükleyip `imageUrl`'i
  /// güncelleme) gerçekten Firebase Storage'a yüklenir.
  Future<bool> addStage(final StageModel stage, final File? imageFile);

  /// 🔄 Admin panelinden bir sahneyi günceller (Phase 2). `imageFile`
  /// verilirse `addStage` ile AYNI Storage yoluna (`StageImages/$id.jpg`)
  /// yeniden yüklenir.
  Future<bool> updateStage(final String stageId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir sahneyi siler (Phase 2). `deleteShow` ile
  /// AYNI desen: önce (varsa) Storage'daki görsel silinir, sonra döküman.
  Future<bool> deleteStage(final String stageId);
}

class StageRemoteDataSourceImpl implements StageRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  const StageRemoteDataSourceImpl({
    required final FirebaseFirestore firestore,
    required final FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

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

  @override
  Future<bool> addStage(final StageModel stage, final File? imageFile) async {
    try {
      final data = stage.toFirestore()
        ..['_createdAt'] = FieldValue.serverTimestamp()
        ..['_updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _stageCollection.add(data);
      await docRef.update({'_id': docRef.id});

      if (imageFile != null) {
        final ref = _storage.ref('StageImages/${docRef.id}.jpg');
        await ref.putFile(imageFile);
        final downloadUrl = await ref.getDownloadURL();
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (addStage): ${e.message}');
    } catch (e) {
      throw Exception('Sahne eklenemedi: $e');
    }
  }

  @override
  Future<bool> updateStage(final String stageId,
      final Map<String, dynamic> updatedData, final File? imageFile) async {
    try {
      final data = Map<String, dynamic>.from(updatedData);

      if (imageFile != null) {
        final ref = _storage.ref('StageImages/$stageId.jpg');
        await ref.putFile(imageFile);
        data['imageUrl'] = await ref.getDownloadURL();
      }

      await _stageCollection.doc(stageId).update({
        ...data,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (updateStage): ${e.message}');
    } catch (e) {
      throw Exception('Sahne güncellenemedi: $e');
    }
  }

  @override
  Future<bool> deleteStage(final String stageId) async {
    try {
      try {
        await _storage.ref('StageImages/$stageId.jpg').delete();
      } catch (_) {
        // Resim yoksa hatayı yut, sorun değil (addStage/deleteShow ile aynı desen).
      }
      await _stageCollection.doc(stageId).delete();
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (deleteStage): ${e.message}');
    } catch (e) {
      throw Exception('Sahne silinemedi: $e');
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
