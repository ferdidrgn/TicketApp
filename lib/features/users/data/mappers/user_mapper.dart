import '../../../../core/common/enum/enums.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

extension UserModelMapper on UserModel {
  /// Model -> Entity (Okuma)
  User toEntity() => User(
        id: id ?? '',
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        imageUrl: imageUrl ?? '',
        // UI tarafında placeholder kullanılabilir
        phoneNumber: phoneNumber ?? '',
        eMail: eMail ?? '',
        city: city ?? '',
        isPhoneActive: isPhoneActive ?? false,
        fcmToken: fcmToken ?? '',
        // String -> Enum Dönüşümü
        role: UserRole.fromString(role),
        // Null listeleri boş listeye çevir
        favoriteShows: favoriteShows?.whereType<String>().toList() ?? [],
        favoriteStages: favoriteStages?.whereType<String>().toList() ?? [],
        favoritePlayers: favoritePlayers?.whereType<String>().toList() ?? [],
        ticketsId: ticketsId?.whereType<String>().toList() ?? [],
      );
}

extension UserEntityMapper on User {
  /// Entity -> Model (Yazma/Güncelleme)
  UserModel toModel() => UserModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        firstName: firstName,
        lastName: lastName,
        imageUrl: imageUrl,
        phoneNumber: phoneNumber,
        eMail: eMail,
        city: city,
        isPhoneActive: isPhoneActive,
        fcmToken: fcmToken,
        // Enum -> String Dönüşümü
        role: role.name,
        favoriteShows: favoriteShows,
        favoriteStages: favoriteStages,
        favoritePlayers: favoritePlayers,
        ticketsId: ticketsId,
      );
}
