import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AppToolsRemoteDataSource {
  Future<String?> getPrivacyPolicy();

  Future<String?> getTermsCondition();
}

class AppToolsRemoteDataSourceImpl implements AppToolsRemoteDataSource {
  final FirebaseFirestore firestore;

  AppToolsRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<String?> getPrivacyPolicy() async {
    return getPrivacyAndTerms('privacyPolicy');
  }

  @override
  Future<String?> getTermsCondition() async {
    return getPrivacyAndTerms('termsAndCondition');
  }

  Future<String?> getPrivacyAndTerms(final String fieldName) async {
    try {
      final QuerySnapshot result = await firestore
          .collection("AppTools")
          .where(fieldName)
          .limit(1)
          .get();
      if (result.docs.isEmpty) {
        return null;
      } else {
        return result.docs.first[fieldName] as String;
      }
    } catch (e) {
      throw Exception('Error fetching $fieldName: $e');
    }
  }
}
