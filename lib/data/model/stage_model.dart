import '../../domain/entities/stage.dart';

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
  final List<String?>? showsId;

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

  factory StageModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const StageModel();
    return StageModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
      name: data['name'] as String?,
      imageUrl: data['imageUrl'] as String?,
      capacity: data['capacity'] as String?,
      description: data['description'] as String?,
      communication: data['communication'] as String?,
      address: data['address'] as String?,
      locationLat: data['locationLat'] as double?,
      locationLng: data['locationLng'] as double?,
      showsId:
          (data['showsId'] as List?)?.map((final e) => e as String?).toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
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

  Stage toEntity() => Stage(
        id: id,
        name: name,
        imageUrl: imageUrl,
        capacity: capacity,
        description: description,
        communication: communication,
        address: address,
        locationLat: locationLat,
        locationLng: locationLng,
        createdAt: createdAt,
        updatedAt: updatedAt,
        showsId: showsId ?? [],
      );

  factory StageModel.fromEntity(final Stage entity) => StageModel(
        id: entity.id,
        name: entity.name,
        imageUrl: entity.imageUrl,
        capacity: entity.capacity,
        description: entity.description,
        communication: entity.communication,
        address: entity.address,
        locationLat: entity.locationLat,
        locationLng: entity.locationLng,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        showsId: entity.showsId,
      );
}
