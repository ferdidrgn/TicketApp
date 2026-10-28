import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/features/auth/data/account_deletion_service.dart';
import 'package:ticketapp/features/auth/data/datasources/auth_remote_data_source_and_impl.dart';

import '../purchase/purchase_test_helpers.dart';

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.error);
  final FirebaseAuthException error;
  int calls = 0;
  @override
  User? get currentUser => null;
  @override
  Future<UserCredential> signInAnonymously() async {
    calls++;
    throw error;
  }
}

class _FakeGoogle extends Fake implements GoogleSignIn {}

AuthRemoteDataSourceImpl _ds(final _FakeAuth a) => AuthRemoteDataSourceImpl(
      firebaseAuth: a,
      googleSignIn: _FakeGoogle(),
      deletionService: AccountDeletionService(FakeCallableClient()),
    );

void main() {
  test('Anonymous kapalı (operation-not-allowed): çökmez, anlamlı mesajla Exception', () async {
    final auth = _FakeAuth(FirebaseAuthException(code: 'operation-not-allowed'));
    await expectLater(
      _ds(auth).signInAnonymously(),
      throwsA(isA<Exception>().having((final e) => e.toString(), 'mesaj',
          allOf(contains('Misafir girişi'), contains('Google'), isNot(contains('konsol'))))),
    );
    expect(auth.calls, 1);
  });

  test('Ağ hatası kullanıcıya bağlantı mesajı olarak döner', () async {
    final auth = _FakeAuth(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(
      _ds(auth).signInAnonymously(),
      throwsA(isA<Exception>().having(
          (final e) => e.toString(), 'mesaj', contains('İnternet'))),
    );
  });
}
