import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/campaing_model.dart';

abstract class CampaignRemoteDataSource {
  Future<List<CampaignModel>> getCampaigns();
}

class CampaignRemoteDataSourceImpl implements CampaignRemoteDataSource {
  final FirebaseFirestore firestore;

  CampaignRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    try {
      final snapshot = await firestore.collection('Campaigns').get();
      return snapshot.docs
          .map((final doc) => CampaignModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching campaigns: $e');
    }
  }
}
