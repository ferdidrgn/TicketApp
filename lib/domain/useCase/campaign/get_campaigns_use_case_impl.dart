import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../data/model/campaing_model.dart';
import '../../repository/campaign_repository.dart';

abstract class GetCampaignsUseCase {
  Future<Either<Failure, List<CampaignModel?>?>> call();
}

class GetCampaignsUseCaseImpl implements GetCampaignsUseCase {
  final CampaignRepository repository;

  GetCampaignsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<CampaignModel?>?>> call() async {
    return repository.getCampaigns();
  }
}
