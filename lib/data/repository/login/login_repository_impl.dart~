import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/common/base_repo.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/login_repository.dart';
import '../../datasources/login/login_remote_data_source_and_impl.dart';

class LoginRepositoryImpl extends BaseRepository implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  LoginRepositoryImpl({required this.remoteDataSource, required super.internetService});

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return execute(() async {
     return remoteDataSource.getCurrentUser();
    });
  }

  @override
  Future<Either<Failure, String?>> signInWithGoogle() async {
    return  execute(() async {
      return remoteDataSource.signInWithGoogle();
    });
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return  execute(() async {
      return remoteDataSource.signOut();
    });
  }

  @override
  Future<Either<Failure, void>> verifyPhone(
      final String phoneNumber,
      final Function(String) onVerificationCompleted,
      final Function(String) onCodeSent,
      final Function(String) onAutoRetrievalTimeout,
      ) async {
    try {
      return execute(() async {
        if(phoneNumber.isEmpty) throw Exception('Telefon Numarası Boş Olamaz');
       await remoteDataSource.verifyPhone(phoneNumber, onVerificationCompleted, onCodeSent, onAutoRetrievalTimeout);
       const Right(null); // Başarılı
      });

    } catch (e) {
      return Left(ServerFailure('Telefon Doğrulama Hatası: $e')); // Hata
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(final String verificationId, final String otp) async {
    return  execute(() async {
      if(verificationId.isEmpty || otp.isEmpty) throw Exception('Doğrulama Kodu Boş Olamaz');
      return remoteDataSource.verifyOtp(verificationId, otp);
    });
  }
}
