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

  factory StageModel.fromFirestore(final Map<String, dynamic> data) {
    return StageModel(
      id: data['_id'],
      name: data['name'],
      imageUrl: data['imageUrl'],
      capacity: data['capacity'],
      description: data['description'],
      communication: data['communication'],
      address: data['address'],
      locationLat: data['locationLat']?.toDouble(),
      locationLng: data['locationLng']?.toDouble(),
      createdAt: data['_createdAt'],
      updatedAt: data['_updatedAt'],
      showsId: List<String>.from(data['showsId'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_id': id,
      'name': name,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'description': description,
      'communication': communication,
      'address': address,
      'locationLat': locationLat,
      'locationLng': locationLng,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'showsId': showsId,
    };
  }

  Stage toEntity() {
    return Stage(
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
      showsId: showsId,
    );
  }

  factory StageModel.fromEntity(final Stage stage) {
    return StageModel(
      id: stage.id,
      name: stage.name,
      imageUrl: stage.imageUrl,
      capacity: stage.capacity,
      description: stage.description,
      communication: stage.communication,
      address: stage.address,
      locationLat: stage.locationLat,
      locationLng: stage.locationLng,
      createdAt: stage.createdAt,
      updatedAt: stage.updatedAt,
      showsId: stage.showsId,
    );
  }
}
