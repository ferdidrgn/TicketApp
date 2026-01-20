import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'firebase_auth_provider.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(final Ref ref) => AuthService(ref);

class AuthService {
  final Ref _ref;

  AuthService(this._ref);

  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ========================================
  // STREAM & STATE
  // ========================================

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Is user logged in
  bool get isLoggedIn => currentUser != null;

  /// Is user anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  // ========================================
  // SIGN IN METHODS
  // ========================================

  /// 🔐 Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Önce temiz bir oturum için mevcut bağlantıyı sonlandırıyoruz
      // Ancak hatayı önlemek için try-catch içine alıyoruz
      try {
        await _googleSignIn.signOut();
      } catch (e) {}

      // 2. Giriş akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // ⚡ HATA BURADAYDI: Kullanıcı pencereyi kapatırsa googleUser NULL döner.
      // Null bir nesne üzerinde .authentication çağıramayız.
      if (googleUser == null) return null;

      // 3. Kimlik bilgilerini al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Firebase ile giriş yap
      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      // Eğer 'disconnect' yüzünden hata veriyorsa, kullanıcıya bir mesaj dönebilirsin
      rethrow;
    }
  }

  /// 📱 Verify phone number
  Future<void> verifyPhoneNumber({
    required final String phoneNumber,
    required final Function(PhoneAuthCredential) onVerificationCompleted,
    required final Function(String, int?) onCodeSent,
    required final Function(String) onVerificationFailed,
    required final Function(String) onAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (final FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (final String verificationId, final int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 📱 Sign in with phone credential
  Future<User?> signInWithPhoneCredential(
      final String verificationId, final String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// 👤 Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // SIGN OUT & DELETE
  // ========================================

  /// 🚪 Sign out
  Future<void> signOut() async {
    try {
      // signOut() yerine disconnect() kullanırsan hesap seçim ekranı zorunlu gelir
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.disconnect();

      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// 🗑️ Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception("No user to delete");

      // Hesabı silmeden önce Google bağlantısını kopar
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      await user.delete();
    } catch (e) {
      // Eğer hata "requires-recent-login" ise burada tekrar login istemen gerekebilir
      rethrow;
    }
  }

  // ========================================
  // FCM TOKEN MANAGEMENT
  // ========================================

  /// 📲 Save FCM token to Firestore
  Future<void> saveFcmToken(final String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('User').doc(userId).set({
          'fcmToken': token,
          '_updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {}
  }

  /// 🗑️ Clear FCM token from Firestore
  Future<void> clearFcmToken(final String userId) async {
    try {
      await _firestore.collection('User').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {}
  }

  // ========================================
  // UTILITY
  // ========================================

  /// Reload current user
  Future<void> reloadUser() async => await currentUser?.reload();

  /// Get login method
  String getLoginMethod(final User? user) {
    if (user == null) return 'none';
    if (user.isAnonymous) return 'anonymous';

    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') return 'google';
      if (provider.providerId == 'phone') return 'phone';
    }

    return 'unknown';
  }
}
