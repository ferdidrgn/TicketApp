import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/campaign_repository.dart';
import '../../datasources/campaign/campaign_remote_data_source_and_impl.dart';
import '../../model/campaing_model.dart';

class CampaignRepositoryImpl extends BaseRepository
    implements CampaignRepository {
  final CampaignRemoteDataSource remoteDataSource;

  CampaignRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, List<CampaignModel?>?>> getCampaigns() async {
    return execute(() async {
      return remoteDataSource.getCampaigns();
    });
  }
}
