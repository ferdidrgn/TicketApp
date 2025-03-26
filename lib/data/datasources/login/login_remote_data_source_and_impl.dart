import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class LoginRemoteDataSource {
  Future<GoogleSignInAccount?> signInWithGoogle();
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> verifyPhone(
      final String phoneNumber,
      final Function(String) onVerificationCompleted,
      final Function(String) onCodeSent,
      final Function(String) onAutoRetrievalTimeout,
      );
  Future<bool> verifyOtp(final String verificationId, final String otp);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  LoginRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<User?> getCurrentUser() async => firebaseAuth.currentUser;

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    final user = await getCurrentUser();
    if (user != null) return null;

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await firebaseAuth.signInWithCredential(credential);
    return googleUser;
  }

  @override
  Future<void> signOut() async {
    final user = await getCurrentUser();
    if (user != null) {
      for (final UserInfo userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com')
             await GoogleSignIn().signOut(); // Kullanıcı Google ile giriş yapmış, Google'dan çıkış yap
      }
      await firebaseAuth.signOut();
    }
  }

  @override
  Future<void> verifyPhone(
      final String phoneNumber,
      final Function(String) onVerificationCompleted,
      final Function(String) onCodeSent,
      final Function(String) onAutoRetrievalTimeout,
      ) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (final PhoneAuthCredential credential) async {
        await firebaseAuth.signInWithCredential(credential);
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
      await firebaseAuth.signInWithCredential(credential);
      return true; // Başarılı
    } catch (e) {
      throw Exception('OTP doğrulama hatası: $e');
    }
  }
}
