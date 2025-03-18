import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/campaign.dart';
import '../../repository/campaign_repository.dart';

abstract class GetCampaignsUseCase {
  Future<Either<Failure, List<Campaign?>>> call();
}

class GetCampaignsUseCaseImpl implements GetCampaignsUseCase {
  final CampaignRepository repository;

  GetCampaignsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Campaign?>>> call() async {
    return repository.getCampaigns();
  }
}
