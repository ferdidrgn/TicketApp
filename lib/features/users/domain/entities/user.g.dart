// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['_id'] as String,
      createdAt: json['_createdAt'] as String,
      updatedAt: json['_updatedAt'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      imageUrl: json['imageUrl'] as String,
      phoneNumber: json['phoneNumber'] as String,
      eMail: json['eMail'] as String,
      city: json['city'] as String,
      isPhoneActive: json['isPhoneActive'] as bool,
      fcmToken: json['fcmToken'] as String,
      role: UserRole.fromString(json['role'] as String?),
      favoriteShows: (json['favoriteShows'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      favoriteStages: (json['favoriteStages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      favoritePlayers: (json['favoritePlayers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ticketsId:
          (json['ticketsId'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      '_id': instance.id,
      '_createdAt': instance.createdAt,
      '_updatedAt': instance.updatedAt,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'imageUrl': instance.imageUrl,
      'phoneNumber': instance.phoneNumber,
      'eMail': instance.eMail,
      'city': instance.city,
      'isPhoneActive': instance.isPhoneActive,
      'fcmToken': instance.fcmToken,
      'role': User._userRoleToString(instance.role),
      'favoriteShows': instance.favoriteShows,
      'favoriteStages': instance.favoriteStages,
      'favoritePlayers': instance.favoritePlayers,
      'ticketsId': instance.ticketsId,
    };
