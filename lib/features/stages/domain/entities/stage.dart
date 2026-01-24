import 'package:equatable/equatable.dart';

class Stage extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String capacity;
  final String description;
  final String communication;
  final String address;
  final double locationLat;
  final double locationLng;
  final String createdAt;
  final String updatedAt;
  final List<String> showsId;

  const Stage({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.capacity,
    required this.description,
    required this.communication,
    required this.address,
    required this.locationLat,
    required this.locationLng,
    required this.createdAt,
    required this.updatedAt,
    required this.showsId,
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
}
