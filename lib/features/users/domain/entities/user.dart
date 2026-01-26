import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/common/enum/enums.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class User extends Equatable {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: '_createdAt')
  final String createdAt;

  @JsonKey(name: '_updatedAt')
  final String updatedAt;

  final String firstName, lastName;
  final String imageUrl;
  final String phoneNumber;
  final String eMail;
  final String city;
  final bool isPhoneActive;
  final String fcmToken;

  // 🔥 Firebase'den String gelir, Flutter'da Enum olarak kullanılır
  @JsonKey(fromJson: UserRole.fromString, toJson: _userRoleToString)
  final UserRole role;

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

  // --------------------------------------------------------------------------
  // JsonSerializable Metotları (g.dart için)
  // --------------------------------------------------------------------------
  factory User.fromJson(final Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Enum'ı Firestore'a yazarken String'e geri çevirmek için yardımcı metot
  static String _userRoleToString(final UserRole role) => role.name;

  // --------------------------------------------------------------------------
  // Equatable: Nesne kıyaslaması ve UI tetiklenmesi için tüm alanlar
  // --------------------------------------------------------------------------
  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        firstName,
        lastName,
        imageUrl,
        phoneNumber,
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

  // --------------------------------------------------------------------------
  // copyWith: Nesnenin kopyasını üretmek için (State Management dostu)
  // --------------------------------------------------------------------------
  User copyWith({
    final String? id,
    final String? createdAt,
    final String? updatedAt,
    final String? firstName,
    final String? lastName,
    final String? imageUrl,
    final String? phoneNumber,
    final String? eMail,
    final String? city,
    final bool? isPhoneActive,
    final String? fcmToken,
    final UserRole? role,
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

  // --------------------------------------------------------------------------
  // User.empty: Yeni kayıt olan kullanıcılar için taslak oluşturur
  // --------------------------------------------------------------------------
  factory User.empty(final String id) => User(
        id: id,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: '',
        lastName: '',
        imageUrl: '',
        phoneNumber: '',
        eMail: '',
        city: '',
        isPhoneActive: false,
        fcmToken: '',
        role: UserRole.user,
        favoriteShows: const [],
        favoriteStages: const [],
        favoritePlayers: const [],
        ticketsId: const [],
      );
}
