import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? account;

  GoogleSignInAccount? get getAccount => account;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      throw Exception('Google Sign-In Error: $error');
    }
  }

  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
  }
}