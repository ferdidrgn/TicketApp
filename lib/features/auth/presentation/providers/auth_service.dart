import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  late final FirebaseAuth _firebaseAuthInstance;
  late final GoogleSignIn _googleSignInInstance;

  @override
  User? build() {
    _firebaseAuthInstance = FirebaseAuth.instance;
    _googleSignInInstance = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: kIsWeb ? "798150499696-YOUR_WEB_OAUTH_ID.apps.googleusercontent.com" : null,
    );
    return _firebaseAuthInstance.currentUser;
  }

  // Güvenli Google Oturum Açma Akışı
  Future<UserCredential?> executeSecureGoogleAuthenticationFlow() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider webAuthProvider = GoogleAuthProvider();
        webAuthProvider.addScope('email');
        webAuthProvider.addScope('profile');
        return await _firebaseAuthInstance.signInWithPopup(webAuthProvider);
      } else {
        final GoogleSignInAccount? accountPresence = await _googleSignInInstance.signIn();
        if (accountPresence == null) return null;

        final GoogleSignInAuthentication securityAuthenticationEnvelope = await accountPresence.authentication;
        final OAuthCredential authenticationCredentialToken = GoogleAuthProvider.credential(
          accessToken: securityAuthenticationEnvelope.accessToken,
          idToken: securityAuthenticationEnvelope.idToken,
        );

        return await _firebaseAuthInstance.signInWithCredential(authenticationCredentialToken);
      }
    } catch (criticalAuthException) {
      debugPrint('Google Login Hatası: $criticalAuthException');
      rethrow;
    }
  }

  // Kalıcı Çıkış Yapma Mantığı
  Future<void> executeGlobalSignOutRoutine() async {
    try {
      if (!kIsWeb) {
        await _googleSignInInstance.signOut();
      }
      await _firebaseAuthInstance.signOut();
    } catch (unhandledSignOutDrop) {
      await _firebaseAuthInstance.signOut();
    }
  }
}
