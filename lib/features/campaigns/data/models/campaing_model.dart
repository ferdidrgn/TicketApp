import '../../domain/entities/campaign.dart';

class CampaignModel {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? endDate;
  final String? imageUrl;
  final String? startDate;
  final String? title;
  final String? url;

  const CampaignModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.endDate,
    this.imageUrl,
    this.startDate,
    this.title,
    this.url,
  });

  factory CampaignModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const CampaignModel();
    return CampaignModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
      endDate: data['endDate'] as String?,
      imageUrl: data['imageUrl'] as String?,
      startDate: data['startDate'] as String?,
      title: data['title'] as String?,
      url: data['url'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'endDate': endDate,
        'imageUrl': imageUrl,
        'startDate': startDate,
        'title': title,
        'url': url,
      };

  Campaign toEntity() => Campaign(
        createdAt: createdAt ?? 'Tarih bulunamadı',
        updatedAt: updatedAt ?? 'Tarih bulunamadı',
        id: id ?? '0',
        endDate: endDate ?? 'Bitiş tarihi bulunamadı',
        imageUrl: imageUrl ?? 'https://example.com/default-image.png',
        startDate: startDate ?? 'Başlangıç tarihi bulunamadı',
        title: title ?? 'Başlık bulunamadı',
        url: url ?? 'https://example.com',
      );

  factory CampaignModel.fromEntity(final Campaign campaign) => CampaignModel(
        createdAt: campaign.createdAt,
        updatedAt: campaign.updatedAt,
        id: campaign.id,
        endDate: campaign.endDate,
        imageUrl: campaign.imageUrl,
        startDate: campaign.startDate,
        title: campaign.title,
        url: campaign.url,
      );
}
