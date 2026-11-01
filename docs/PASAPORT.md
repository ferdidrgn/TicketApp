# Tiyatro Pasaportu (İŞ G-1)

Kullanıcının izlediği oyunlar, sahne damgaları, sezon sayacı ve rozetleri. **Yeni yazım yok**: her şey kullanıcının kendi `Ticket` kayıtlarından istemcide hesaplanır (Firestore kuralı: bilet yalnız sahibince okunur).

- Mobil: `lib/features/passport/` (çekirdek `domain/passport.dart`, ekran `presentation/pages/passport_page.dart`), rota `/passport/:userId` (korumalı), giriş noktası Biletlerim ekranındaki "Pasaportum" düğmesi.
- Web: `/pasaport` (`site/pasaport.html`, `js/pages/pasaport.js`, `js/pasaport-cekirdek.js`, `css/pasaport.css`), hesap menüsünde "Pasaportum". Sitemap/prerender'da YOK, `robots.txt` Disallow, sayfada `noindex`.
- Giriş gerekli; başkasına açık profil yok. Paylaşım görselinde ad/telefon/e-posta yok (mobil: yalnız sayılar + rozet adları; web canvas kartı: afişsiz metin + damga).

## 'İZLENDİ' tanımı
Bir bilet izlenmiş sayılır eğer:
1. iptal edilmemiş (`paymentStatus != cancelled`, `cancelledAt` boş) VE `paymentStatus != no_show` (gelmedi), VE
2. `usedAt` dolu (kapıdan geçti) VEYA seans tarihi ayrıştırılabilir ve **şu andan önce** (kesin `<`).

Ayrıştırılamayan / boş tarih ve `usedAt` yok → izlendi **sayılmaz**. Yalnız gün verilirse (`27.10.2026`) gün sonu (23:59) kabul edilir. Taşan tarih (`31.02.2026`) geçersizdir.
Aynı seansa (`eventId`) ait birden çok bilet tek izleme; "oyun" = farklı `showId` (yoksa oyun adı).

### Test vektörleri (now = 28.10.2026 12:00)
Aynı örnekler: `test/passport/passport_test.dart` ve `node site/tools/pasaport-test.mjs`.

| # | Bilet | Beklenen |
|---|---|---|
| V1 | `15.10.2026,20:00`, paid | izlendi |
| V2 | `15.11.2026,20:00`, pay_at_venue | hayır |
| V3 | `15.11.2026,20:00`, usedAt dolu | izlendi |
| V4 | geçmiş, cancelled | hayır |
| V5 | geçmiş, no_show | hayır |
| V6 | geçmiş, iptal işareti (cancelledAt) | hayır |
| V7 | usedAt dolu + no_show | hayır |
| V8 | `yakında` | hayır |
| V9 | boş tarih | hayır |
| V10 | `2026-09-01T18:00:00Z` | izlendi |
| V11 | `31.02.2026,20:00` | hayır |
| V12 | `27.10.2026` | izlendi |
| V13 | `28.10.2026` (gün sonu) | hayır |
| V14 | `28.10.2026,11:59` | izlendi |
| V15 | `28.10.2026,12:00` | hayır |

Özet senaryoları S1-S5 (aynı iki test dosyasında): karışık biletler (3 izleme, 2 oyun, 2 sahne, bu yıl 1), boş durum, sadık seyirci, 5 sahne/5 oyun (3 rozet), adsız oyun + paylaşım metni.

## Rozetler (yalnız gerçek veriden; v1'de sunucuya yazılmaz)
| Rozet | Kural |
|---|---|
| İlk perde | 1 oyun izle |
| 5 farklı sahne | 5 farklı sahnede izle |
| Sadık seyirci | Aynı sahnede 3 ayrı seans |
| Sezon yıldızı | Bu takvim yılında 5 farklı oyun |
| On perde | Toplam 10 farklı oyun |

Kilitli rozette nasıl kazanılacağı ve ilerleme (n/hedef) gösterilir. Sezon sayacı "bu yıl N oyun" seans tarihinin yılına göre.

## v2 (yapılmadı)
`User.badges` (sunucu): kalıcı rozet, silinen oyun/sahne kayıtlarından bağımsız tarihçe, rozet bildirimi. Şehir damgası: mobilde `Stage` varlığında şehir alanı yok, bu yüzden v1'de damga sahne başınadır.

## Bilinen sınırlar
- Mobil "izlendi" tarihi: canlı `Event.date` varsa o, yoksa biletteki `eventDate`; web: biletteki `eventDate`, yoksa seans kaydı.
- Web `/pasaport` akışı tarayıcıda emülatörle uçtan uca doğrulanmadı (yalnız çekirdek birim testi + sunucu 200 + sözdizimi).
