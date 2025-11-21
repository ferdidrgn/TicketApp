import 'package:dartz/dartz.dart';
import '../../../core/common/base_repo.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/app_tools_repository.dart';
import '../../datasources/appTools/app_tools_remote_data_source_and_impl.dart';

class AppToolsRepositoryImpl extends BaseRepository
    implements AppToolsRepository {
  final AppToolsRemoteDataSource remoteDataSource;

  AppToolsRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, String?>> getPrivacyPolicy() async {
    return execute(() async => remoteDataSource.getPrivacyPolicy());
  }

  @override
  Future<Either<Failure, String?>> getTermsCondition() async {
    return execute(() => remoteDataSource.getTermsCondition());
  }
}
