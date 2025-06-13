import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AppToolsRemoteDataSource {
  Future<String?> getPrivacyPolicy();
  Future<String?> getTermsCondition();
}

class AppToolsRemoteDataSourceImpl implements AppToolsRemoteDataSource {
  final FirebaseFirestore firestore;
  final String docId = 'bgVYTTauB9gwd1qOyjix';

  AppToolsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String?> getPrivacyPolicy() => _getField('privacyPolicy');

  @override
  Future<String?> getTermsCondition() => _getField('termsAndCondition');

  Future<String?> _getField(final String field) async {
    final settings = await _getAppSettings();
    return settings?[field] as String?;
  }

  Future<Map<String, dynamic>?> _getAppSettings() async {
    try {
      final doc = await firestore.collection('AppTools').doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Error fetching app settings: $e');
    }
  }

}
