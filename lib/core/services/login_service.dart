import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repository/user_service.dart';
import '../custom_views/custom_loading.dart';
import '../../../data/model/user.dart' as _user;
import '../util/date_formatter.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final LoginService _instance = LoginService._internal();

  factory LoginService() {
    return _instance; // Singleton
  }

  LoginService._internal(); // Private constructor

  User? get currentUser => _auth.currentUser;

  bool get isUserLoggedIn => currentUser != null;

  Future<String?> signInWithGoogle(final BuildContext context) async {
    _showLoadingDialog(context);

    try {
      // Eğer kullanıcı zaten giriş yapmışsa, user bilgisini döndür
      if (currentUser != null) {
        return currentUser!.displayName;
      }

      // Kimlik doğrulama akışını başlat
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Yeni bir kimlik bilgisi oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Firebase ile oturum aç
      await _auth.signInWithCredential(credential);
      return googleUser?.displayName;
    } catch (e) {
      _showErrorSnackBar(context, 'Google Girişi Başarısız Oldu: $e');
      return null; // Hata durumunu fırlat
    } finally {
      _hideLoadingDialog(context);
    }
  }

  Future<void> verifyPhone(
    final BuildContext context,
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  ) async {
    _showLoadingDialog(context);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (final PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onVerificationCompleted(credential.smsCode ?? '');
      },
      verificationFailed: (final FirebaseAuthException e) {
        _showErrorSnackBar(context, e.message ?? 'Doğrulama hatası');
      },
      codeSent: (final String verificationId, final int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (final String verificationId) {
        onAutoRetrievalTimeout(verificationId);
      },
    );
    _hideLoadingDialog(context);
  }

  Future<bool> verifyOtp(final BuildContext context,
      final String verificationId, final String otp) async {
    _showLoadingDialog(context);
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true; // Başarılı
    } catch (e) {
      _showErrorSnackBar(context, e.toString());
      return false; // Hatalı
    } finally {
      _hideLoadingDialog(context);
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        for (final UserInfo userInfo in currentUser!.providerData) {
          if (userInfo.providerId == 'google.com') {
            // Kullanıcı Google ile giriş yapmış, Google'dan çıkış yap
            await GoogleSignIn().signOut();
          }
        }
        await _auth.signOut();
      }
    } catch (e) {
      _showErrorSnackBar(null, 'Oturum kapatılırken hata oluştu: $e');
    }
  }

  void _showLoadingDialog(final BuildContext context) {
    LoadingOverlay.show(context);
  }

  void _hideLoadingDialog(final BuildContext context) {
    LoadingOverlay.hide(context);
  }

  void _showErrorSnackBar(final BuildContext? context, final String message) {
    if (context != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      throw Exception(message);
    }
  }

  void fillUserInfo(final GoogleSignInAccount account) {
    if (isUserLoggedIn) {
      final String displayName = account.displayName?.trim() ?? '';
      final List<String> nameParts = displayName.split(' ');
      final nowTime = DateFormatter.nowFormatDateTime();

      final user = _user.User(
        id: _auth.currentUser!.uid,
        createdAt: nowTime,
        updatedAt: nowTime,
        firstName: nameParts.isNotEmpty
            ? nameParts.sublist(0, nameParts.length - 1).join(' ')
            : '',
        lastName: nameParts.isNotEmpty ? nameParts.last : '',
        imageUrl: account.photoUrl,
        phoneNumber: '',
        age: 0,
        eMail: account.email,
        city: '',
        isPhoneActive: false,
        fcmToken: '',
        role: 'user',
      );
      UserService().saveUser(user, account.photoUrl ?? '');
    }
  }
}
