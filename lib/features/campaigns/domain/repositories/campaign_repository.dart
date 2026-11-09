import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/campaign.dart';

abstract class CampaignRepository {
  Future<Either<Failure, List<Campaign>>> getCampaigns();

  /// ➕ Mobil admin panelinden yeni bir kampanya oluşturur.
  Future<Either<Failure, bool>> addCampaign(
      final Campaign campaign, final File? imageFile);

  /// 🔄 Mobil admin panelinden bir kampanyayı günceller. `imageFile`
  /// verilirse görsel `addCampaign` ile AYNI Storage yoluna yeniden yüklenir.
  Future<Either<Failure, bool>> updateCampaign(final String campaignId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Mobil admin panelinden bir kampanyayı siler.
  Future<Either<Failure, bool>> deleteCampaign(final String campaignId);
}
