import 'package:equatable/equatable.dart';

class Stage extends Equatable {
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

  const Stage({
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

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        capacity,
        description,
        communication,
        address,
        locationLat,
        locationLng,
        createdAt,
        updatedAt,
        showsId,
      ];

  factory Stage.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Stage();
    return Stage(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      name: data['name'] as String?,
      imageUrl: data['imageUrl'] as String?,
      capacity: data['capacity'] as String?,
      description: data['description'] as String?,
      communication: data['communication'] as String?,
      address: data['address'] as String?,
      locationLat: data['locationLat'] as double?,
      locationLng: data['locationLng'] as double?,
      showsId: (data['showsId'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
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
