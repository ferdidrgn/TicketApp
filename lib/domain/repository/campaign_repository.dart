import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/campaing_model.dart';

abstract class CampaignRepository {
  Future<Either<Failure, List<CampaignModel>>> getCampaigns();
}
