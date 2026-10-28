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
- Uygulama ici `Notification` kutusu tercihten bagimsiz yazilmaya devam eder (kullanici kapattigi kategoride yalniz **push** gitmez; `changes` icin kutu da yazilir).

## 3. Kullananlar (ajanlar)
- Mobil ayarlar + web `/ayarlar` bu semayi yazar (yalniz `notifPrefs` alani, tek `update`/`set merge`).
- Admin/ekip onizlemesi: `prefs: { optedOut: { <kategori>: n }, of }` — kisi listesi YOK.
- Yorum daveti baglantisi: `/oyun/<slug>-<id>?yorum=1`; push `data.route` ayni yol.
