import 'package:equatable/equatable.dart';

class Show extends Equatable {
  final String id;
  final String createdAt, updatedAt;

  final String name;
  final String description;
  final String imageUrl;

  final String duration;
  final String category;
  final String type;
  final String ageLimit;
  final String eventRule;

  final String teamId;

  final List<String> eventsId;
  final List<String> nowPlayersId;
  final List<String> oldPlayersId;
  final List<String> photosShowId;

  /// 🎬 Fragman/tanıtım videosu için YouTube video ID'si (ör. "dQw4w9WgXcQ").
  /// Küratör tarafından opsiyonel olarak eklenir; boşsa web ana sayfasındaki
  /// "Fragmanlar" bölümünde bu gösteri hiç görünmez.
  final String? trailerYoutubeId;

  const Show({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.category,
    required this.type,
    required this.ageLimit,
    required this.eventRule,
    required this.teamId,
    required this.eventsId,
    required this.nowPlayersId,
    required this.oldPlayersId,
    required this.photosShowId,
    this.trailerYoutubeId,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        name,
        description,
        imageUrl,
        duration,
        category,
        type,
        ageLimit,
        eventRule,
        teamId,
        eventsId,
        nowPlayersId,
        oldPlayersId,
        photosShowId,
        trailerYoutubeId,
      ];
}
