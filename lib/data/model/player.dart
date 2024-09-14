class Player {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String? imageUrl;
  final List<String> showsId;

  Player({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    this.imageUrl,
    required this.showsId,
  });
}
