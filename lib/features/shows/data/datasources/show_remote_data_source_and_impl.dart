import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/show_model.dart';

abstract class ShowRemoteDataSource {
  Future<List<ShowModel>> getSearchShow(
      final String? query, final List<String> categories, final String? type);

  Future<List<ShowModel>> getShows(final bool isLimit);

  Future<List<ShowModel>> getShowsByIds(final List<String> showIds);

  Future<bool> addShow(final ShowModel show, final File? imageFile);

  Future<bool> deleteShow(final String showId);

  Future<bool> updateShow(
      final String showId, final Map<String, dynamic> updatedData);
}

class ShowRemoteDataSourceImpl implements ShowRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ShowRemoteDataSourceImpl({required this.firestore, required this.storage});

  CollectionReference<Map<String, dynamic>> get _showCollection =>
      firestore.collection('Show');

  @override
  Future<List<ShowModel>> getSearchShow(final String? query,
      final List<String> categories, final String? type) async {
    try {
      var firebaseQuery = _showCollection as Query<Map<String, dynamic>>;

      if (query != null && query.isNotEmpty) {
        firebaseQuery = firebaseQuery
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\uf8ff');
      }

      if (categories.isNotEmpty)
        firebaseQuery = firebaseQuery.where('category', whereIn: categories);

      if (type != null && type.isNotEmpty)
        firebaseQuery = firebaseQuery.where('type', isEqualTo: type);

      final snapshot = await firebaseQuery.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      // BaseRepository yakalayacağı için hatayı fırlatıyoruz
      throw Exception('Search shows failed: $e');
    }
  }

  @override
  Future<List<ShowModel>> getShows(final bool isLimit) async {
    try {
      var query = _showCollection.orderBy('_createdAt', descending: true);
      if (isLimit) query = query.limit(20);

      final snapshot = await query.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Fetch shows failed: $e');
    }
  }

  @override
  Future<List<ShowModel>> getShowsByIds(final List<String> showIds) async {
    if (showIds.isEmpty) return [];
    try {
      // 🔥 DÜZELTME: Firestore 'whereIn' sorgusu en fazla 30 eleman alır.
      // Bir oyuncunun/mekanın 30'dan fazla eski/aktif gösterisi olduğunda
      // eski kod tek seferde whereIn'e >30 ID gönderip Firestore'un
      // invalid-argument hatası fırlatmasına ve tüm sayfanın kilitlenmesine
      // sebep oluyordu. Artık ID listesi 30'luk parçalara bölünüp paralel
      // çekiliyor, tekil bir parçanın (veya tamamının) başarısız olması
      // diğer parçaları etkilemez.
      const chunkSize = 30;
      final uniqueIds = showIds.toSet().toList();
      final chunks = <List<String>>[
        for (var i = 0; i < uniqueIds.length; i += chunkSize)
          uniqueIds.sublist(
              i, i + chunkSize > uniqueIds.length ? uniqueIds.length : i + chunkSize),
      ];

      final snapshots = await Future.wait(chunks.map((final chunk) =>
          _showCollection.where(FieldPath.documentId, whereIn: chunk).get()));

      return snapshots.expand(_mapSnapshot).toList();
    } catch (e) {
      throw Exception('Fetch shows by IDs failed: $e');
    }
  }

  @override
  Future<bool> addShow(final ShowModel show, final File? imageFile) async {
    try {
      // 1. Dökümanı oluştur (ID otomatik)
      final docRef = await _showCollection.add(show.toFirestore());

      // 2. ID'yi güncelle
      await docRef.update({'_id': docRef.id});

      // 3. Resim varsa yükle ve güncelle
      if (imageFile != null) {
        final downloadUrl = await _uploadImage(docRef.id, imageFile);
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } catch (e) {
      throw Exception('Add show failed: $e');
    }
  }

  @override
  Future<bool> deleteShow(final String showId) async {
    try {
      await _deleteImage(showId);
      await _showCollection.doc(showId).delete();
      return true;
    } catch (e) {
      throw Exception('Delete show failed: $e');
    }
  }

  @override
  Future<bool> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    try {
      await _showCollection.doc(showId).update({
        ...updatedData,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Update show failed: $e');
    }
  }

  // --- Helpers ---

  List<ShowModel> _mapSnapshot(
      final QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((final doc) {
      final data = doc.data();
      // ID'yi dökümandan garanti altına alıyoruz
      data['_id'] = doc.id;
      return ShowModel.fromFirestore(data);
    }).toList();
  }

  Future<String> _uploadImage(final String showId, final File imageFile) async {
    final ref = storage.ref('ShowImages/$showId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _deleteImage(final String showId) async {
    try {
      await storage.ref('ShowImages/$showId.jpg').delete();
    } catch (_) {
      // Resim yoksa hatayı yut, sorun değil.
    }
  }
}
