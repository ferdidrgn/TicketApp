import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/campaign_repository.dart';
import '../../datasources/campaign/campaign_remote_data_source_and_impl.dart';
import '../../model/campaing_model.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  final CampaignRemoteDataSource remoteDataSource;
  final InternetService internetService;

  CampaignRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, List<CampaignModel>>> getCampaigns() async {
    if (await internetService.isConnected)
      try {
        final campaigns = await remoteDataSource.getCampaigns();
        if (campaigns.isNotEmpty) return Right(campaigns.map((final model) => model).toList());
        else return const Left(ServerFailure("Boş Liste"));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    else return const Left(NetworkFailure('No internet connection'));
  }
}
