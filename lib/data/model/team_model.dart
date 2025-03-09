import '../../domain/entities/team.dart';

class TeamModel {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> photosId;
  final List<String> showsId;

  const TeamModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.photosId,
    required this.showsId,
  });

  factory TeamModel.fromFirestore(final Map<String, dynamic> data) {
    return TeamModel(
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

  Map<String, dynamic> toFirestore() {
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

  Team toEntity() {
    return Team(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name,
      description: description,
      imageUrl: imageUrl,
      photosId: photosId,
      showsId: showsId,
    );
  }

  factory TeamModel.fromEntity(final Team team) {
    return TeamModel(
      id: team.id,
      createdAt: team.createdAt,
      updatedAt: team.updatedAt,
      name: team.name,
      description: team.description,
      imageUrl: team.imageUrl,
      photosId: team.photosId,
      showsId: team.showsId,
    );
  }
}
