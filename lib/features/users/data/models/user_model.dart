import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? firstName, lastName;
  final String? imageUrl;
  final String? phoneNumber;
  final String? eMail;
  final String? city;
  final bool? isPhoneActive;
  final String? fcmToken;
  final String? role; // Firestore'da String olarak tutulur
  final List<String>? favoriteShows;
  final List<String>? favoriteStages;
  final List<String>? favoritePlayers;
  final List<String>? ticketsId;

  const UserModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.phoneNumber,
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

  /// 🔥 Firestore'dan güvenli okuma (Map null gelemez varsayımıyla)
  factory UserModel.fromFirestore(final Map<String, dynamic> data) => UserModel(
        id: data['_id'] as String?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        firstName: data['firstName'] as String?,
        lastName: data['lastName'] as String?,
        imageUrl: data['imageUrl'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
        eMail: data['eMail'] as String?,
        city: data['city'] as String?,
        isPhoneActive: data['isPhoneActive'] as bool?,
        fcmToken: data['fcmToken'] as String?,
        role: data['role'] as String?,
        // Listeleri güvenli cast etme
        favoriteShows:
            (data['favoriteShows'] as List?)?.map((e) => e.toString()).toList(),
        favoriteStages: (data['favoriteStages'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        favoritePlayers: (data['favoritePlayers'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        ticketsId:
            (data['ticketsId'] as List?)?.map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'imageUrl': imageUrl,
        'phoneNumber': phoneNumber,
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
