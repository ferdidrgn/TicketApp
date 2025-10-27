import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/show_model.dart';

abstract class ShowRemoteDataSource {
  Future<List<ShowModel?>?> getSearchShow(
      final List<String> categories, final String? type);

  Future<List<ShowModel?>?> getShows(final bool isLimit);

  Future<List<ShowModel?>?> getShowsByIds(final List<String> showIds);

  Future<bool> addShow(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);

  Future<bool> deleteShow(final String showId);

  Future<bool> updateShow(
      final String showId, final Map<String, dynamic> updatedData);
}

class ShowRemoteDataSourceImpl implements ShowRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ShowRemoteDataSourceImpl({required this.firestore, required this.storage});

  @override
  Future<List<ShowModel?>?> getSearchShow(
      final List<String> categories, final String? type) async {
    try {
      Query query = firestore.collection('Show');

      if (categories.isNotEmpty)
        query = query.where('category', whereIn: categories);
      if (type?.isNotEmpty ?? false)
        query = query.where('type', isEqualTo: type);

      final snapshot = await (query.get());
      return _toShowList(snapshot);
    } catch (e) {
      throw Exception('Search Error: $e');
    }
  }

  @override
  Future<List<ShowModel?>?> getShows(final bool isLimit) async {
    try {
      final snapshot = isLimit
          ? await firestore
              .collection('Show')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Show').get();
      return _toShowList(snapshot);
    } catch (e) {
      throw Exception('Error fetching shows: $e');
    }
  }

  @override
  Future<List<ShowModel?>?> getShowsByIds(final List<String> showsIds) async {
    try {
      final snapshot = await firestore
          .collection('Show')
          .where(FieldPath.documentId, whereIn: showsIds)
          .get();
      return _toShowList(snapshot);
    } catch (e) {
      throw Exception('Error fetching shows by IDs: $e');
    }
  }

  @override
  Future<bool> addShow(final ShowModel show, final Uri? imageUri) async {
    try {
      // 1. Önce veriyi ekle
      final data = show.toFirestore();
      final docRef = await firestore.collection('Show').add(data);

      // 2. Fotoğraf varsa yükle ve downloadUrl güncelle
      if (imageUri != null) {
        final downloadUrl =
            await _uploadImage(docRef.id, imageUri, show.imageUrl);
        await docRef.update({'imageUrl': downloadUrl});
      }

      return true;
    } catch (e) {
      print('Add show error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteShow(final String showId) async {
    try {
      // 1. Fotoğrafı sil
      final imageDeleted = await _deleteImage(showId);
      if (!imageDeleted) return false; // Foto silinemedi, veri silinmesin

      // 2. Veri sil
      final docRef = firestore.collection('Show').doc(showId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;

      await docRef.delete();
      return true;
    } catch (e) {
      print('Delete show error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    try {
      final docRef = firestore.collection('Show').doc(showId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;

      await docRef.update({
        ...updatedData,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Update show error: $e');
      return false;
    }
  }

  // Storage işlemleri
  Future<String> _uploadImage(final String showId, final Uri? imageUri,
      final String? currentUrl) async {
    if (imageUri == null) return currentUrl ?? '';
    final ref = storage.ref().child("ShowImages/$showId.jpg");
    await ref.putFile(File.fromUri(imageUri));
    return await ref.getDownloadURL();
  }

  Future<bool> _deleteImage(final String showId) async {
    try {
      await storage.ref().child("ShowImages/$showId.jpg").delete();
      return true; // Silme başarılı
    } catch (e) {
      print('Image delete failed: $e');
      return false;
    }
  }

  // Helper
  List<ShowModel> _toShowList(final QuerySnapshot snapshot) => snapshot.docs
      .map((final doc) =>
          ShowModel.fromFirestore(doc.data() as Map<String, dynamic>))
      .toList();
}
