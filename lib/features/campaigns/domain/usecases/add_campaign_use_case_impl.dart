import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/campaign.dart';
import '../repositories/campaign_repository.dart';

abstract class AddCampaignUseCase {
  Future<Either<Failure, bool>> call(
      final Campaign campaign, final File? imageFile);
}

class AddCampaignUseCaseImpl implements AddCampaignUseCase {
  final CampaignRepository repository;

  AddCampaignUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final Campaign campaign, final File? imageFile) async =>
      repository.addCampaign(campaign, imageFile);
}
