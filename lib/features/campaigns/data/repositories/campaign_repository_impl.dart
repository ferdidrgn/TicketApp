import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../datasources/campaign_remote_data_source_and_impl.dart';
import '../mappers/campaigns_mapper.dart';

class CampaignRepositoryImpl extends BaseRepository
    implements CampaignRepository {
  final CampaignRemoteDataSource remoteDataSource;

  CampaignRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async =>
      execute(() async {
        final models = await remoteDataSource.getCampaigns();
        return models.map((final m) => m.toEntity()).toList();
      });
}
