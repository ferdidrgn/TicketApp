import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AppToolsRemoteDataSource {
  Future<String?> getPrivacyPolicy();
  Future<String?> getTermsCondition();
}

class AppToolsRemoteDataSourceImpl implements AppToolsRemoteDataSource {
  final FirebaseFirestore firestore;

  AppToolsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String?> getPrivacyPolicy() => _getField('privacyPolicy');

  @override
  Future<String?> getTermsCondition() => _getField('termsAndCondition');

  Future<String?> _getField(final String field) async {
    try {
      final settings = await _getAppSettings();
      return settings?[field] as String?;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getAppSettings() async {
    try {
      final doc = await firestore
          .collection('AppTools')
          .doc('bgVYTTauB9gwd1qOyjix')
          .get();
      return doc.data();
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error fetching app settings: $e');
    }
  }
}
