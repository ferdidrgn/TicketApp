import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id, createdAt, updatedAt;
  final String firstName, lastName, imageUrl, bio;
  final List<Map<String, String>>
      achievements; // Örn: {'year': '2020', 'title': '...', 'detail': '...'}
  final List<String> collaborations;
  final String quote;
  final List<String> nowShowsId;
  final List<String> oldShowsId;

  const Player({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.bio,
    required this.achievements,
    required this.collaborations,
    required this.quote,
    required this.nowShowsId,
    required this.oldShowsId,
  });

  @override
  List<Object?> get props =>
      [id, firstName, lastName, achievements, collaborations, quote];
}
