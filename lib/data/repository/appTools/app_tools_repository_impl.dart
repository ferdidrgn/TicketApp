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
  Future<String?> getPrivacyPolicy() async {
    return remoteDataSource.getPrivacyPolicy();
  }

  @override
  Future<String?> getTermsCondition() async {
    return remoteDataSource.getTermsCondition();
  }
}
