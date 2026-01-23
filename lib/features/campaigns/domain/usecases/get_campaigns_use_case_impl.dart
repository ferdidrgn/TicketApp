import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/campaign.dart';
import '../repositories/campaign_repository.dart';

abstract class GetCampaignsUseCase {
  Future<Either<Failure, List<Campaign>>> call();
}

class GetCampaignsUseCaseImpl implements GetCampaignsUseCase {
  final CampaignRepository repository;

  GetCampaignsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Campaign>>> call() async {
    final result = await repository.getCampaigns();
    return result.fold(
        (final failure) => Left(failure),
        (final campaignsModels) => Right(campaignsModels
                ?.map((final campaignModel) => campaignModel?.toEntity())
                .whereType<Campaign>()
                .toList() ??
            []));
  }
}
