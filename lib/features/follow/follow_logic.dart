import '../../core/services/push/notif_prefs.dart';

/// Takip edilebilir varlık türü. "Takip" = favori semantiği: AYNI `User`
/// alanları kullanılır (yeni koleksiyon yok). Oyun kalbi "Favori" kalır.
enum FollowKind {
  player('favoritePlayers'),
  stage('favoriteStages'),
  team('favoriteTeams');

  final String field;
  const FollowKind(this.field);
}

/// Düğme etiketi / ekran okuyucu metni (kalp ikonu korunur).
String followLabel({required final bool following}) =>
    following ? 'Takibi bırak' : 'Takip et';

/// Durum sözcüğü: "Takiptesin" / "Takip et".
String followStateWord({required final bool following}) =>
    following ? 'Takiptesin' : 'Takip et';

/// "Yeni oyun bildirimlerini aç?" önerisi: cihazda daha önce gösterilmediyse
/// VE tercih biliniyor ve `newShows` kapalıysa. Varsayılan ASLA kendiliğinden
/// açılmaz; yalnız kullanıcı onaylarsa.
bool shouldOfferNewShows({
  required final bool alreadyOffered,
  required final NotifPrefs? prefs,
}) =>
    !alreadyOffered && prefs != null && !prefs.newShows;

/// Ham `User` belgesinden takip kümeleri (savunmacı).
Map<FollowKind, Set<String>> followSetsFromUser(final Map<String, dynamic>? data) =>
    {
      for (final FollowKind k in FollowKind.values)
        k: {
          if (data != null && data[k.field] is List)
            ...(data[k.field] as List).whereType<String>(),
        },
    };
