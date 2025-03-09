import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> photosId;
  final List<String> showsId;

  const Team({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.photosId,
    required this.showsId,
  });

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    name,
    description,
    imageUrl,
    photosId,
    showsId,
  ];

  factory Team.fromMap(final Map<String, dynamic> data) {
    return Team(
      id: data['_id'] ?? '',
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      photosId: List<String>.from(data['photosId'] ?? []),
      showsId: List<String>.from(data['showsId'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'photosId': photosId,
      'showsId': showsId,
    };
  }
}
