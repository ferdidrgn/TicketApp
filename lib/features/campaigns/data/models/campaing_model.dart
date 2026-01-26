import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? startDate, endDate;
  final String? imageUrl;
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

  factory CampaignModel.fromFirestore(final Map<String, dynamic> data) =>
      CampaignModel(
        id: data['_id'] as String?,
        endDate: data['endDate'] as String?,
        imageUrl: data['imageUrl'] as String?,
        startDate: data['startDate'] as String?,
        title: data['title'] as String?,
        url: data['url'] as String?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
      );

  Map<String, dynamic> toFirestore() => {
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
