# Takip et + yeni oyun/seans bildirimi (F-1)

- "Takip" = favori alanları: `User.favoritePlayers / favoriteStages / favoriteTeams` (yeni koleksiyon yok). Oyun kalbi "Favori" kalır.
- Bildirim kategorisi `newShows`: **varsayılan kapalı**; kullanıcı `notifPrefs.newShows = true` yapmadıkça ne push ne uygulama içi kutu.
- Takip et'e ilk basışta (yalnız tercih kapalıysa, cihaz başına bir kez) "Yeni oyun bildirimlerini aç?" önerisi çıkar; kendiliğinden açılmaz (web: `fav.js`, mobil: `lib/features/follow/`).
- Tetikleyiciler (`functions/src/follow-notify.js`, index.js `onEventCreatedFollow`, `onShowEventsLinkedFollow`): yeni Event, Event.showId bağlanması ya da Show.eventsId'e eklenme. Zamanlanmış iş yok.
- Kadro: `Show.nowPlayersId` (eski kadro `oldPlayersId` bildirim tetiklemez), topluluk `Show.teamId`, sahne `Event.stageId`. Show: `Event.showId` tek doğruluk kaynağı, boşsa `Show.eventsId` yedeği.
- Tek kullanıcıya tek mesaj, öncelik: oyuncu > topluluk > sahne. Günde en çok 3 takip bildirimi (`UserLimits.followDay/followCount`), aynı oyun için 24 saatte 1 (`UserLimits.followShows`).
- İdempotent: `Event.followNotified`, kullanıcı başına kilit `Notification/fol_<event>_<uid>`, `NotificationLog/fol_<event>` (yalnız sayılar).
- Geçmiş / iptal / tarihsiz seans için gönderilmez. Sessiz saatte kutu yazılır, push gitmez.
- Kapatma: `Config/bildirim.followNotify = false`.
- Maliyet: takipçi sorgusu `array-contains` + `notifPrefs.newShows == true`; **bileşik dizin gerekir** (3 adet, `firestore.indexes.json`). Dizin dağıtılmamışsa sorgu otomatik bellek içi süzmeye düşer (daha çok okuma). Üst sınır 5.000 benzersiz takipçi/seans, 500'lük sayfalar.
- Deep link: `/show/<slug>-<id>` (PushRoutes beyaz listesinde).
- `followersCount` sayacı eklenmedi (ek yazma/maliyet).
