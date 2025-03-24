import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;
  final String? phoneNumber;
  final int? age;
  final String? eMail;
  final String? city;
  final bool? isPhoneActive;
  final String? fcmToken;
  final String? role;
  final List<String?>? favoriteShows;
  final List<String?>? favoriteStages;
  final List<String?>? favoritePlayers;
  final List<String?>? ticketsId;

  const User({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.firstName,
    this.lastName,
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

  factory User.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return User();
    return User(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      age: data['age'] as int?,
      eMail: data['eMail'] as String?,
      city: data['city'] as String?,
      isPhoneActive: data['isPhoneActive'] as bool?,
      fcmToken: data['fcmToken'] as String?,
      role: data['role'] as String?,
      favoriteShows: (data['favoriteShows'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
      favoriteStages: (data['favoriteStages'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
      favoritePlayers: (data['favoritePlayers'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
      ticketsId: (data['ticketsId'] as List<dynamic>?)
          ?.map((final e) => e as String?)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
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
