import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/show_model.dart';

abstract class ShowRemoteDataSource {
  Future<List<ShowModel?>> getSearchShow(
      final List<String?> categories, final String? type);

  Future<List<ShowModel?>> getShows(final isLimit);

  Future<ShowModel?> getShowById(final String showId);

  Future<void> addShow(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);

  Future<void> deleteShow(final String? showId);

  Future<void> updateShow(
      final String showId, final Map<String, dynamic> updatedData);
}

class ShowRemoteDataSourceImpl implements ShowRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ShowRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<ShowModel?>> getSearchShow(
      final List<String?> categories, final String? type) async {
    try {
      Query query = firestore.collection('Show');

      if (categories.isEmpty && type == null) {
        return getShows(false);
      } else {
        if (categories.isNotEmpty) {
          query = query.where('category', whereIn: categories);
        }

        if (type != null && type.isNotEmpty) {
          query = query.where('type', isEqualTo: type);
        }

        final QuerySnapshot result = await query.get();
        return result.docs
            .map((final e) =>
                ShowModel.fromFirestore(e.data()! as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      throw Exception('Arama Hatası: $e');
    }
  }

  @override
  Future<List<ShowModel?>> getShows(final isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await firestore
              .collection('Show')
              .orderBy('_createdAt', descending: true)
              .limit(20)
              .get()
          : await firestore.collection('Show').get();

      return snapshot.docs
          .map((final doc) =>
              ShowModel.fromFirestore(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Oyunları Getirme Hatası: $e');
    }
  }

  @override
  Future<ShowModel?> getShowById(final String showId) async {
    try {
      final QuerySnapshot result = await firestore
          .collection('Show')
          .where('_id', isEqualTo: showId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return ShowModel.fromFirestore(
          result.docs.first.data()! as Map<String, dynamic>);
    } catch (error) {
      throw Exception('Gösterileri Getirme Hatası: $error');
    }
  }

  @override
  Future<void> addShow(
     
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) async {
    final String downloadUrl =
        await putStorageImage(show.id, showIdAddOrUpdateImgUrl, show.imageUrl);
    final Map<String, dynamic> showMap = show.toFirestore()
      ..['imageUrl'] = downloadUrl;

    await firestore.collection('Show').add(showMap).catchError((final error) {
      throw Exception('Show Ekleme Hatası: $error');
    });
  }

  @override
  Future<void> deleteShow(final String? showId) async {
    try {
      final QuerySnapshot showQuery = await firestore
          .collection('Show')
          .where('_id', isEqualTo: showId)
          .get();

      if (showQuery.docs.isNotEmpty) {
        for (final document in showQuery.docs) {
          try {
            await firestore.collection('Show').doc(document.id).delete();
            await deleteStorageImage(showId ?? '');
          } catch (e) {
            throw Exception('Silme işleminde bir hata oluştu: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Silme işleminde bir hata oluştu: $e');
    }
  }

  @override
  Future<void> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    await firestore.collection('Show').doc(showId).update({
      ...updatedData,
      '_updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> putStorageImage(final String showId,
      final Uri? showIdAddOrUpdateImgUrl, final String showIdImgUrl) async {
    final String imageName = "ShowImages/$showId.jpg";
    final Reference imagesRef = storage.ref().child(imageName);
    String downloadUrl = '';

    if (showIdAddOrUpdateImgUrl != null) {
      await imagesRef.putFile(File.fromUri(showIdAddOrUpdateImgUrl));
      downloadUrl = await imagesRef.getDownloadURL();
    }

    return downloadUrl.isEmpty ? showIdImgUrl : downloadUrl;
  }

  Future<void> deleteStorageImage(final String showId) async {
    final String imageName = "ShowImages/$showId.jpg";
    final Reference imagesRef = storage.ref().child(imageName);

    try {
      await imagesRef.delete();
    } catch (e) {
      throw Exception('Resim silinirken bir hata oluştu: $e');
    }
  }
}
