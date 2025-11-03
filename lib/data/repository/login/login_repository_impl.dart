import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/common/base_repo.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/login_repository.dart';
import '../../datasources/login/login_remote_data_source_and_impl.dart';

class LoginRepositoryImpl extends BaseRepository implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  LoginRepositoryImpl({
    required this.remoteDataSource,
    required super.internetService,
  });

  @override
  Future<Either<Failure, User?>> getCurrentUser() {
    return execute(() => remoteDataSource.getCurrentUser());
  }

  @override
  Future<Either<Failure, User?>> signInAnonymously() async {
    return execute(() => remoteDataSource.signInAnonymously());
  }

  @override
  Future<Either<Failure, GoogleSignInAccount?>> signInWithGoogle() {
    return execute(() => remoteDataSource.signInWithGoogle());
  }

  @override
  Future<Either<Failure, bool>> signOut() {
    return execute(() => remoteDataSource.signOut());
  }

  @override
  Future<Either<Failure, bool>> deleteAccount() {
    return execute(() => remoteDataSource.deleteAccount());
  }

  @override
  Future<Either<Failure, String>> verifyPhone({
    required final String phoneNumber,
    required final void Function(PhoneAuthCredential) onVerificationCompleted,
    required final void Function(
            String verificationId, int? forceResendingToken)
        onCodeSent,
    required final void Function(String verificationId) onAutoRetrievalTimeout,
  }) {
    return execute(() async {
      if (phoneNumber.isEmpty) throw Exception('Telefon Numarası Boş Olamaz');

      return remoteDataSource.verifyPhone(
        phoneNumber: phoneNumber,
        onVerificationCompleted: onVerificationCompleted,
        onCodeSent: onCodeSent,
        onAutoRetrievalTimeout: onAutoRetrievalTimeout,
      );
    });
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(
      final String verificationId, final String otp) {
    return execute(() async {
      if (verificationId.isEmpty || otp.isEmpty)
        throw Exception('Doğrulama Kodu veya ID Boş Olamaz');
      return remoteDataSource.verifyOtp(verificationId, otp);
    });
  }
}
