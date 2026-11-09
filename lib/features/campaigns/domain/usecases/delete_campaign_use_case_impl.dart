import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/campaign_repository.dart';

abstract class DeleteCampaignUseCase {
  Future<Either<Failure, bool>> call(final String campaignId);
}

class DeleteCampaignUseCaseImpl implements DeleteCampaignUseCase {
  final CampaignRepository repository;

  DeleteCampaignUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String campaignId) async =>
      repository.deleteCampaign(campaignId);
}
