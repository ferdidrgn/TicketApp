/// Kullanıcının favorileyebileceği içerik türleri.
/// Her tür, User dökümanındaki ilgili Firestore alanına karşılık gelir.
enum FavoriteType { show, stage, player }

extension FavoriteTypeX on FavoriteType {
  /// User Firestore dökümanındaki karşılık gelen liste alanı.
  String get fieldName {
    switch (this) {
      case FavoriteType.show:
        return 'favoriteShows';
      case FavoriteType.stage:
        return 'favoriteStages';
      case FavoriteType.player:
        return 'favoritePlayers';
    }
  }
}
