# Bildirim tercihleri ve etkinlik otomasyonu (N-1 + N-2) — SÖZLEŞME

Durum: 28.10.2026. Ilgili: `docs/BILDIRIM-ISTATISTIK.md` (bolum 4, 5, 11), `functions/src/notify-prefs.js`.

## 1. Sema: `User/{uid}.notifPrefs`

| Alan | Tur | Varsayilan | Anlam | Kategori |
|---|---|---|---|---|
| `loudAlarm` | bool | **false** | Sessizdeyken de sesli hatirlat (mevcut) | (kanal secimi) |
| `reminders` | bool | **true** | Seans hatirlatma 24 sa / 2 sa | `reminder` |
| `changes` | bool | **true** | Iptal / erteleme / saat degisikligi (islemsel) | `change` |
| `thankYou` | bool | **true** | Seans sonrasi tesekkur + yorum daveti | `thankYou` |
| `newShows` | bool | **false** | Yeni oyun / seans duyurulari (kesif) | `newShows` |
| `marketing` | bool | **false** | Kampanya / pazarlama | `marketing` |
| `quietStart` | metin `HH:MM` | yok | Sessiz saat baslangici (Istanbul saati) | |
| `quietEnd` | metin `HH:MM` | yok | Sessiz saat bitisi (gece yarisini asabilir: 23:00-08:00) | |

Kurallar: alan yok = varsayilan. Bilinmeyen anahtar yazilamaz (rules `hasOnly`). Bool alanlar yalniz bool; `quietStart/End` yalniz gecerli `HH:MM` ya da bos degil (`null` yazilmaz, alan silinerek kapatilir -> iki alan birlikte olmali).
Geriye donuk uyumlu: eski `{loudAlarm}` belgeleri gecerlidir.

## 2. Sunucu: `shouldSend(prefs, category, now)` — `functions/src/notify-prefs.js`

Kategoriler: `change`, `reminder`, `thankYou`, `newShows`, `marketing`, `announcement` (admin serbest mesaj, `genel`/sahne sablonlari: tercihe bagli DEGIL, islemsel kabul edilir), `alarm` (sahne kumandasi sablonlari; tercihe bagli degil).

- Kategori anahtari kapaliysa -> gonderilmez (`reason:'category'`).
- Sessiz saat (`quietStart..quietEnd`, Istanbul saati) icindeyse: **muaf** kategoriler (`change`, `announcement`, `alarm`, seansa <=3 sa kala `reminder`) yine gider; digerleri (`thankYou`, `newShows`, `marketing`, uzak `reminder`) **gonderilmez, ertelenir** (`reason:'quiet'`; teşekkur isi sonraki calismada tekrar dener, `bitti` yasi <12 sa penceresi icinde).
- Uygulama ici kutu: `change` (iptal/erteleme) kutuya HER ZAMAN yazilir (yalniz push tercihe baglidir). Diger kapali kategorilerde (`reminders`, `thankYou`, `newShows`, `marketing`) kutu da yazilmaz. `announcement` ve `alarm` kapatilamaz.
- Sessiz saatte ertelenen kullanici icin kilit/bayrak yazilmaz; sonraki calisma (15 dk) yeniden dener (24 sa hatirlatma kendi penceresi icinde, teşekkur "bitti" yasi < 12 sa icinde).

## 3. Kullananlar (ajanlar)
- Mobil ayarlar + web `/ayarlar` bu semayi yazar (yalniz `notifPrefs` alani, tek `update`/`set merge`).
- Admin/ekip onizlemesi: `prefs: { optedOut: { <kategori>: n }, of }` — kisi listesi YOK.
- Yorum daveti baglantisi: `/oyun/<slug>-<id>?yorum=1`; push `data.route` ayni yol.

## 4. Uygulama (28.10.2026)

### Sunucu (`functions/src/notify.js`, `notify-prefs.js`)
- `loadRecipients` artik `prefs` (uid -> ham notifPrefs) de doner; `filterByPrefs(rc, kategori, an, {eventMs})` token'li alicilari eler ve `suppressed:{category, quiet}` sayar; loudAlarm mantigina dokunulmadi.
- **Admin/ekip gonderimi**: sablon -> kategori: `iptal`/`ertelendi` = `change`; sahne sablonlari (`baslamak_uzere`, `basladi`, `ara`, `ara_bitiyor`, `bitti`) = `alarm` (muaf); `genel` = `announcement` (muaf). Yalniz admin `genel` icin `category: 'newShows' | 'marketing'` verebilir -> tercihe baglanir; **"Tum kullanicilar" (konu) hedefiyle gonderilemez** (`failed-precondition`, tercih bilinemez). `NotificationLog`: `category`, `suppressed`.
- **Onizleme** (`adminNotifyPreview`, `teamNotifyPreview`): `prefs = { category, of, optedOut, quietNow, willSend, withQuietHours, byCategory:{changes,reminders,thankYou,newShows,marketing} }`. Yalniz sayilar; kisi listesi/uid YOK. Panel: "X kisiden Y kisi bu bildirim turunu kapatti".
- **N-1a iptal/erteleme** — Firestore tetikleyici `onEventChanged` (`onDocumentUpdated('Event/{eventId}')`, YENI zamanlanmis is degil). Veri modeli: `Event.cancelled` (admin formunda metin alani, `evet` yaz; `true`/`iptal`/`Event.status=='cancelled'` da kabul) -> `iptal`; `Event.date` ileri bir zamana degisirse (eski tarih <=1 sa once ya da gelecekte, yeni tarih gelecekte) -> `ertelendi`. Iptalken tarih degisimi / iptali geri alma bildirim uretmez. Alicilar: o seansin aktif (iptal/gelmedi olmayan) bilet sahipleri; `changes` kapaliysa push yok (kutu var); sessiz saatten muaf. Idempotent: kullanici basina `Notification/chg_iptal_<event>_<uid>` / `chg_move_<event>_<yeniMs>_<uid>` `create()` kilidi + tek `NotificationLog/chg_iptal_<event>` / `chg_move_<event>_<yeniMs>` (durum `sending` -> `done`; yarim kalirsa yeniden denemede tamamlanir). Gunluk: `auto:true, sentBy:'system'`, yalniz sayilar. Odeme/iade bilgisi yoktur (satis rezervasyon modunda).
  - **Bolge uyarisi**: tetikleyici `europe-west1`'de; Firestore veritabani baska bolgedeyse `functions/index.js`'te `region` ayni olmali (deploy hatasi verir).
  - Bilinen sinir: tarih degisince mevcut Ticket.eventDate (bilete yazilan metin) otomatik guncellenmez; ayrica `remind24At/remind2At` bayraklari ve `rem*_<event>_<uid>` kilitleri eski tarihe gore konmustur -> ertelenen seansta hatirlatma tekrar gitmeyebilir (kasitli olarak degistirilmedi).
- **Iptal edilmis seansa** otomatik hatirlatma ve tesekkur gitmez.
- **N-1b tesekkur** — `eventReminders` (15 dk) icinde `thankYouRun` (yeni is yok): seans bitisi = baslangic + `Show.duration` (dk/saat; cozulemezse 120 dk); "bitti" yasi 1–12 sa olan seanslar; alici: `usedAt` dolu (kapidan gecmis) ve iptal/gelmedi olmayan biletler (`Config/bildirim.thankYouAll=true` ise usedAt'i olmayan gecerli rezervasyonlar da). Kilit: `Notification/thank_<event>_<uid>` create() + bilet `thankedAt` bayragi; `System/thankYou_<event>` bitis isareti (sessiz saatte bekleyen kalmayinca yazilir). `data.route = /show/<slug>-<showId>?yorum=1` (mobil; `PushRoutes` beyaz listesi bu tek sorguyu kabul eder; web karsiligi `/oyun/<slug>-<id>?yorum=1`). Kapatma: `Config/bildirim.thankYou=false` (varsayilan acik; panelde anahtar).
- **N-1c alarm2h** — `Config/bildirim.alarm2h` (varsayilan **KAPALI**, panelde anahtar). Aciksa 2 saatlik hatirlatma `alarm` turunde gider: `notifPrefs.loudAlarm` acik olanlara `tiyatrol_alarm` kanalindan, digerlerine normal kanaldan (iki multicast). 24 saatlik hatirlatma ve kutu turu (`reminder`) degismez. `data.kind` = `alarm` olur (mobil on planda uyari penceresi acabilir).
- Rules: `Config/bildirim` `alarm2h`, `thankYou`, `thankYouAll` opsiyonel bool.

### Istemciler
- Mobil: Ayarlar > Izinler: kategori anahtarlari + sessiz saat (`NotificationPrefsRows`, `lib/core/services/push/notif_prefs*.dart`). Yazim **noktali yol** (`notifPrefs.reminders` ...) — `loudAlarm` ve diger alanlar ezilmez (eski `{'notifPrefs': {'loudAlarm': x}}` yazimlari duzeltildi). Oturum yoksa bolum gizli.
- Web: `/ayarlar` > Bildirimler karti (`site/js/bildirim-tercih.js`), giris yapmis kullanici icin; tum harita tek `updateDoc`.
- Admin: Event formunda "Seans iptal edildi" alani; Sahne kumandasi'nda "Teşekkur" ve "2 saat alarm" anahtarlari.

### Testler
`functions/test/notify-prefs-unit.test.js` (emulatorsuz), `notify-auto.test.js` (16 senaryo), `rules.test.js` (notifPrefs semasi + Config/bildirim), Dart: `test/notif_prefs_test.dart`, `push_notifications_test.dart` (rota).
