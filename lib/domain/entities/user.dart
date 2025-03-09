import 'package:equatable/equatable.dart';

class User extends Equatable {
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

  const User({
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

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        firstName,
        lastName,
        imageUrl,
        phoneNumber,
        age,
        eMail,
        city,
        isPhoneActive,
        fcmToken,
        role,
        favoriteShows,
        favoriteStages,
        favoritePlayers,
        ticketsId,
      ];

  factory User.fromMap(final Map<String, dynamic> data) {
    return User(
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

  Map<String, dynamic> toMap() {
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
}
