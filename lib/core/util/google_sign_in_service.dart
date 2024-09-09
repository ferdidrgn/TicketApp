import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
  }
}
