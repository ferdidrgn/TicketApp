import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
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

  @override
  Future<Either<Failure, bool>> addCampaign(
          final Campaign campaign, final File? imageFile) =>
      execute(() async {
        final model = campaign.toModel();
        return remoteDataSource.addCampaign(model, imageFile);
      });

  @override
  Future<Either<Failure, bool>> updateCampaign(final String campaignId,
          final Map<String, dynamic> updatedData, final File? imageFile) =>
      execute(() => remoteDataSource.updateCampaign(
          campaignId, updatedData, imageFile));

  @override
  Future<Either<Failure, bool>> deleteCampaign(final String campaignId) {
    if (campaignId.isEmpty) {
      return Future.value(const Left(ServerFailure('Invalid ID')));
    }
    return execute(() => remoteDataSource.deleteCampaign(campaignId));
  }
}
