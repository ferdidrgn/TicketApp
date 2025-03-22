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
  final List<String>? showsId;

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
  List<Object?> get props =>
      [
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

  factory Stage.fromMap(final Map<String, dynamic> data) {
    return Stage(
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

  Map<String, dynamic> toMap() {
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
}
