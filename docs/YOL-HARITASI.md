# TiyatRol Web Sitesi — Yol Haritası (25.10.2026)

Kaynaklar: mobil uygulama ↔ site denetimi (kod okuma), rakip/referans özet listesi (bilgi birikimine dayalı; `rea` aracı bu oturumda
yoktu, canlı site taraması yapılmadı — güncel arayüz ayrıntıları uygulanmadan önce tarayıcıda doğrulanmalı).
Kural: webde **satın alma yok**, **giriş yok** (yalnızca mobil + `/yonetim`). Favori webde tarayıcıda (localStorage) tutulur.

## Dalga 1 — Çekirdek (bu turda)
| # | İş | Durum |
|---|---|---|
| 1 | İl seçici (81 il, konumla, hatırlar) + il bazlı Ana Sayfa / Keşfet | yapıldı |
| 2 | Stage'den il türetme (adres, ilçe, koordinat) + harici oyunlar için `externalVenue*` | yapıldı |
| 3 | `/harita`: tüm mekânlar + harici bilet mekânları, liste↔harita, süzgeç, Yakınımda 50 km | yapıldı |
| 4 | Harici platform rozeti (kart, slayt, oyun sayfası) | yapıldı |
| 5 | Kayan vitrin (otomatik + ok + kaydırma) | yapıldı |
| 6 | Oyun / oyuncu / topluluk / sahne sayfaları yeniden | yapıldı |
| 7 | `/favoriler` sayfası (Oyunlar/Sahneler/Sanatçılar, Sahnede/Perdesi kapananlar) | yapıldı |
| 8 | Kampanyalar sayfası: kupon kartı, geçerlilik etiketi | yapıldı |
| 9 | Yorumlar ve puan (oyun sayfası, salt okuma) + kartlarda ★ | yapıldı |
| 10 | Keşfet: Yarın / Hafta sonu, yaş/çocuk, fiyat, "ücretsiz" süzgeçleri | yapıldı |
| 11 | Günün repliği + oyuncu hikâyeleri (ana sayfa) | yapıldı |
| 12 | "Son baktıkların" + son aramalar | yapıldı |
| 13 | Ayarlar sayfası: 6 tema stili (Gündüz, Gece, Oto, Doğa, Ahenk, Özel) + önizleme | kısmen (Doğa/Ahenk paletleri eklendi; ayrı sayfa sırada) |
| 14 | Yardım/SSS/Gizlilik/Şartlar → `AppTools` (tek kaynak) | sırada |

## Dalga 2
- Şehir landing sayfaları (`/il/istanbul`) build'de statik + JSON-LD ItemList + sitemap
- Seyirci karnesi / rozet tanıtım sayfası (uygulamaya yönlendirir)
- Seans hatırlatma `.ics` alarmı (VALARM)
- Koltuk planı salt gösterim (`Seats`)
- Kapanışa yakın / yeni eklendi rozetleri, benzer oyun skoru
- Blog / rehber (statik MD → önceden üretim)

## Dalga 3
- Web push + e-posta hatırlatma (Cloud Function + FCM) — hatırlatma veri modeli gerekir
- EN dil anahtarı
- E-bülten
- Erişilebilirlik alanları (Show/Stage: tekerlekli sandalye, işaret dili, ses betimleme) + admin + filtre

## Veri modeli işleri
1. `Stage.city` (+ `district`) alanı; admin formunda seçim. Şimdilik kod adresten/koordinattan türetir.
2. `Show.externalCity` (harici oyun için); şimdilik `externalVenueAddress/Lat/Lng`'den türetilir.
3. `Player.achievements` biçimi mobil (liste-harita) ↔ web (metin satırı) farkı — tek biçim seç.
4. `Campaign`: `code`, `showId`, `stageId` alanları (kupon + içeriğe bağlama).
5. `Show.ratingAvg/ratingCount` önbellek alanı (kart rozetleri için).
6. `AppTools` tek kaynak (web statik kopyalar kalkar).

## Mobile geri taşınacaklar (dengeleme)
Son çağrı, Top 10, canlı geri sayım, yapışkan bilet paneli + bölüm sekmeleri, ay filtreli seans listesi,
takvim menüsü (Outlook/Yahoo seçimi), kayan seans şeridi, "birlikte oynadıkları", sahne "bu sahnede oynayanlar" sekmesi.
Bunlar Flutter dalı (`sahne-ui-v3`) için ayrı bir tur olarak yapılır.

## Güvenlik / yayın
- `firestore.rules` yayınla; Auth yetkili alan adı; Storage `images/**` yalnızca admin
- Hosting sitesi aç (`tiyatrol-web`), `firebase deploy --only hosting:web`
- Search Console: sitemap gönder; AdSense için gizlilik metnindeki `[Ad Soyad]`/`[Adres]` doldur
