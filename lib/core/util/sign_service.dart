import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repository/user_service.dart';
import '../custom_views/custom_loading.dart';
import '../../../data/model/user.dart' as _user;
import 'date_formatter.dart';

class LoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? account;

  Future<GoogleSignInAccount?> signInWithGoogle(final BuildContext context) async {
    _showLoadingDialog(context);
    try {
      // Eğer kullanıcı zaten oturum açtıysa doğrudan account'ı döndürebiliriz
      account =
          await _googleSignIn.isSignedIn() ? _googleSignIn.currentUser : null;
      if (account != null) {
        _hideLoadingDialog(context);
        return account;
      }

      // Google ile giriş yapılıyor
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı giriş yapmayı iptal etti, gereksiz işlemlerden kaçın
        _hideLoadingDialog(context);
        return null;
      }

      // Kimlik doğrulama bilgilerini paralel olarak alıp Firebase giriş işlemiyle devam ediyoruz
      final googleAuthFuture = googleUser.authentication;
      final GoogleSignInAuthentication googleAuth = await googleAuthFuture;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase Authentication ile giriş işlemi
      await _auth.signInWithCredential(credential);
      account = googleUser;
      _hideLoadingDialog(context);
      return account;
    } catch (e) {
      _hideLoadingDialog(context);
      _showErrorSnackBar(context, 'Google ile giriş başarısız: $e');
      return null;
    } finally {
      if (account != null) {
        fillUserInfo(account!);
      }
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
        _hideLoadingDialog(context);
      },
      verificationFailed: (final FirebaseAuthException e) {
        _showErrorSnackBar(context, e.message ?? 'Verification failed');
        _hideLoadingDialog(context);
      },
      codeSent: (final String verificationId, final int? resendToken) {
        onCodeSent(verificationId);
        _hideLoadingDialog(context);
      },
      codeAutoRetrievalTimeout: (final String verificationId) {
        onAutoRetrievalTimeout(verificationId);
        _hideLoadingDialog(context);
      },
    );
  }

  Future<bool> verifyOtp(
      final BuildContext context, final String verificationId, final String otp) async {
    _showLoadingDialog(context);
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
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
      final User? user = _auth.currentUser;

      if (user != null) {
        for (final UserInfo userInfo in user.providerData) {
          if (userInfo.providerId == 'google.com') {
            // Kullanıcı Google ile giriş yapmış, Google'dan çıkış yap
            await GoogleSignIn().signOut();
            print('Google ile oturum kapatıldı.');
          }
        }
        await _auth.signOut();
      }
      throw ('Firebaseden oturum kapatıldı.');
    } catch (e) {
      _showErrorSnackBar(null, 'Oturum kapatılırken hata oluştu: $e');
    }
  }

  // Açık oturumdaki user bilgileri
  User? get currentUser => _auth.currentUser;

  // Kullanıcının Oturum Açmış mı Kontrol Etme
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  void _showLoadingDialog(final BuildContext context) {
    LoadingOverlay.show(context);
  }

  void _hideLoadingDialog(final BuildContext context) {
    LoadingOverlay.hide(context);
  }

  void _showErrorSnackBar(final BuildContext? context, final String message) {
    context == null
        ? throw Exception(message)
        : ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
  }

  void fillUserInfo(final GoogleSignInAccount account) {
    if (isUserLoggedIn()) {
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
