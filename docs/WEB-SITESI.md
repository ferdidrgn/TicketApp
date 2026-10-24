# TiyatRol Web Sitesi ("Perde") — HTML / CSS / JavaScript

Flutter web yerine **gerçek, ayrı bir web sitesi**. Klasör: `site/` (dal: `tiyatrol-web-perde`).
Derleme gerekmez; saf HTML + CSS + ES modülleri. Veri, mobil uygulamayla **aynı Firestore** (`ticketappflutter`).
Satın alma yok: bilet uygulamadan ya da harici organizatör bağlantısından alınır. Giriş yalnızca mobilde ve web yönetim panelinde.

## Yerelde çalıştırma
```bash
cd site
python -m http.server 8200
```
Sadece ana sayfa/Keşfet için yeterli. `/oyun/...` gibi temiz adresler için Firebase emülatörü kullan:
```bash
firebase emulators:start --only hosting
```
(`firebase.json` içindeki `web` hedefi `site/` klasörünü yayınlar.)

## Yayınlama
1. Firebase Console → Hosting → "Başka site ekle" (ör. `tiyatrol-web`).
2. `firebase target:apply hosting web tiyatrol-web`
3. `firebase deploy --only hosting:web`
Sonra istediğin alan adını bu siteye bağla (Hosting → Özel alan adı).

## Sayfalar
| Adres | Dosya | Ne |
|---|---|---|
| `/` | `index.html` + `js/pages/home.js` | Vitrin: slayt, tür daireleri, raylar, tarih şeridi + ajanda, Top 10, son çağrı, bütçe kadranı, sahneler, oyuncular |
| `/kesfet` | `kesfet.html` | Süzgeçli katalog (tür, zaman, sıralama; oyuncu/sahne/topluluk) |
| `/oyun/ad-ID` | `oyun.html` | Program ve bilet: yapışkan bilet, seanslar, kadro, harita, galeri, takvime ekle (Google/Outlook/Yahoo/.ics) |
| `/oyuncu/…`, `/sahne/…`, `/topluluk/…` | aynı mantık | Künye sayfaları |
| `/yonetim` | `yonetim/index.html` | **Yönetim paneli** |
| `/yardim`, `/uygulama`, `/gizlilik`, `/sartlar` | statik | |

## Yönetim paneli — nasıl girilir?
Adres: `https://<site-adresin>/yonetim` (altbilgide küçük "Yönetim" bağlantısı da var). Arama motorlarına kapalıdır.
1. Panelde (ya da mobilde) Google/e-posta ile bir kez giriş yap → `User/{uid}` belgesi oluşur.
2. Firebase Console → Firestore → `User` → kendi belgen → `role` alanını `admin` yap (kimse bunu uygulamadan kendine veremez).
3. Panele tekrar gir: Oyunlar, Seanslar, Sahneler, Topluluklar, Oyuncular, Kampanyalar CRUD; biletler salt okunur; görünüm (tema) ayarı.

**Güvenlik:** panel yetkiyi arayüzde `role == admin` ile kontrol eder; **asıl koruma `firestore.rules`**'dur
(yazma = `isAdmin()`). `firebase deploy --only firestore:rules` yapılmadan panel güvenli sayılmaz.
Ayrıca: Authentication → Yetkili alan adlarına site adresini ekle; Storage kurallarında `images/**` yazmasını yalnızca admin'e aç.

## Tema
`js/theme.js`: mod (sistem/gündüz/gece) × palet (Şarap = TiyatRol, Okyanus, Orman, Menekşe, Kehribar, **özel renk**).
Ayarlar sağ üstteki palet simgesinde; seçim `localStorage`'da. Tüm renkler `css/theme.css` değişkenlerinden (`--accent`, `--bg`…) gelir;
ekrana sabit renk gömülmez (bilet kâğıdı hariç).

## Veri kuralları (mobille aynı)
- `Event.showId` tek doğruluk kaynağı, `Show.eventsId` yedek. Panel seans kaydederken ikisini de günceller.
- Tarihler `gg.aa.yyyy,ss:dd` biçiminde saklanır (`js/util.js › tarihAyristir`).
- Tarihi geçen seans silinmez: oyun "bitti" sayılır; bileti olan oyun/sahne/seans silinemez.

## Dosya haritası
`js/firebase.js` (SDK) · `js/store.js` (okuma + türetme) · `js/ui.js` (başlık, arama önerileri, kartlar) · `js/detay.js` (program/bilet iskeleti, takvim, harita) ·
`js/admin/schema.js` (alan şeması) · `js/admin/admin.js` (panel).
