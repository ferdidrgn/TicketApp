import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class LoginRemoteDataSource {
  Future<User?> getCurrentUser();

  Future<GoogleSignInAccount?> signInWithGoogle();

  Future<bool> signOut();

  Future<void> verifyPhone(
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
    if (_auth.currentUser != null) return null;

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return googleUser;
    } catch (e) {
      throw Exception('Google giriş hatası: $e');
    }
  }

  @override
  Future<bool> signOut() async {
    final user = await getCurrentUser();
    if (user == null) return false;

    try {
      final isGoogleUser =
          user.providerData.any((final p) => p.providerId == 'google.com');
      if (isGoogleUser) await _googleSignIn.signOut();
      await _auth.signOut();
      return true;
    } catch (e) {
      throw Exception('Çıkış hatası: $e');
    }
  }

  @override
  Future<void> verifyPhone(
      final String phoneNumber,
      final Function(String) onVerificationCompleted,
      final Function(String) onCodeSent,
      final Function(String) onAutoRetrievalTimeout,
      ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (final PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onVerificationCompleted(credential.smsCode ?? '');
      },
      verificationFailed: (final FirebaseAuthException e) {
        throw Exception(e.message);
      },
      codeSent: (final String verificationId, final int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (final String verificationId) {
        onAutoRetrievalTimeout(verificationId);
      },
    );
  }

  @override
  Future<bool> verifyOtp(final String verificationId, final String otp) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      throw Exception('OTP doğrulama hatası: $e');
    }
  }
}
