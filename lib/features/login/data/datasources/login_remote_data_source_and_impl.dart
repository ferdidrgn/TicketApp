import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class LoginRemoteDataSource {
  Future<User?> getCurrentUser();

  Future<User?> signInAnonymously();

  Future<GoogleSignInAccount?> signInWithGoogle();

  Future<bool> signOut();

  Future<bool> deleteAccount();

  Future<bool> verifyOtp(final String verificationId, final String otp);

  Future<String> verifyPhone({
    required final String phoneNumber,
    required final void Function(PhoneAuthCredential) onVerificationCompleted,
    required final void Function(
            String verificationId, int? forceResendingToken)
        onCodeSent,
    required final void Function(String verificationId) onAutoRetrievalTimeout,
  });
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  LoginRemoteDataSourceImpl({
    required final FirebaseAuth firebaseAuth,
    final GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  @override
  Future<User?> getCurrentUser() async => _auth.currentUser;

  @override
  Future<User?> signInAnonymously() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && !currentUser.isAnonymous)
        throw Exception('Zaten giriş yapılmış. Önce çıkış yapın.');

      if (currentUser != null && currentUser.isAnonymous) return currentUser;

      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          throw Exception(
              'Anonymous giriş desteklenmiyor. Firebase konsoldan etkinleştirin.');
        case 'network-request-failed':
          throw Exception(
              'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
        default:
          throw Exception('Anonymous giriş başarısız: ${e.message}');
      }
    } catch (e) {
      throw Exception('Anonymous giriş başarısız: $e');
    }
  }

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      await _auth.signInWithCredential(credential);

      return googleUser;
    } catch (e) {
      // Hatayı konsola yazdıralım ki ne olduğunu görelim

      throw Exception('Google Giriş Hatası: $e');
    }
  }

  @override
  Future<bool> signOut() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      if (user.providerData.any((final p) => p.providerId == 'google.com'))
        await _googleSignIn.signOut();

      await _auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuth çıkış hatası: ${e.message}');
    } catch (e) {
      throw Exception('Çıkış işlemi başarısız: $e');
    }
  }

  @override
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Hesabı silmek için son zamanlarda giriş yapmalısınız. Lütfen tekrar giriş yapın.');
      }
      throw Exception('Hesap silme başarısız: ${e.message}');
    } catch (e) {
      throw Exception('Hesap silme başarısız: $e');
    }
  }

  // ✅ Named parametre olarak güncellendi
  @override
  Future<String> verifyPhone({
    required final String phoneNumber,
    required final void Function(PhoneAuthCredential) onVerificationCompleted,
    required final void Function(
            String verificationId, int? forceResendingToken)
        onCodeSent,
    required final void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (final PhoneAuthCredential credential) async {
          onVerificationCompleted(credential);

          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.isAnonymous) {
            await currentUser.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }

          if (!completer.isCompleted) {
            completer.complete(credential.verificationId ?? '');
          }
        },
        verificationFailed: (final FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent:
            (final String verificationId, final int? forceResendingToken) {
          onCodeSent(verificationId, forceResendingToken);
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (final String verificationId) {
          onAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } on FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuth telefon doğrulama hatası: ${e.message}');
    } catch (e) {
      throw Exception('Telefon doğrulama başarısız: $e');
    }
  }

  @override
  Future<bool> verifyOtp(final String verificationId, final String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: otp);

      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        await currentUser.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Geçersiz OTP kodu.');
        case 'invalid-verification-id':
          throw Exception('Geçersiz doğrulama ID.');
        case 'session-expired':
          throw Exception('OTP süresi dolmuş. Lütfen yeniden kod isteyin.');
        default:
          throw Exception('OTP doğrulama başarısız: ${e.message}');
      }
    } catch (e) {
      throw Exception('OTP doğrulama başarısız: $e');
    }
  }
}
