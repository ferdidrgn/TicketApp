class Show {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String imageUrl;
  final String name;
  final String description;
  final String duration;
  final String category;
  final String teamId;
  final String type;
  final String ageLimit;
  final String eventRule;
  final List<String> nowPlayersId;
  final List<String> oldPlayersId;
  final List<String> eventsId;
  final List<String> photosShowId;

  Show({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.duration,
    required this.category,
    required this.type,
    required this.teamId,
    required this.ageLimit,
    required this.eventRule,
    required this.eventsId,
    required this.nowPlayersId,
    required this.oldPlayersId,
    required this.photosShowId,
  });
}
