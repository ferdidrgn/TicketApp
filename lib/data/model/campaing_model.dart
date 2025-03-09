import '../../domain/entities/campaign.dart';

class CampaignModel {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String endDate;
  final String imageUrl;
  final String startDate;
  final String title;
  final String url;

  const CampaignModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.endDate,
    required this.imageUrl,
    required this.startDate,
    required this.title,
    required this.url,
  });

  factory CampaignModel.fromFirestore(final Map<String, dynamic> data) {
    return CampaignModel(
      id: data['_id'] ?? '',
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      endDate: data['endDate'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startDate: data['startDate'] ?? '',
      title: data['title'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'startDate': startDate,
      'title': title,
      'url': url,
    };
  }

  Campaign toEntity() {
    return Campaign(
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

  factory CampaignModel.fromEntity(final Campaign campaign) {
    return CampaignModel(
      id: campaign.id,
      createdAt: campaign.createdAt,
      updatedAt: campaign.updatedAt,
      endDate: campaign.endDate,
      imageUrl: campaign.imageUrl,
      startDate: campaign.startDate,
      title: campaign.title,
      url: campaign.url,
    );
  }
}
