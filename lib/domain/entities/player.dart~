import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String? createdAt;
  final String? updatedAt;
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? imageUrl;
  final List<String?>? nowShowsId;
  final List<String?>? oldShowsId;

  const Player({
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

  @override
  List<Object?> get props => [
        createdAt,
        updatedAt,
        id,
        firstName,
        lastName,
        bio,
        imageUrl,
        nowShowsId,
        oldShowsId,
      ];

  factory Player.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Player();
    return Player(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      imageUrl: data['imageUrl'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      bio: data['bio'] as String?,
      nowShowsId: (data['nowShowsId'] as List?)?.map((final e) => e as String?).toList(),
      oldShowsId: (data['oldShowsId'] as List?)?.map((final e) => e as String?).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'imageUrl': imageUrl,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'nowShowsId': nowShowsId,
      'oldShowsId': oldShowsId,
    };
}
