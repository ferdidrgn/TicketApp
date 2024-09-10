class Player {
  final String createdAt;
  final String updateAt;
  final String id;
  final String name;
  final String surname;
  final String bio;
  final String? imageUrl;
  final List<String> showsId;

  Player({
    required this.createdAt,
    required this.updateAt,
    required this.id,
    required this.name,
    required this.surname,
    required this.bio,
    this.imageUrl,
    required this.showsId,
  });
}
