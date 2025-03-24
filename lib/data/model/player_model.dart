import '../../domain/entities/player.dart';

class PlayerModel {
  final String? createdAt;
  final String? updatedAt;
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? imageUrl;
  final List<String?>? nowShowsId;
  final List<String?>? oldShowsId;

  const PlayerModel({
    this.createdAt,
    this.updatedAt,
    this.id,
    this.firstName,
    this.lastName,
    this.bio,
    this.imageUrl,
    this.nowShowsId,
    this.oldShowsId,
  });

  factory PlayerModel.fromFirestore(final Map<String, dynamic>? data){
    if (data == null) return PlayerModel();
    return PlayerModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      bio: data['bio'] as String?,
      imageUrl: data['imageUrl'] as String?,
      nowShowsId: (data['nowShowsId'] as List?)
          ?.map((final e) => e as String?)
          .toList(),
      oldShowsId: (data['oldShowsId'] as List?)
          ?.map((final e) => e as String?)
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
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

  Player toEntity() => Player(
    createdAt: createdAt,
    updatedAt: updatedAt,
    id: id,
    firstName: firstName,
    lastName: lastName,
    bio: bio,
    imageUrl: imageUrl,
    nowShowsId: nowShowsId ?? [],
    oldShowsId: oldShowsId ?? [],
  );

  factory PlayerModel.fromEntity(final Player player) => PlayerModel(
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
