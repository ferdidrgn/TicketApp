import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? phoneNumber;
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

  const UserModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.phoneNumber,
    this.age,
    this.eMail,
    this.city,
    this.isPhoneActive,
    this.fcmToken,
    this.role,
    this.favoriteShows,
    this.favoriteStages,
    this.favoritePlayers,
    this.ticketsId,
  });

  factory UserModel.fromFirestore(final Map<String, dynamic> data) {
    return UserModel(
      id: data['_id'] ?? '',
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      imageUrl: data['imageUrl'],
      phoneNumber: data['phoneNumber'],
      age: data['age'],
      eMail: data['eMail'],
      city: data['city'],
      isPhoneActive: data['isPhoneActive'],
      fcmToken: data['fcmToken'],
      role: data['role'],
      favoriteShows: List<String>.from(data['favoriteShows'] ?? []),
      favoriteStages: List<String>.from(data['favoriteStages'] ?? []),
      favoritePlayers: List<String>.from(data['favoritePlayers'] ?? []),
      ticketsId: List<String>.from(data['ticketsId'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'age': age,
      'eMail': eMail,
      'city': city,
      'isPhoneActive': isPhoneActive,
      'fcmToken': fcmToken,
      'role': role,
      'favoriteShows': favoriteShows,
      'favoriteStages': favoriteStages,
      'favoritePlayers': favoritePlayers,
      'ticketsId': ticketsId,
    };
  }

  User toEntity() {
    return User(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firstName: firstName,
      lastName: lastName,
      imageUrl: imageUrl,
      phoneNumber: phoneNumber,
      age: age,
      eMail: eMail,
      city: city,
      isPhoneActive: isPhoneActive,
      fcmToken: fcmToken,
      role: role,
      favoriteShows: favoriteShows,
      favoriteStages: favoriteStages,
      favoritePlayers: favoritePlayers,
      ticketsId: ticketsId,
    );
  }

  factory UserModel.fromEntity(final User user) {
    return UserModel(
      id: user.id,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      firstName: user.firstName,
      lastName: user.lastName,
      imageUrl: user.imageUrl,
      phoneNumber: user.phoneNumber,
      age: user.age,
      eMail: user.eMail,
      city: user.city,
      isPhoneActive: user.isPhoneActive,
      fcmToken: user.fcmToken,
      role: user.role,
      favoriteShows: user.favoriteShows,
      favoriteStages: user.favoriteStages,
      favoritePlayers: user.favoritePlayers,
      ticketsId: user.ticketsId,
    );
  }
}
