# Denenenler ve sahibinin tepkisi (yeni tasarımdan ÖNCE oku)

Sahibi Türkçe ve doğrudan konuşur; "berbat", "iğrenç", "kullanışsız"
geri bildirimleri ciddi ret demektir. Beğendiği şeyler de not edildi —
onları koru.

## ✅ ONAYLANAN YÖN: "BİLET DİLİ" (29.09.2026)

Giriş ekranındaki "bilet gişesi" tasarımı için sahibi: **"çok çok çok
harika… bunu her sayfaya her logice bağla… İŞTE BÖYLE DEVAM ET… webLERE DE
EKLE"**. Bu artık uygulamanın imza dilidir:
- Önemli nesneler fiziksel tiyatro biletidir: fildişi kağıt, delikli koçan
  (yarım daire çentikler), barkod, mürekkep damgası (YENİ, KOD GÖNDERİLDİ),
  birincil aksiyon "damga butonu", aksiyonda koçanın yırtılması.
- Başlıklar Playfair Display ile ve soldan sağa perde açılışı (wipe).
- Bilgi, bilet alanları gibi (küçük etiket + basılı değer: TARİH, SEANS,
  KOLTUK) verilir.
- Kit: `lib/shared/widgets/ticket/ticket_kit.dart` (`TicketPiece`,
  `TicketPerforation`, `AdmitTicket`, `TicketStampButton`, `TicketField`,
  `TicketBarcode`, `TicketInkStamp`, `TicketHeaderStrip`, `TicketStage`,
  `AuthWipeReveal`). Vurgu rengi temadan (`TicketInk.accentOf`); kağıt ve
  mürekkep sabit. Giriş gibi "an" ekranları koyu sahnede
  (`TicketStage()`), genel sayfalar temanın zemininde
  (`TicketStage(themed: true)`).
- Not: skill'in "BÜYÜK HARF etiket / monospace" uyarıları bu dilde
  bilinçli olarak kullanılıyor (sahibinin onayı, gerçek biletin
  dili) — ama ölçülü: bilet alanlarında, her başlığın üstünde değil.

## Oyunlaştırma / sahne anları (30.09.2026, sahibinin isteği: "bir oyunmuş gibi")
- Profil: "Seyirci karnesi" — izlenen her oyun için mürekkep damgası, rütbe
  (Yeni Seyirci → Seyirci → Müdavim → Tiyatro Kurdu → Sahne Tozu Yutmuş),
  zımba delikleriyle sonraki rütbe. Tamamen gerçek bilet verisinden.
- Favoriye eklerken sahneye gül atılır (`stage_moments.dart` → `tossRose`).
- Yükleme: "Üç Gong" (`ThreeGongIndicator`) — Türk tiyatrosunda perde üç
  gongla açılır.
- Giriş biletindeki afiş bandı: yatay bantta dikey afişler basık/kırpık
  görünüyordu ("basıklıktan kurtar") → afiş 2:3 tam oranında solda, oyun adı
  sağda. Sahibi: "oyunun afişleri de çıksın" — afiş her zaman görünür kalmalı.

- Onboarding "Oyun programı" (I-II-III. perde; gerçek afiş yelpazesi, koltuk
  sırası, CANLI tema seçimi). Sadece mobilde, ilk açılışta bir kez
  (`OnboardingGate`). Web'de gösterilmez.
- "Başa dön": sayfa başına FAB yerine kökte tek global buton
  (`StageScrollTop`) — temanın vurgu renginde küçük bilet koçanı, "BAŞA".
  Eski gri yuvarlak (`fab_scroll_up.dart`) artık kullanılmıyor.

- Alt menü (01.10.2026, "sıfırdan farklı"): yüzen "bilet şeridi" — iki yanda
  zımba çentikleri, aktif sekme vurgu renginde kayan koçan. Eski düz şerit
  + üst çizgideki zımba çentiği değiştirildi. Yükseklik sabit
  (`kTicketNavBarExtent`); çubuğa asla tüm yüksekliği kaplayan Center/Align
  koyma.

- Arama çubuğu: "gişe arama fişi" (damga + delik çizgisi + kayan örnek)
  REDDEDİLDİ ("hiç beğenmedim"). Yerine "ışıyan kenar": temanın
  renklerinde dönen ince halka + daktilo ipucu (04.10.2026).
- Arama sayfasında oyuncular: yuvarlak (76px) ve elips "el aynası"
  (84x128) REDDEDİLDİ ("aşırı berbat"). Sahibinin İLK tasarımı geri
  getirildi: 120 genişlik, ClipRRect r=60 uzun hap portre, ad/soyad iki
  satır (eski `PlayerHeroCard`). Bunu koru.
- **"Her yerde bilet" yorucu** (04.10.2026): "her yerde bilet temalı
  tasarımlar görmek asabımı bozdu". Bilet dili artık İMZA olarak az
  yerde (giriş, sıradaki seans, repertuvar, bilet/koltuk); ana sayfa ve
  aramada fotoğraf odaklı, ferah bölümler: hareketli vitrin (kampanya +
  oyun, ilerlemeli gösterge), "bu hafta" nabzı, ruh hâline göre seçim,
  sinematik afiş kartı, günün repliği, oyuncu hikâyeleri, tür karoları
  (`home_showcase.dart`).

- Keşfet + Yakınımdakiler (04.10.2026, "sıfırdan yap, çalışmıyor"):
  Keşfet fotoğraflı tür kartları + sıralama + afiş ızgarası (bilet kartı
  yok); kategori anahtarı büyük/küçük harf duyarsız, bağlantı
  `Uri.encodeQueryComponent` ile ("&" içeren tür adresi kesiyordu).
  Harita: TÜM yaklaşan seansların sahneleri, 50 km halkası, içeride/
  dışarıda farklı renk, lejant; liste "Tümü / 50 km içinde / Daha
  uzakta". 30 günlük pencere kaldırıldı (dışarıdaki oyun hiç
  görünmüyordu).

## Beğenilenler (koru)
- **Metin perde açılışı (wipe reveal):** başlığın soldan sağa `ClipRect +
  Align(widthFactor)` ile açılması — "yazı animasyonu çok iyi".
- **Konser/kalabalık sahne fotoğrafı** (profil sayfası misafir hero'su,
  Unsplash `photo-1514525253161-7a46d19cd819`) — "bu foto çok iyi".
- 5 tema özelliği — "asla temalarımı bozma".

## 06.10.2026 gece — yumuşak malzeme

Material 3 Expressive (tonal yüzey, büyük köşe, yaylı basış) Flutter
token'larına alındı. Afiş kartında ad, görselin üstüne binen yumuşak
yüzeyde. "Kaldığın yerden devam" kampanya vitrininin altında. D-köşe,
perde ve vesica yok.

Sahibi ana sayfa / arama / keşfet / yakındakiler / oyun ve oyuncu
detayının boş durduğunu söyledi. Bilet dili işlemde kalır; keşif
yüzeyinde afiş duvarı (`HomePlaybillBoard`) ve poster ızgarası. Bölüm
araları kısaldı. Perde, D-köşe, vesica hâlâ yok. Tek birincil aksiyon
(Bilet al) duruyor; doluluk boşluk kısarak ve gerçek afişleri
yan yana koyarak artar.

Sahibi: keşif yüzeylerini (ana sayfa, arama, kategoriler, yakındakiler)
TodayTix/DICE benzeri koleksiyon + tür + tarih + harita ile zenginleştir;
bilet dilini işlem yüzeylerinde tut. Skill'ler
`creative-design/frontend-design` ve `mobile-design` (claude-code-templates,
Flutter'a çevrildi) güncellenir. Perde/spot her ekranda hâlâ yasak;
motif = afiş, mürekkep çizgisi, tipografi, tek koreografili an.

## Reddedilenler

### Genel (Eylül 2026)
- Web ve mobil sayfaların geneli: "çok berbat", "hiç gerçekçi tasarım hissi
  vermiyor, firmalara sunsam berbat der", "UI'lar birbirine karıştı,
  sadelik gitti".
- Renk paleti (koyu lacivert/siyah + koyu kırmızı `#C50337` + fildişi, pembe/
  mor gradyanlar): "renkler iğrenç". Sahibi paleti değiştirme izni verdi.
- Oyun detay sayfası: "bir sürü buton var, çok karmaşık".
- Hazır yönler (Biletix tarzı ticari, Netflix tarzı karanlık sinema, dergi
  tarzı editöryal) önerildi → hiçbiri seçilmedi: "bize özgü, bunlardan
  ayrı olsun".

### Oyun kartı (`lib/shared/widgets/theatre_show_card.dart`)
1. Tek büyük yuvarlak köşeli "taç yaprağı" kart, rozetler afiş üstünde iki
   köşede → dar kartta "BAŞKA PLATFORMDA" ile "YENİ" üst üste bindi.
2. Zeytin yaprağı/göz (vesica) şekli sadece afişte → "sen sadece fotoyu öyle
   yapmışsın, kart tasarımından bahsetmiştim… çok iğrenç".
3. Vesica şekli tüm kartta → dar bantta RenderFlex taşması, "çok kullanışsız".
4. İmza asimetrik köşe (`AppRadius.asymLg`) → **"D harfi şeklinde tasarımlar
   iğrenç"**. `asymSm/asymLg` ~10 dosyada daha kullanılıyor; temizlenmeli.

### Giriş / telefonla giriş
1. Üst yarı fotoğraf + alt yarı buton platformu (bottom sheet) → "berbat".
2. Web'de sol fotoğraf paneli + sağ form kartı → "berbat".
3. Fotoğrafsız editöryal tipografi + numaralı "01 02" satırlar → "berbat"
   (sadece başlık animasyonu beğenildi).
4. Referans afiş kompozisyonu (başlık + tam kanama foto + yüzen pill buton)
   → negatif margin çökmesi; mobilde üstte temanın açık şeridi; web'de
   Scaffold yok → çöktü; dış foto web'de yüklenmedi.
5. "Bilet gişesi" (fildişi fiziksel bilet, delikli koçan, yırtılma,
   koltuk sırası SMS kodu, gerçek afiş bandı) → **ONAYLANDI, çok beğenildi**
   (bkz. en üst).

### Diğer
- Geri butonlu ortak başlıkta sabit pembe/kırmızı gradyan yazı → temaya
  bağlandı (düzeltildi).
- Her yerde perde/spot/parlama/vignette "tiyatro efekti" — gimmick.
