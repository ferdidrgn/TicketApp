import '../../domain/entities/user.dart';

class UserModel {
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

  const UserModel({
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

  factory UserModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const UserModel();
    return UserModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
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
      favoriteShows: (data['favoriteShows'] as List?)
          ?.map((final e) => e as String?)
          .toList(),
      favoriteStages: (data['favoriteStages'] as List?)
          ?.map((final e) => e as String?)
          .toList(),
      favoritePlayers: (data['favoritePlayers'] as List?)
          ?.map((final e) => e as String?)
          .toList(),
      ticketsId:
          (data['ticketsId'] as List?)?.map((final e) => e as String?).toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
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

  User toEntity() => User(
        id: id ?? '0',
        createdAt: createdAt ?? 'Tarih bulunamadı',
        updatedAt: updatedAt ?? 'Tarih bulunamadı',
        firstName: firstName ?? 'İsim bulunamadı',
        lastName: lastName ?? 'Soyisim bulunamadı',
        phoneNumber: phoneNumber ?? 'Telefon numarası bulunamadı',
        age: age ?? 0,
        imageUrl: imageUrl ?? 'https://example.com/default-image.png',
        eMail: eMail ?? 'E-mail bulunamadı',
        city: city ?? 'Şehir bulunamadı',
        isPhoneActive: isPhoneActive ?? false,
        fcmToken: fcmToken ?? 'FCM token bulunamadı',
        role: role ?? 'Rol bulunamadı',
        favoriteShows: favoriteShows
                ?.where((final e) => e != null)
                .map((final e) => e!)
                .toList() ??
            [],
        favoriteStages: favoriteStages
                ?.where((final e) => e != null)
                .map((final e) => e!)
                .toList() ??
            [],
        favoritePlayers: favoritePlayers
                ?.where((final e) => e != null)
                .map((final e) => e!)
                .toList() ??
            [],
        ticketsId: ticketsId
                ?.where((final e) => e != null)
                .map((final e) => e!)
                .toList() ??
            [],
      );

  factory UserModel.fromEntity(final User user) => UserModel(
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
