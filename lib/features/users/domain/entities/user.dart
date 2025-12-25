import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String firstName;
  final String lastName;
  final String imageUrl;
  final String phoneNumber;
  final int age;
  final String eMail;
  final String city;
  final bool isPhoneActive;
  final String fcmToken;
  final String role;
  final List<String> favoriteShows;
  final List<String> favoriteStages;
  final List<String> favoritePlayers;
  final List<String> ticketsId;

  const User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.phoneNumber,
    required this.age,
    required this.eMail,
    required this.city,
    required this.isPhoneActive,
    required this.fcmToken,
    required this.role,
    required this.favoriteShows,
    required this.favoriteStages,
    required this.favoritePlayers,
    required this.ticketsId,
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

  // ---------------------------
  // copyWith metodu
  // ---------------------------
  User copyWith({
    final String? id,
    final String? createdAt,
    final String? updatedAt,
    final String? firstName,
    final String? lastName,
    final String? imageUrl,
    final String? phoneNumber,
    final int? age,
    final String? eMail,
    final String? city,
    final bool? isPhoneActive,
    final String? fcmToken,
    final String? role,
    final List<String>? favoriteShows,
    final List<String>? favoriteStages,
    final List<String>? favoritePlayers,
    final List<String>? ticketsId,
  }) =>
      User(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        imageUrl: imageUrl ?? this.imageUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        age: age ?? this.age,
        eMail: eMail ?? this.eMail,
        city: city ?? this.city,
        isPhoneActive: isPhoneActive ?? this.isPhoneActive,
        fcmToken: fcmToken ?? this.fcmToken,
        role: role ?? this.role,
        favoriteShows: favoriteShows ?? List.from(this.favoriteShows),
        favoriteStages: favoriteStages ?? List.from(this.favoriteStages),
        favoritePlayers: favoritePlayers ?? List.from(this.favoritePlayers),
        ticketsId: ticketsId ?? List.from(this.ticketsId),
      );

  // ---------------------------
  // fromMap ve toMap
  // ---------------------------
  factory User.fromMap(final Map<String, dynamic>? data) => User(
        id: data?['_id'] ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        firstName: data?['firstName'] as String? ?? 'İsim bulunamadı',
        lastName: data?['lastName'] as String? ?? 'Soyisim bulunamadı',
        imageUrl: data?['imageUrl'] as String? ??
            'https://example.com/default-image.png',
        phoneNumber:
            data?['phoneNumber'] as String? ?? 'Telefon numarası bulunamadı',
        age: data?['age'] as int? ?? 0,
        eMail: data?['eMail'] as String? ?? 'E-mail bulunamadı',
        city: data?['city'] as String? ?? 'Şehir bulunamadı',
        isPhoneActive: data?['isPhoneActive'] as bool? ?? false,
        fcmToken: data?['fcmToken'] as String? ?? 'Fcm token bulunamadı',
        role: data?['role'] as String? ?? 'Rol bulunamadı',
        favoriteShows: List<String>.from(data?['favoriteShows'] as List? ?? []),
        favoriteStages:
            List<String>.from(data?['favoriteStages'] as List? ?? []),
        favoritePlayers:
            List<String>.from(data?['favoritePlayers'] as List? ?? []),
        ticketsId: List<String>.from(data?['ticketsId'] as List? ?? []),
      );

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

// ---------------------------
  // User.empty (Başlangıç durumu)
  // ---------------------------
  factory User.empty(final String id) => User(
        id: id,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: '',
        lastName: '',
        imageUrl: '',
        phoneNumber: '',
        age: 0,
        eMail: '',
        city: '',
        isPhoneActive: false,
        fcmToken: '',
        role: 'users',
        favoriteShows: const [],
        favoriteStages: const [],
        favoritePlayers: const [],
        ticketsId: const [],
      );
}
