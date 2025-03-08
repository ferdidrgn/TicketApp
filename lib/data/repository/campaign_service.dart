import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/campaing.dart';

class CampaignService {
  final CollectionReference _campaignCollection =
      FirebaseFirestore.instance.collection("Campaign");

  // Get all campaigns
  Future<List<Campaign?>> getCampaigns() async {
    try {
      final QuerySnapshot snapshot = await _campaignCollection.get();
      return snapshot.docs.map((final doc) => _mapDocumentToCampaign(doc)).toList();
    } catch (e) {
      throw Exception('Kampanyalar getirilemedi: $e');
    }
  }

  Campaign _mapDocumentToCampaign(final DocumentSnapshot document) {
    return Campaign(
      createdAt: _getStringField(document, '_createdAt'),
      updatedAt: _getStringField(document, '_updatedAt'),
      id: _getStringField(document, '_id'),
      title: _getStringField(document, 'title'),
      imageUrl: _getStringField(document, 'imageUrl'),
      startDate: _getStringField(document, 'startDate'),
      endDate: _getStringField(document, 'endDate'),
      url: _getStringField(document, 'url'),
    );
  }

  String _getStringField(final DocumentSnapshot document, final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }
}
