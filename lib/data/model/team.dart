class Team {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> photosId;
  final List<String> showsId;

  Team({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.photosId,
    required this.showsId,
    required this.createdAt,
    required this.updatedAt,
  });
}