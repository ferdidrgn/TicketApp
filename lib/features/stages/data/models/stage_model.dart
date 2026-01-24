import 'package:cloud_firestore/cloud_firestore.dart';

class StageModel {
  final String? id;
  final String? name;
  final String? imageUrl;
  final String? capacity;
  final String? description;
  final String? communication;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final String? createdAt;
  final String? updatedAt;
  final List<String>? showsId;

  const StageModel({
    this.id,
    this.name,
    this.imageUrl,
    this.capacity,
    this.description,
    this.communication,
    this.address,
    this.locationLat,
    this.locationLng,
    this.createdAt,
    this.updatedAt,
    this.showsId,
  });

  factory StageModel.fromFirestore(final Map<String, dynamic> data) =>
      StageModel(
        id: data['_id'] as String?,
        name: data['name'] as String?,
        imageUrl: data['imageUrl'] as String?,
        capacity: data['capacity'] as String?,
        description: data['description'] as String?,
        communication: data['communication'] as String?,
        address: data['address'] as String?,
        locationLat: data['locationLat'] as double?,
        locationLng: data['locationLng'] as double?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        showsId: (data['showsId'] as List?)?.map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'name': name,
        'imageUrl': imageUrl,
        'capacity': capacity,
        'description': description,
        'communication': communication,
        'address': address,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'showsId': showsId,
      };
}
