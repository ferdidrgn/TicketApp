import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/app_tools_repository.dart';
import '../../datasources/appTools/app_tools_remote_data_source_and_impl.dart';

class AppToolsRepositoryImpl implements AppToolsRepository {
  final AppToolsRemoteDataSource remoteDataSource;
  final InternetService internetService;

  AppToolsRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, String?>> getPrivacyPolicy() async {
    try {
      final privacyPolicy = await remoteDataSource.getPrivacyPolicy();
      return Right(privacyPolicy); // Başarılı
    } catch (e) {
      return Left(ServerFailure('Verileri Getirme Başarısız: $e')); // Hata
    }
  }

  @override
  Future<Either<Failure, String?>> getTermsCondition() async {
    try {
      final termsCondition = await remoteDataSource.getTermsCondition();
      return Right(termsCondition); // Başarılı
    } catch (e) {
      return Left(ServerFailure('Verileri Getirme Başarısız: $e')); // Hata
    }
  }
}
