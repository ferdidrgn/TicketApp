import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class LoginRemoteDataSource {
  Future<User?> getCurrentUser();

  Future<GoogleSignInAccount?> signInWithGoogle();

  Future<bool> signOut();

  Future<bool> verifyPhone(
    final String phoneNumber, {
    required final void Function(String code) onVerificationCompleted,
    required final void Function(String verificationId) onCodeSent,
    required final void Function(String verificationId) onAutoRetrievalTimeout,
  });

  Future<bool> verifyOtp(final String verificationId, final String otp);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  LoginRemoteDataSourceImpl({
    required final FirebaseAuth firebaseAuth,
    final GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<User?> getCurrentUser() async => _auth.currentUser;

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    // Mevcut kullanıcı varsa tekrar giriş yapmayı engelle
    if (_auth.currentUser != null) return null;

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı pencereyi kapattı

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return googleUser;
    } on FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuth hatası: ${e.message}');
    } catch (e) {
      throw Exception('Google ile giriş başarısız: $e');
    }
  }

  @override
  Future<bool> signOut() async {
    final user = _auth.currentUser;
    if (user == null) return false; // Zaten çıkış yapılmış

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
  Future<bool> verifyPhone(
    final String phoneNumber, {
    required final void Function(String code) onVerificationCompleted,
    required final void Function(String verificationId) onCodeSent,
    required final void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (final credential) async {
          await _auth.signInWithCredential(credential);
          onVerificationCompleted(credential.smsCode ?? '');
        },
        verificationFailed: (final e) =>
            throw Exception(e.message ?? 'Telefon doğrulaması başarısız.'),
        codeSent: (final verificationId, final _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
      );
      return true;
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
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuth OTP hatası: ${e.message}');
    } catch (e) {
      throw Exception('OTP doğrulama başarısız: $e');
    }
  }
}
