// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Campaign _$CampaignFromJson(Map<String, dynamic> json) => Campaign(
      id: json['_id'] as String,
      createdAt: json['_createdAt'] as String,
      updatedAt: json['_updatedAt'] as String,
      endDate: json['endDate'] as String,
      imageUrl: json['imageUrl'] as String? ??
          'https://example.com/default-image.png',
      startDate: json['startDate'] as String,
      title: json['title'] as String? ?? 'İsimsiz Kampanya',
      url: json['url'] as String? ?? 'https://example.com',
    );

Map<String, dynamic> _$CampaignToJson(Campaign instance) => <String, dynamic>{
      '_id': instance.id,
      '_createdAt': instance.createdAt,
      '_updatedAt': instance.updatedAt,
      'endDate': instance.endDate,
      'imageUrl': instance.imageUrl,
      'startDate': instance.startDate,
      'title': instance.title,
      'url': instance.url,
    };
