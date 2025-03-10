import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/login_repository.dart';
import '../../datasources/login/login_remote_data_source_and_impl.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;
  final InternetService internetService;

  LoginRepositoryImpl(
      {required this.remoteDataSource, required this.internetService});

  @override
  User? getCurrentUser() => remoteDataSource.getCurrentUser();

  @override
  Future<Either<Failure, String?>> signInWithGoogle() async {
    try {
      final displayName = await remoteDataSource.signInWithGoogle();
      return Right(displayName); // Başarılı
    } catch (e) {
      return Left(ServerFailure('Google Girişi Başarısız: $e')); // Hata
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null); // Başarılı
    } catch (e) {
      return Left(ServerFailure('Oturum Kapatma Hatası: $e')); // Hata
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhone(
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  ) async {
    try {
      await remoteDataSource.verifyPhone(phoneNumber, onVerificationCompleted,
          onCodeSent, onAutoRetrievalTimeout);
      return const Right(null); // Başarılı
    } catch (e) {
      return Left(ServerFailure('Telefon Doğrulama Hatası: $e')); // Hata
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(
      final String verificationId, final String otp) async {
    try {
      final result = await remoteDataSource.verifyOtp(verificationId, otp);
      return Right(result); // Başarılı
    } catch (e) {
      return Left(ServerFailure('OTP Doğrulama Hatası: $e')); // Hata
    }
  }
}
