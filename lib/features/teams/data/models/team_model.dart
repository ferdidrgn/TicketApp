import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<String>? photosId;
  final List<String>? showsId;

  const TeamModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.description,
    this.imageUrl,
    this.photosId,
    this.showsId,
  });

  /// 🔥 Firestore'dan güvenli okuma
  factory TeamModel.fromFirestore(final Map<String, dynamic> data) => TeamModel(
        id: data['_id'] as String?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        name: data['name'] as String?,
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        photosId: (data['photosId'] as List?)
            ?.map((final e) => e.toString())
            .toList(),
        showsId:
            (data['showsId'] as List?)?.map((final e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'photosId': photosId,
        'showsId': showsId,
      };
}
