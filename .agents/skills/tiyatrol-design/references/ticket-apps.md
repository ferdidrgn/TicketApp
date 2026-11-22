# Bilet uygulamaları — ana sayfa, arama, yönetim (2025–2026)

Kaynak: TodayTix, DICE, Ticketmaster, Biletix, Biletinial, Mobilet, tiyatrolar.com.tr, ATG Tickets, National Theatre. Sahibe: neyi al, neyi çalma. En fazla 8 kalıp.

## 1. Afişli kategori şeridi

**Rakipler.** DICE ana sayfada Tonight / This week / Comedy yatay şerit; seçince feed anında değişir. Ticketmaster “Browse by Category” (Concerts, Arts & Theatre…). TodayTix Halloween / Plays / Kid-friendly koleksiyon hapları. Biletix ve Biletinial tür + şehir ile katalog keser. National Theatre What’s On: Events / Date / Location.

**TiyatRol.** Onaylı keşif filtresi Keşfet’teki `BrowseCategoryStrip`: gerçek `Show.category`, afişli kart, Tümü, tekrar dokununca sıfır. Ana sayfa ruh hâli (`HomeMoodPicker`) aynı türe `/discover?category=` ile gider. Arama da bu şeridi kullanır — ikinci bir chip dili icat etme.

**Alma.** Sahte “trending” rozeti, koçanlı tür kartı, her ekranda farklı kategori UI’sı.

## 2. Vitrin satırları (koleksiyon, öne çıkan)

**Rakipler.** TodayTix editorial collection satırları (Rush, new, special offer). Biletix büyük hero kaydırıcı + “24 saat içinde”. Biletinial “Bugün senin için” (AI öneri) + mekan satırı (Zorlu PSM). ATG ana sayfa: önerilen / yeni + Plays / Tours şeritleri. National Theatre: South Bank / In cinemas blokları, afiş + “Dates & tickets”.

**TiyatRol.** `HomeSpotlightCarousel` (kampanya + oyun, gerçek slayt), `HomeRail` + `HomePosterCard`, “Tümünü gör” → Keşfet. Vitrin fotoğraf; koçan değil.

**Alma.** “Sold-out hit”, “son 3 bilet”, geri sayım, from-price her kartta, her satıra bilet kromu.

## 3. Bu hafta / bu gece nabzı

**Rakipler.** DICE Tonight / This week. Ticketmaster 2026 Home: For You / Trending / Last Minute. Biletix “24 saat içinde başlayacaklar”. tiyatrolar.com.tr “Bu haftasonu / Bu ay sahnede”. Mobilet etkinliği tarih + mekanla açar.

**TiyatRol.** `HomeWeekPulse` gerçek seans sayısı; “Sıradaki seans” sayfadaki tek bilet anı (`HomeFeaturedTicket`). Yaklaşan seans listesi Firestore’dan.

**Alma.** Sahte aciliyet (uydurma stok, yanıp sönen “kaçırma”, sahte Last Minute). Nabız gerçek seans yoksa uydurulmaz.

## 4. Gerçek konum, sahte GPS yok

**Rakipler.** TodayTix şehir seçici (NYC, London…). Ticketmaster konum + ziyaret edilen şehir. DICE aramada harita (swipe / View map). Biletix/Biletinial şehir. ATG mekan + tur. National Theatre Location filtresi (South Bank / sinema / ev).

**TiyatRol.** Yakınımdakiler: cihazın gerçek konumu, 50 km halkası, içeride/dışarıda renk, “Tümü / 50 km / Daha uzakta”, yol tarifi gerçek harita uygulaması. Konum yoksa izin ekranı; İstanbul’u taklit etme.

**Alma.** Sahte GPS, varsayılan sahte pin, “yakınımda 12 oyun” diye yalan sayı.

## 5. Arama: yaz + aynı tür şeridi

**Rakipler.** TodayTix arama: oyun + mekan + koleksiyon karışır; tarih/adet ayrı sheet. Ticketmaster 2026 native search + konum değiştirme. DICE: çubuk + tarih/fiyat/şehir hapları; tür bazen çubuğa gömülüp kaybolur (eleştiri). ATG iç arama veya Shows A–Z. Mobilet ana sayfa veya arama butonu.

**TiyatRol.** Ana sayfa sakin arama kutusu → arama sayfası. Tür çipleri (Oyunlar / Oyuncular / Mekanlar / Ekipler) varlık seçer. Oyunlarda Keşfet’in `BrowseCategoryStrip` aynı işi görür. Işıyan kenar + daktilo ipucu; “gişe fişi” reddedildi.

**Alma.** Arama çubuğuna bilet/koçan, ikinci bir kategori dili, DICE’teki “filtre çubuğa gömülsün kaybolsun”.

## 6. Afiş kartı; koçan her yüzeyde değil

**Rakipler.** National Theatre ve ATG afiş + tarih aralığı. TodayTix/DICE fotoğraf odaklı kart, fiyat/rozet ikincil. Biletinial/Mobilet etkinlik kartı. tiyatrolar.com.tr afiş duvarı ama her karta “BİLET AL” basar — kalabalık.

**TiyatRol.** Keşfet ve ana şerit: `HomePosterCard`. Bilet dili imza: giriş, sıradaki seans, repertuvar/bilet/koltuk, alt menü koçanı. 04.10.2026: “her yerde bilet asabımı bozdu”.

**Alma.** Her karta koçan, barkod, damga, “BİLET AL” yığını.

## 7. Tek aksiyon: Bilet al

**Rakipler.** National Theatre kartta tek “Dates & tickets”. ATG “Buy Tickets” + seans. Mobilet “Satın Al”. Ticketmaster detayda filtre + koltuk; ana keşifte tek CTA. Biletix “X₺’den itibaren” fiyatı CTA yerine koyar.

**TiyatRol.** Oyun detayında tek birincil: Bilet al. Damga butonu yalnızca bilet anında. Kartta buton kalabalığı reddedildi.

**Alma.** Kart üstüne çok CTA, from-price her yerde, sahte “özel teklif” rozeti.

## 8. Sahne Arkası: varlık → seans → gerçek koltuk

**Rakipler.** Ticketmaster TM1: dikey Event app, toplu düzenleme, durum filtresi, canlı satış/giriş. Biletix Business: seans kurulumu, ön satış, takvim. Biletinial: gişe + kapı + envanter tek panel. Organizatör panelleri: etkinlik / fiyat / gişe / rapor — sade CRUD, vitrin değil.

**TiyatRol.** `AdminHomePage` sekmeleri: Oyunlar, Sahneler, Topluluklar, Oyuncular, Biletler. Biletler: oyun seç → seans seç → gerçek bilet + koltuk; blokaj satışa dokunmaz. `AdminGuard` + Firestore `isAdmin()`. İç araç: perde/spot yok, token’lar var.

**Alma.** Admin’e bilet kromu, sahte KPI, pazarlama “acil satış” panosu, TM1 ölçeğinde pazarlama paketi.
