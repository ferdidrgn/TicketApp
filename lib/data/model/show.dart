class Show {
  final String createdAt;
  final String updateAt;
  final String id;
  final String imageUrl;
  final String name;
  final String description;
  final String category;
  final String ageLimit;
  final String eventRule;
  final List<String> playersId;
  final List<String> eventsId;
  final List<String> photosStageId;

  Show({
    required this.createdAt,
    required this.updateAt,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.category,
    required this.ageLimit,
    required this.eventRule,
    required this.playersId,
    required this.eventsId,
    required this.photosStageId,
  });
}
