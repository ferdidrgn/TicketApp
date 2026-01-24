import '../../domain/entities/campaign.dart';
import '../models/campaing_model.dart';

extension CampaignModelMapper on CampaignModel {
  Campaign toEntity() => Campaign(
        id: id ?? '',
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        endDate: endDate ?? '',
        imageUrl: imageUrl ?? 'https://example.com/default-image.png',
        startDate: startDate ?? '',
        title: title ?? 'İsimsiz Kampanya',
        url: url ?? '',
      );
}

extension CampaignEntityMapper on Campaign {
  CampaignModel toModel() => CampaignModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        endDate: endDate,
        imageUrl: imageUrl,
        startDate: startDate,
        title: title,
        url: url,
      );
}
