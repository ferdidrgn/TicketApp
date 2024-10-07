class User {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String phoneNumber;
  final int? age;
  final String? eMail;
  final String? city;
  final bool? isPhoneActive;
  final String? fcmToken;
  final String? role;
  final List<String>? favoriteShows;
  final List<String>? favoriteStages;
  final List<String>? favoritePlayers;
  final List<String>? ticketsId;

  User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    required this.phoneNumber,
    this.age,
    this.eMail,
    this.city,
    this.isPhoneActive,
    this.fcmToken,
    this.role,
    this.favoriteShows,
    this.favoriteStages,
    this.favoritePlayers,
    this.ticketsId
  });
}