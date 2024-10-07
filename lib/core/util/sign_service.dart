import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../custom_views/custom_loading.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final GoogleSignInAccount? account;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try{
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      return account;
    }catch (e){
      throw Exception(e);
    }
  }

  Future<void> verifyPhone(BuildContext context,
      String phoneNumber,
      Function(String) onVerificationCompleted,
      Function(String) onCodeSent,
      Function(String) onAutoRetrievalTimeout,) async {
    _showLoadingDialog(context);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onVerificationCompleted(credential.smsCode ?? '');
      },
      verificationFailed: (FirebaseAuthException e) {
        _showErrorSnackBar(context, e.message ?? 'Verification failed');
        _hideLoadingDialog(context);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
        _hideLoadingDialog(context);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onAutoRetrievalTimeout(verificationId);
        _hideLoadingDialog(context);
      },
    );
  }

  Future<bool> verifyOtp(BuildContext context, String verificationId, String otp) async {
    _showLoadingDialog(context);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      _hideLoadingDialog(context);
      return true; // Başarılı
    } catch (e) {
      _showErrorSnackBar(context, e.toString());
      _hideLoadingDialog(context);
      return false; // Hatalı
    }
  }

  // Firebase Authentication - Oturum Kapatma
  Future<void> signOut() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        for (UserInfo userInfo in user.providerData) {
          if (userInfo.providerId == 'google.com') {
            // Kullanıcı Google ile giriş yapmış, Google'dan çıkış yap
            await GoogleSignIn().signOut();
            print('Google ile oturum kapatıldı.');
          }
        }
        await _auth.signOut();
      }
      print('Firebaseden oturum kapatıldı.');
    } catch (e) {
      print('Oturum kapatılırken hata oluştu: $e');
      throw Exception('Error signing out: $e');
    }
  }

  // Açık oturumdaki user bilgileri
  get currentUser => _auth.currentUser;

  // Kullanıcının Oturum Açmış mı Kontrol Etme
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  void _showLoadingDialog(BuildContext context) {
    LoadingOverlay.show(context);
  }

  void _hideLoadingDialog(BuildContext context) {
    LoadingOverlay.hide(context);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
