import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String imageUrl;
  final List<String> nowShowsId;
  final List<String> oldShowsId;

  const Player({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.imageUrl,
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
}
