import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/campaign.dart';

abstract class CampaignRepository {
  Future<Either<Failure, List<Campaign>>> getCampaigns();
}
