import '../../domain/entities/player.dart';

class PlayerModel {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String? imageUrl;
  final List<String> nowShowsId;
  final List<String> oldShowsId;

  const PlayerModel({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    this.imageUrl,
    required this.nowShowsId,
    required this.oldShowsId,
  });

  factory PlayerModel.fromFirestore(final Map<String, dynamic> data) {
    return PlayerModel(
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      id: data['_id'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      bio: data['bio'] ?? '',
      imageUrl: data['imageUrl'],
      nowShowsId: List<String>.from(data['nowShowsId'] ?? []),
      oldShowsId: List<String>.from(data['oldShowsId'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'imageUrl': imageUrl,
      'nowShowsId': nowShowsId,
      'oldShowsId': oldShowsId,
    };
  }

  Player toEntity() {
    return Player(
      createdAt: createdAt,
      updatedAt: updatedAt,
      id: id,
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      imageUrl: imageUrl,
      nowShowsId: nowShowsId,
      oldShowsId: oldShowsId,
    );
  }

  factory PlayerModel.fromEntity(final Player player) {
    return PlayerModel(
      createdAt: player.createdAt,
      updatedAt: player.updatedAt,
      id: player.id,
      firstName: player.firstName,
      lastName: player.lastName,
      bio: player.bio,
      imageUrl: player.imageUrl,
      nowShowsId: player.nowShowsId,
      oldShowsId: player.oldShowsId,
    );
  }
}
