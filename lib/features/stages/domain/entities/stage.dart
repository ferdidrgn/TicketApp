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

  factory Stage.fromMap(final Map<String, dynamic>? data) => Stage(
        id: data?['_id'] as String? ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        name: data?['name'] as String? ?? 'İsimsiz Takım',
        description: data?['description'] as String? ?? 'Açıklama bulunamadı.',
        imageUrl: data?['imageUrl'] as String? ??
            'https://example.com/default-image.png',
        capacity: data?['capacity'] as String? ?? 'Kapasite bulunamadı.',
        communication:
            data?['communication'] as String? ?? 'İletişim bulunamadı.',
        address: data?['address'] as String? ?? 'Adres bulunamadı.',
        locationLat: data?['locationLat'] as double? ?? 0.0,
        locationLng: data?['locationLng'] as double? ?? 0.0,
        showsId: (data?['showsId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
      );

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
