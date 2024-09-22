import 'package:cloud_firestore/cloud_firestore.dart';

class AppToolsService {
  final CollectionReference _firestore =
      FirebaseFirestore.instance.collection('AppTools');

  Future<String?> getPrivacyAndTerms(String fieldName) async {
    try {
      QuerySnapshot result = await _firestore.where(fieldName).limit(1).get();
      if (result.docs.isEmpty) {
        return null;
      } else {
        return result.docs.first[fieldName] as String;
      }
    } catch (e) {
      throw Exception('Error fetching $fieldName: $e');
    }
  }

  Future getPrivacyPolicy() async {
    return getPrivacyAndTerms('privacyPolicy');
  }

  Future getTermsCondition() async {
    return getPrivacyAndTerms('termsAndCondition');
  }
}
