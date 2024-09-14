import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../model/show.dart';

class ShowService {
  final CollectionReference _showCollection =
      FirebaseFirestore.instance.collection('Show');

  // search show
  Future<List<Show?>> getSearchShow(String query) async {
    try {
      QuerySnapshot result = await _showCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return result.docs.map((e) => _mapDocumentToShow(e)).toList();
    } catch (e) {
      throw Exception('Arama Hatası: $e');
    }
  }

  // Tüm Oyunları getiren fonksiyon
  Future<List<Show?>> getShows(bool isLimit) async {
    try {
      QuerySnapshot snapshot = isLimit
          ? await _showCollection.get()
          : await _showCollection.orderBy('createdAt', descending: true).limit(20).get();
      return snapshot.docs.map((doc) => _mapDocumentToShow(doc)).toList();
    } catch (e) {
      throw Exception('Oyunları Getirme Hatası: $e');
    }
  }

  // Show ID ile gösterileri getiren fonksiyon
  Future<Show?> getShowById(String showId) async {
    try {
      QuerySnapshot result =
          await _showCollection.where('_id', isEqualTo: showId).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToShow(result.docs.first);
    } catch (error) {
      throw Exception('Gösterileri Getirme Hatası: $error');
    }
  }

// Show kaydetme fonksiyonu
  Future<void> addShow(Show show, Uri? showIdAddOrUpdateImgUrl) async {
    String downloadUrl = await putStorageImage(
      show.id ?? '',
      showIdAddOrUpdateImgUrl,
      show.imageUrl ?? '',
    );

    Map<String, dynamic> showMap = putHashMap(show, downloadUrl, false);

    _showCollection.add(showMap).then((value) {
      true;
    }).catchError((error) {
      throw Exception('Show Ekleme Hatası: $error');
    });
  }

  // Show silme fonksiyonu
  Future<void> deleteShow(String? showId) async {
    try {
      QuerySnapshot showQuery =
          await _showCollection.where('_id', isEqualTo: showId).get();

      if (showQuery.docs.isNotEmpty) {
        for (var document in showQuery.docs) {
          try {
            await _showCollection.doc(document.id).delete();

            // Storage'daki resmi sil
            await deleteStorageImage(showId ?? '');
            true;
          } catch (e) {
            throw Exception('Silme işleminde bir hata oluştu: $e');
          }
        }
      } else {
        false;
      }
    } catch (e) {
      throw Exception('Silme işleminde bir hata oluştu: $e');
    }
  }

// Show güncelleme fonksiyonu
  Future<void> updateShow(
      String showId, Map<String, dynamic> updatedData) async {
    await _showCollection.doc(showId).update({
      ...updatedData, // Güncellenen veriler
      '_updatedAt': FieldValue.serverTimestamp(), // Güncelleme zamanı
    });
  }

  Future<String> putStorageImage(
    String showId,
    Uri? showIdAddOrUpdateImgUrl,
    String showIdImgUrl,
  ) async {
    final String imageName = "ShowImages/$showId.jpg";
    final Reference imagesRef = FirebaseStorage.instance.ref().child(imageName);
    String downloadUrl = '';

    if (showIdAddOrUpdateImgUrl != null) {
      // Dosyayı Firebase Storage'a yükleme
      await imagesRef.putFile(File.fromUri(showIdAddOrUpdateImgUrl));

      // Yüklenen dosyanın indirme URL'sini alma
      downloadUrl = await imagesRef.getDownloadURL();
    }

    // Eğer yeni URL alınmadıysa eski URL'yi kullan
    return downloadUrl.isEmpty ? showIdImgUrl : downloadUrl;
  }

  Future<void> deleteStorageImage(String stageId) async {
    final String imageName = "ShowImages/$stageId.jpg";
    final Reference imagesRef = FirebaseStorage.instance.ref().child(imageName);

    try {
      await imagesRef.delete(); // Resmi silme
    } catch (e) {
      throw Exception('Resim silinirken bir hata oluştu: $e');
    }
  }

  Map<String, dynamic> putHashMap(
      Show? show, String downloadUrl, bool isUpdate) {
    final Map<String, dynamic> showMap = {};

    if (!isUpdate) {
      showMap['_createdAt'] = DateTime.now().toIso8601String();
    }

    showMap['_updatedAt'] = DateTime.now().toIso8601String();
    showMap['_id'] = show?.id ?? '';
    showMap['name'] = show?.name ?? '';
    showMap['imageUrl'] = downloadUrl;
    showMap['ageLimit'] = show?.ageLimit ?? '';
    showMap['description'] = show?.description ?? '';
    showMap['category'] = show?.category ?? '';
    showMap['eventRule'] = show?.eventRule ?? '';

    // playersId listesi
    List<String> playersIdList = [];
    if (show?.playersId != null) {
      playersIdList = show!.playersId.map((e) => e.toString()).toList();
    }
    showMap['players'] = playersIdList;

    // eventsId listesi
    List<String> eventsIdList = [];
    if (show?.eventsId != null) {
      eventsIdList = show!.eventsId.map((e) => e.toString()).toList();
    }
    showMap['events'] = eventsIdList;

    // photosStageId listesi
    List<String> photosStageIdList = [];
    if (show?.photosStageId != null) {
      photosStageIdList = show!.photosStageId.map((e) => e.toString()).toList();
    }
    showMap['photosStageId'] = photosStageIdList;

    return showMap;
  }

  Show _mapDocumentToShow(DocumentSnapshot document) {
    return Show(
      createdAt: _getFieldAsString(document, '_createdAt'),
      updateAt: _getFieldAsString(document, '_updateAt'),
      id: _getFieldAsString(document, '_id'),
      imageUrl: _getFieldAsString(document, 'imageUrl'),
      name: _getFieldAsString(document, 'name'),
      description: _getFieldAsString(document, 'description'),
      category: _getFieldAsString(document, 'category'),
      ageLimit: _getFieldAsString(document, 'ageLimit'),
      eventRule: _getFieldAsString(document, 'eventRule'),
      playersId: _getListAsString(document, 'playersId'),
      eventsId: _getListAsString(document, 'eventsId'),
      photosStageId: _getListAsString(document, 'photosStageId'),
    );
  }

// Helper to get field as a string
  String _getFieldAsString(DocumentSnapshot document, String fieldName) {
    return document[fieldName].toString() ?? '';
  }

// Helper to get a list of strings
  List<String> _getListAsString(DocumentSnapshot document, String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
