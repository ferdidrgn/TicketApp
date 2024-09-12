import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppToolsService {
  final _firestore = FirebaseFirestore.instance.collection('AppTools');

  Future<String?> getPrivacyAndTerms(String fieldName) async {
    try {
      QuerySnapshot result =await _firestore.where(fieldName).get();
      if (result.docs.isEmpty) {
        return null;
      } else {
        return result.docs.first[fieldName] as String;
      }
    } catch (e) {
      SnackBar(content: Text('Error fetching Privacy Policy: $e'));
      return null;
    }
  }

  Future getPrivacyPolicy() async {
    return getPrivacyAndTerms('privacyPolicy');
  }

  Future getTermsCondition() async {
    return getPrivacyAndTerms('termsAndCondition');
  }
}
