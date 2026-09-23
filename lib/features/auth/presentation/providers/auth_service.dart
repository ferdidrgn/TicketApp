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
    // KRİTİK: web'deki gerçek giriş akışı bu örneği hiç kullanmıyor —
    // Firebase'in kendi `signInWithPopup(GoogleAuthProvider())` akışını
    // çağırıyor (aşağıda `kIsWeb` dalı). AMA `google_sign_in_web` paketi,
    // `.signIn()` hiç çağrılmasa bile, `GoogleSignIn(...)` örneği
    // oluşturulur oluşturulmaz `appClientId != null` diye bir assertion
    // atıyor — bu yüzden web'de clientId olmadan bu satır uygulamayı
    // anında çökertiyordu. Değer Firebase Console → Authentication →
    // Sign-in method → Google → "Web SDK configuration" → Web client ID'den
    // alınan GERÇEK, herkese açık bir OAuth istemci ID'si (web client ID'ler
    // gizli değildir, sayfa kaynağında zaten görünür olur). Android/iOS'ta
    // clientId göndermiyoruz — orada google-services.json/
    // GoogleService-Info.plist üzerinden otomatik çözülüyor.
    _googleSignInInstance = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb
          ? '823869540671-qqlassf6p7014kdcatrp6qj6795gghqm.apps.googleusercontent.com'
          : null,
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
