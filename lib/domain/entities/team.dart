import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<String?>? photosId;
  final List<String?>? showsId;

  const Team({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.description,
    this.imageUrl,
    this.photosId,
    this.showsId,
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

  factory Team.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Team();
    return Team(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      name: data['name'] as String?,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      photosId: (data['photosId'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
      showsId: (data['showsId'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'photosId': photosId,
        'showsId': showsId,
      };
}
