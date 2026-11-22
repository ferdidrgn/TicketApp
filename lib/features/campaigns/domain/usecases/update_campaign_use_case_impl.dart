import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/campaign_repository.dart';

abstract class UpdateCampaignUseCase {
  Future<Either<Failure, bool>> call(final String campaignId,
      final Map<String, dynamic> updatedData, final File? imageFile);
}

class UpdateCampaignUseCaseImpl implements UpdateCampaignUseCase {
  final CampaignRepository repository;

  UpdateCampaignUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String campaignId,
          final Map<String, dynamic> updatedData, final File? imageFile) async =>
      repository.updateCampaign(campaignId, updatedData, imageFile);
}
