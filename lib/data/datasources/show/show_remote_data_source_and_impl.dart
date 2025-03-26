import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/show_model.dart';

abstract class ShowRemoteDataSource {
  Future<List<ShowModel?>?> getSearchShow(final List<String> categories,
      final String? type);

  Future<List<ShowModel?>?> getShows(isLimit);

  Future<List<ShowModel?>?> getShowsByIds(final List<String> showsIds);

  Future<void> addShow(final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);

  Future<void> deleteShow(final String showId);

  Future<void> updateShow(final String showId, final Map<String, dynamic> updatedData);
}

class ShowRemoteDataSourceImpl implements ShowRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ShowRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<ShowModel?>?> getSearchShow(final List<String> categories,
      final String? type) async {
    try {
      Query query = firestore.collection('Show');

      if (categories.isEmpty && type == null)
        return getShows(false);
      else {
        if (categories.isNotEmpty)
          query = query.where('category', whereIn: categories);

        if (type != null && type.isNotEmpty)
          query = query.where('type', isEqualTo: type);

        final result = await query.get();

        if (result.docs.isEmpty) return [];
        return result.docs
            .map((final e) =>
            ShowModel.fromFirestore(e.data()! as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      throw Exception('Search Error: $e');
    }
  }

  @override
  Future<List<ShowModel?>?> getShows(isLimit) async {
    try {
      final snapshot = isLimit
          ? await firestore
          .collection('Show')
          .orderBy('_createdAt', descending: true)
          .limit(20)
          .get()
          : await firestore.collection('Show').get();

      if (snapshot.docs.isEmpty) return [];
      return _convertQuerySnapshotToShowList(snapshot);
    } catch (e) {
      throw Exception('Error fetching shows: $e');
    }
  }

  @override
  Future<List<ShowModel?>?> getShowsByIds(final List<String> showsIds) async {
    try {
      if (showsIds.isEmpty) throw Exception('Shows IDs cannot be empty.');

      // Firestore'dan birden fazla gösteriyi tek bir istekle çekmek
      final snapshots = await firestore
          .collection('Show')
          .where(FieldPath.documentId, whereIn: showsIds)
          .get();

      if (snapshots.docs.isEmpty) return [];
      return _convertQuerySnapshotToShowList(snapshots);
    } catch (e) {
      throw Exception('Error fetching shows ids: $e');
    }
  }

  @override
  Future<void> addShow(final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) async {

    if (show.id == null || show.id!.isEmpty) {
      final String downloadUrl = await putStorageImage(
          show.id, showIdAddOrUpdateImgUrl, show.imageUrl);

      final Map<String, dynamic> showMap = show.toFirestore()
        ..['imageUrl'] = downloadUrl;

      await firestore.collection('Show').add(showMap).catchError((final error) {
        throw Exception('Error adding show: $error');
      });
    }
  }

  @override
  Future<void> deleteShow(final String showId) async {
    try {
      final QuerySnapshot showQuery = await firestore
          .collection('Show')
          .where(FieldPath.documentId, isEqualTo: showId)
          .get();

      if (showQuery.docs.isNotEmpty)
        for (final document in showQuery.docs) {
          await firestore.collection('Show').doc(document.id).delete();
          await deleteStorageImage(showId ?? '');
        }
    } catch (e) {
      throw Exception('Error deleting show: $e');
    }
  }

  @override
  Future<void> updateShow(final String showId,
      final Map<String, dynamic> updatedData) async {
    await firestore.collection('Show').doc(showId).update({
      ...updatedData,
      '_updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> putStorageImage(final String? showId,
      final Uri? showIdAddOrUpdateImgUrl, final String? showIdImgUrl) async {
    if (showId == null || showId.isEmpty) return '';
    final String imageName = "ShowImages/$showId.jpg";
    final Reference imagesRef = storage.ref().child(imageName);
    String downloadUrl = '';

    if (showIdAddOrUpdateImgUrl != null) {
      await imagesRef.putFile(File.fromUri(showIdAddOrUpdateImgUrl));
      downloadUrl = await imagesRef.getDownloadURL();
    }

    return (downloadUrl.isEmpty ? showIdImgUrl : downloadUrl) ?? '';
  }

  Future<void> deleteStorageImage(final String showId) async {
    final String imageName = "ShowImages/$showId.jpg";
    final Reference imagesRef = storage.ref().child(imageName);

    try {
      await imagesRef.delete();
    } catch (e) {
      throw Exception('Error deleting image: $e');
    }
  }

  // Convert Firestore document to Show model
  List<ShowModel> _convertQuerySnapshotToShowList(
      final QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((final doc) => ShowModel.fromFirestore(doc.data()))
        .toList();
  }
}
