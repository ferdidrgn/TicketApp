import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/show_model.dart';

abstract class ShowRemoteDataSource {
  Future<List<ShowModel>> getSearchShow(
      final List<String> categories, final String? type);

  Future<List<ShowModel>> getShows(final bool isLimit);

  Future<List<ShowModel>> getShowsByIds(final List<String> showIds);

  Future<bool> addShow(final ShowModel show, final Uri? imageUri);

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
  Future<List<ShowModel>> getSearchShow(
      final List<String> categories, final String? type) async {
    try {
      var query = _showCollection as Query<Map<String, dynamic>>;
      if (categories.isNotEmpty)
        query = query.where('category', whereIn: categories);
      if (type?.isNotEmpty ?? false)
        query = query.where('type', isEqualTo: type);

      final snapshot = await query.get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Search shows failed: $e');
    }
  }

  @override
  Future<List<ShowModel>> getShows(final bool isLimit) async {
    try {
      final query = _showCollection.orderBy('_createdAt', descending: true);
      final snapshot =
          isLimit ? await query.limit(20).get() : await query.get();
      final result = _mapSnapshot(snapshot);
      return result;
    } catch (e) {
      throw Exception('Fetch shows failed: $e');
    }
  }

  @override
  Future<List<ShowModel>> getShowsByIds(final List<String> showIds) async {
    if (showIds.isEmpty) return [];
    try {
      final snapshot = await _showCollection
          .where(FieldPath.documentId, whereIn: showIds)
          .get();
      return _mapSnapshot(snapshot);
    } catch (e) {
      throw Exception('Fetch shows by IDs failed: $e');
    }
  }

  @override
  Future<bool> addShow(final ShowModel show, final Uri? imageUri) async {
    try {
      final docRef = await _showCollection.add(show.toFirestore());

      if (imageUri != null) {
        final downloadUrl = await _uploadImage(docRef.id, imageUri);
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } catch (e) {
      print('Add show failed: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteShow(final String showId) async {
    try {
      final docRef = _showCollection.doc(showId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;

      await _deleteImage(showId);
      await docRef.delete();
      return true;
    } catch (e) {
      print('Delete show failed: $e');
      return false;
    }
  }

  @override
  Future<bool> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    try {
      final docRef = _showCollection.doc(showId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;

      await docRef.update({
        ...updatedData,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Update show failed: $e');
      return false;
    }
  }

  /// --- Private helpers ---

  Future<String> _uploadImage(final String showId, final Uri imageUri) async {
    final ref = storage.ref('ShowImages/$showId.jpg');
    await ref.putFile(File.fromUri(imageUri));
    return ref.getDownloadURL();
  }

  Future<void> _deleteImage(final String showId) async {
    try {
      await storage.ref('ShowImages/$showId.jpg').delete();
    } catch (_) {
      // Eğer resim yoksa hata bastırılır (örneğin zaten silinmişse)
    }
  }

  List<ShowModel> _mapSnapshot(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((final doc) => ShowModel.fromFirestore(doc.data()))
          .toList();
}
