import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// 🔥 MANUEL FIRESTORE DÖNÜŞÜMÜ (Güvenli Timestamp Kontrolü)
  factory CampaignModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const CampaignModel();
    return CampaignModel(
      // Timestamp -> String dönüşümü
      createdAt: data['_createdAt'] is Timestamp
          ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
          : data['_createdAt']?.toString() ?? '',
      updatedAt: data['_updatedAt'] is Timestamp
          ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
          : data['_updatedAt']?.toString() ?? '',
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
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        id: id ?? '0',
        endDate: endDate ?? '',
        imageUrl: imageUrl ?? 'https://example.com/default-image.png',
        startDate: startDate ?? '',
        title: title ?? 'Başlık Yok',
        url: url ?? '',
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
