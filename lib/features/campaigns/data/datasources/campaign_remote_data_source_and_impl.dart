import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaing_model.dart';

abstract class CampaignRemoteDataSource {
  Future<List<CampaignModel?>?> getCampaigns();
}

class CampaignRemoteDataSourceImpl implements CampaignRemoteDataSource {
  final FirebaseFirestore firestore;

  const CampaignRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<CampaignModel?>?> getCampaigns() async {
    try {
      final snapshot = await firestore.collection('Campaign').get();
      return snapshot.docs
          .map((final doc) => CampaignModel.fromFirestore(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error fetching campaigns: $e');
    }
  }
}
