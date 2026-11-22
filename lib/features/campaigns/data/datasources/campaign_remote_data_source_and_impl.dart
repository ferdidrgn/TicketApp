import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/campaing_model.dart';

abstract class CampaignRemoteDataSource {
  Future<List<CampaignModel>> getCampaigns();

  /// ➕ Mobil admin panelinden yeni bir kampanya oluşturur.
  Future<bool> addCampaign(final CampaignModel campaign, final File? imageFile);

  /// 🔄 Mobil admin panelinden bir kampanyayı günceller.
  Future<bool> updateCampaign(final String campaignId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Mobil admin panelinden bir kampanyayı siler.
  Future<bool> deleteCampaign(final String campaignId);
}

class CampaignRemoteDataSourceImpl implements CampaignRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  const CampaignRemoteDataSourceImpl(
      {required this.firestore, required this.storage});

  CollectionReference<Map<String, dynamic>> get _campaignCollection =>
      firestore.collection('Campaign');

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    try {
      final snapshot = await _campaignCollection.get();
      return snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return CampaignModel.fromFirestore(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error fetching campaigns: $e');
    }
  }

  // 🔥 KRİTİK: Mobil yönetim görselleri için ayrılmış `TeamImages` tarzı bir
  // Storage yolu Campaign için YOK (bkz. `storage.rules` — yalnızca
  // PlayerImages/ShowImages/StageImages/TeamImages beyaz listede). Web
  // yönetim paneli (`site/js/admin/admin.js`) kampanya görsellerini
  // `images/Campaign/{zaman}-{ad}` yoluna yüklüyor; bu yol zaten
  // `storage.rules`'ta herkese açık okuma + admin yazma ile tanımlı
  // (`match /images/{coll}/{file}`). Mobil admin AYNI yolu kullanır —
  // yeni bir Storage kuralı eklemeye gerek yok.
  String _uploadPath(final File file) {
    final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    return 'images/Campaign/${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  @override
  Future<bool> addCampaign(
      final CampaignModel campaign, final File? imageFile) async {
    try {
      final data = campaign.toFirestore()
        ..remove('_id')
        ..['_createdAt'] = FieldValue.serverTimestamp()
        ..['_updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _campaignCollection.add(data);
      await docRef.update({'_id': docRef.id});

      if (imageFile != null) {
        final ref = storage.ref(_uploadPath(imageFile));
        await ref.putFile(imageFile);
        final downloadUrl = await ref.getDownloadURL();
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } catch (e) {
      throw Exception('Error adding campaign: $e');
    }
  }

  @override
  Future<bool> updateCampaign(final String campaignId,
      final Map<String, dynamic> updatedData, final File? imageFile) async {
    try {
      final data = Map<String, dynamic>.from(updatedData);

      if (imageFile != null) {
        final ref = storage.ref(_uploadPath(imageFile));
        await ref.putFile(imageFile);
        data['imageUrl'] = await ref.getDownloadURL();
      }

      await _campaignCollection.doc(campaignId).update({
        ...data,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Error updating campaign: $e');
    }
  }

  @override
  Future<bool> deleteCampaign(final String campaignId) async {
    try {
      await _campaignCollection.doc(campaignId).delete();
      return true;
    } catch (e) {
      throw Exception('Error deleting campaign: $e');
    }
  }
}
