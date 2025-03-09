import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String? imageUrl;
  final List<String> nowShowsId;
  final List<String> oldShowsId;

  const Player({
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

  factory Player.fromMap(final Map<String, dynamic> data) {
    return Player(
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

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'imageUrl': imageUrl,
      'nowShowsId': nowShowsId,
      'oldShowsId': oldShowsId,
    };
  }
}
