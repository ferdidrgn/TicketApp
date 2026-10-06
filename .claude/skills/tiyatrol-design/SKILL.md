---
name: tiyatrol-design
description: TiyatRol (Flutter; web + Android/iOS + tablet) için HER arayüz işinde kullan — yeni ekran, redesign, kart, oyun detayı, ana sayfa, login, animasyon, responsive/genişlik, renk/tema. frontend-design + premium-web-design + mobile-design skill'lerinin Flutter'a uyarlanmış, bu projenin reddedilmiş denemelerini de içeren hâli.
---

# TiyatRol Tasarım Skill'i (Flutter)

> Kaynak: [claude-code-templates](https://github.com/davila7/claude-code-templates)
> `creative-design/frontend-design`, `premium-web-design`, `mobile-design`
> (Apache 2.0 — bkz. `LICENSE.txt`). React/CSS örnekleri Flutter'a çevrildi,
> bu projeye özel kurallar ve geçmiş hatalar eklendi.

Bu uygulamanın tasarım lideri gibi çalış: sahibi daha önce **şablon gibi
duran, "yapay zekâ yapmış" hissi veren her öneriyi reddetti**. Ondan beklenen:
gerçek bir ürün gibi duran, firmalara sunulabilecek, **sade ama TiyatRol'e
özgü** bir arayüz. Cesaretini tek bir yerde harca, geri kalan her şey sakin ve
disiplinli olsun.

Ayrıntılar: `references/flutter-web.md`, `references/flutter-mobile.md`,
`references/motion.md`, `references/interaction.md` (etkileşimli UI,
hazır eklentiler, işlem akışları), `references/history.md` (neyi denedik, neden reddedildi
— **yeni bir şey tasarlamadan önce MUTLAKA oku**, aynı hatayı tekrarlama).

---

## 1. Konu: neyi tasarlıyoruz?

- **Ürün:** Türkiye'de tiyatro oyunlarını, sahneleri, toplulukları ve
  oyuncuları keşfedip bilet alınan uygulama (web + mobil). Bazı oyunların
  biletleri başka platformda satılıyor (harici link).
- **Kullanıcı:** Tiyatro seyircisi — "bu hafta ne izlesem, nerede, kaça?"
- **Birincil iş:** Oyunu bul → seansı seç → koltuğu seç → bileti al.
  Her ekran bu zinciri hızlandırmalı; süs bu zincirin önüne geçemez.
- **Konunun gerçek malzemesi** (ayırt edici tasarım buradan çıkar, "tiyatro
  efekti"nden değil): oyun afişleri, sahne fotoğrafları, bilet ve koçan,
  koltuk planı, seans tarihleri, tiyatro programı (broşür) düzeni, topluluk
  ve oyuncu isimleri. Gerçek içerikle tasarla (Firestore'daki gerçek oyun
  adları uzun, Türkçe karakterli, bazen afişsiz — tasarım buna dayanmalı).

## 2. Değişmez kurallar (sahibinin kararları)

1. **5 tema korunur.** `AppThemeStyle`: appLight, appDark, system,
   materialLight, materialDark, custom (kullanıcının seçtiği vurgu rengi).
   Tema değiştirme özelliği ASLA bozulmaz. Her yeni renk **tema üzerinden**
   gelir: `context.colors.*` (`ColorScheme`) ya da bir `ThemeExtension`.
   Ekrana sabit `WebColors.x` gömmek temayı devre dışı bırakır — yeni kodda
   yapma, dokunduğun eski kodda temaya taşı.
2. **Renkler değişebilir** (sahibi izin verdi). Ama palet önce tasarım
   planında önerilir, sahibine gösterilir, sonra uygulanır; 5 temada da
   (açık/koyu/Material You/özel vurgu) kontrast kontrol edilir.
3. **Sadelik.** Bir kartta/detay sayfasında buton kalabalığı yok. Her
   ekranın TEK net birincil aksiyonu olur (oyun detayında: "Bilet al").
4. **Gerçekçi ürün hissi.** Görsel olarak bir tiyatro/etkinlik platformunun
   gerçek ürünü gibi durmalı; oyuncak/demo/konsept sanat gibi değil.
5. **Mobil ve web gerçekten ayrı** (conditional export: `*_stub.dart`,
   `*_web.dart`, `*_mobile.dart`). Web = mobili büyütmek değil; tablet
   kendi kırılma noktası (bkz. `references/flutter-web.md`).
6. **İki görsel dil, tek ürün (02.10.2026).** Bilet koçanı her yüzeyde
   tekrarlanınca sıkıcı ve "şablon" oldu. **İşlem / kimlik** yüzeylerinde
   bilet dili kalır (giriş, biletlerim, koltuk, ödeme, alt menü şeridi,
   arama damgası). **Keşif** yüzeylerinde (ana sayfa, keşfet/kategoriler,
   arama sonuçları, yakındakiler listesi dışı) **editöryal afiş dili**
   kullanılır: poster kart, tür mozaiği, "bugün / bu hafta" zaman çipleri,
   yatay koleksiyon şeritleri. Kaynak skill'ler: `sources/frontend-design.md`,
   `sources/mobile-design.md` (claude-code-templates, Flutter'a çevrildi).
   Rakip araştırması (DICE, TodayTix): konum + tür + tarih ile keşif;
   harita birinci sınıf; sonuç türü etiketi; koleksiyon satırları.
   Motif = afiş, mürekkep çizgisi, tipografi — her ekranda perde/spot yok.

## 2b. Etkileşim zorunlu (sahibinin isteği, 04.10.2026)

"İnteraktif UI'lar, eklentiler, işlemler de ekleyerek yap." Sadece okunan
statik ekran yetersizdir: her yeni ekran/yeniden tasarım en az bir anlamlı,
GERÇEK veriye bağlı etkileşim içerir (kaydırılan vitrin, filtreleyen
seçici, canlı önizleme, iyimser favori, paylaş, hatırlat…), dört durumu
(yükleniyor/boş/hata/başarı) ve dokunuş geri bildirimini (InkWell +
`HapticFeedback`) kapsar. Önce projede HAZIR eklentileri kullan (confetti,
staggered animations, skeletonizer, visibility_detector, share_plus,
url_launcher, firebase_messaging…). Kalıplar, paket tablosu ve işlem
kuralları: `references/interaction.md`. Tasarım planına bir
**"Etkileşim"** satırı eklenir: birincil işlem, doğrudan manipülasyon,
geri bildirim, durumlar, kalıcılık, geri alma.

## 3. Süreç (zorunlu): planla → brief'e karşı gözden geçir → görsel doğrula → kodla → eleştir

1. **Tasarım planı** (koda başlamadan, kısa):
   - **Renk:** 4–6 isimli hex (zemin, yüzey, metin, ikincil metin, marka,
     durum). Her biri hangi `ColorScheme` rolüne/`ThemeExtension` alanına
     karşılık gelir, 5 temada nasıl türer.
   - **Tipografi:** en fazla 2 aile (`google_fonts`, `latin-ext` —
     "ğ ş ı İ ö ü ç" ile test et) ve rolleri; tip ölçeği (display → başlık →
     bölüm → kart başlığı → gövde → meta).
   - **Yerleşim:** tek cümlelik yerleşim fikri + ASCII wireframe (mobil,
     tablet, geniş web ayrı ayrı). Hizalama kararı (sol hizalı mı?).
   - **İlke:** bu ekranı TiyatRol'e özgü yapan tek şey ne?
2. **Brief'e karşı gözden geçir:** Plandaki her karar "başka bir etkinlik
   uygulaması için de aynısını yapardım" diyorsa → değiştir, neyi neden
   değiştirdiğini yaz. `references/history.md`'deki reddedilenlere
   benziyorsa → değiştir.
3. **Görsel doğrulama (bu sandbox'ta Flutter SDK YOK):** Büyük bir görsel
   karar (yeni palet, yeni kart, yeni sayfa iskeleti) Flutter'a
   çevrilmeden önce aynı tasarımın basit bir **HTML/CSS maketi** yazılıp
   Playwright/Chromium ile ekran görüntüsü alınır (mobil 390px, tablet
   820px, web 1440px) ve kullanıcıya gösterilir. Onaydan sonra Flutter'a
   çevrilir. "Bir resim 1000 token eder."
4. **Kodla**, sonra **eleştir:** "Aynaya bak, bir aksesuarı çıkar."
   Kaliteli taban (duyurmadan): mobile kadar responsive, görünür klavye
   odağı, azaltılmış hareket desteği, erişilebilir kontrast, 48dp dokunma.

## 4. Tasarım ilkeleri

**Hero:** Konunun en karakteristik şeyiyle aç — TiyatRol'de bu genelde
**gerçek bir afiş/sahne fotoğrafı + oyun adı + en yakın seans**. "Büyük sayı
+ küçük etiket + istatistik + gradyan" varsayılanını kullanma.

**Tipografi kişiliği taşır.** Bir ya da iki aile; ikiyse belirgin farklı.
Tip ölçeği net: display ile gövde arasında dramatik fark, başlıkta sıkı
satır aralığı (1.0–1.15), gövdede rahat (1.45–1.6), satır ≤ ~75 karakter
(web'de `ConstrainedBox(maxWidth: ...)`). Başlık tipografisi tasarımın
parçası olabilir; nötr bir taşıyıcı değil.

**Yapı bilgidir.** Çerçeve, çizgi, numara, etiket, ayraç sadece içerik
hakkında bilgi veriyorsa kullanılır. `01/02/03` sadece gerçek bir sıra
varsa (bilet alma adımları gibi).

**Hareket azdır ve bilinçlidir.** Tek bir koreografili an (bir sayfa
açılışı ya da bir açılış/reveal) dağınık efektlerden iyidir. Her bölüme
"aşağıdan fade-in" ve her karta hover efekti = yapay zekâ işareti.
Kullanıcı aksiyonuna cevap veren hareket (açma, genişleme, onay) iyidir.
Keşif sayfalarında ek izinli hareket: hero wipe, afişte hover'da galeri
açılışı, zaman çipinde seçim kayması, haritada kamera. Ayrıntı:
`references/motion.md`.

**Keşif iskeleti (DICE / TodayTix, TiyatRol malzemesiyle):**
- Ana sayfa: arama + sıradaki GERÇEK seans (tek bilet anı) + Bugün/Bu
  hafta + Firestore `Show.category` mozaiği + repertuvar afiş ızgarası +
  yakınımda daveti (GPS uydurma yok).
- Keşfet: tür mozaiği (gerçek afiş + sayı) + anında çip filtresi + afiş
  ızgarası. Seans satırları koçan olabilir (seans = bilet).
- Arama: gişe fişi korunur; boş sorguda tür kısayolu + karışık sonuçlarda
  tür etiketi (oyun / oyuncu / sahne / ekip).
- Yakınımakiler: harita birinci sınıf; Bugün/Bu hafta/tür; sahne grupları.

**Yazı (Türkçe metin):** Kullanıcının dilinden, sade, aktif fiil. Buton ne
olacağını söyler ("Bilet al", "Koltuğu seç"); akış boyunca aynı ad kalır
("Bilet al" → "Biletin alındı"). Hata: ne oldu + ne yapmalı + tekrar dene;
özür dileme, belirsiz olma. Boş ekran bir davet ve CTA'dır. Satış dili
("şehrin en seçkin…") yok.

## 5. YAPMA listesi

### Genel yapay zekâ işaretleri (frontend-design + premium-web-design)
- Siyaha yakın zemin + tek parlak/kırmızı-turuncu vurgu (← bu projenin eski
  hâli), krem zemin + serif + kiremit vurgu, mor→mavi gradyan.
- Her başlığın üstünde harf aralığı açılmış BÜYÜK HARF etiket ("eyebrow");
  "A · B · C" ortanoktalı meta dizileri; "KELİME — parça" etiketleri;
  küçük etiketlerde monospace; buton/link sonuna "→".
- Başlıkta tek kelimeyi renk/italik ile vurgulamak.
- Aynı radius + aynı gri gölge ile her şeyi eş kartlara bölmek; süs
  gradyanlar; blob/şekil süslemeler; her yerde glassmorphism.
- Hero → 3'lü özellik ızgarası → CTA kalıbı; her şey ortalı ve kutulu.
- Spinner (skeleton yerine), her şeye aynı geçiş, "hover'da büyü".

### Bu projede denenip REDDEDİLENLER (bkz. `references/history.md`)
- **"D harfi" asimetrik köşe** (`AppRadius.asymSm/asymLg`: iki köşe keskin,
  iki köşe çok yuvarlak). Sahibi "iğrenç" dedi. Yeni kodda kullanma;
  dokunduğun yerde kaldır.
- Zeytin yaprağı/göz (vesica) kart silüeti — taşma hatası üretti, reddedildi.
- Perde, spot ışığı, "perde açılışı" parlamaları, vignette süsleri her
  ekranda — gimmick olarak algılandı.
- Karta/detaya çok sayıda buton, rozet ve ikon yığmak.
- Dışarıdan hotlink stok fotoğraf (web'de CORS ile kırıldı; rakip/3. taraf
  görseli risk). Görsel = Firebase'deki gerçek afiş/fotoğraf ya da
  `assets/images/` içindeki lisanslı dosya.

## 6. Renk ve tema (Flutter)

- Tema kaynağı: `lib/core/theme/theme_manager.dart` (`ColorScheme.fromSeed`
  ile 5 temanın her biri üretiliyor) + `app_colors.dart`.
- Yeni paleti **seed + gerekirse `ColorScheme.copyWith`** ile ver; markaya
  özel ve `ColorScheme`'da olmayan roller (ör. koçan kağıdı, afiş karartması)
  için bir `ThemeExtension<TiyatrolPalette>` tanımla ve 5 temada doldur.
- `withOpacity` ile renk "uydurma" (overlay'i gerçek renk yerine kullanma).
- Kontrast: gövde metni ≥ 4.5:1, büyük başlık ≥ 3:1 — 5 temada da.

## 7. Responsive (özet — ayrıntı `references/flutter-web.md`)

- Kırılma noktaları `ResponsiveUtils` (mobil / tablet / masaüstü / geniş).
  Her kırılmada **kompozisyon değişir** (sütun sayısı, yan panel, sticky
  alan), sadece boyut değil.
- İçerik genişliği sınırlanır (okuma sütunu ~680, ızgara ~1280–1440),
  geniş ekranda kenarlar "nefes alır".
- Izgaralarda `SliverGridDelegateWithMaxCrossAxisExtent`/`LayoutBuilder`;
  sabit `crossAxisCount` yok.
- Akışkan tip: `fluid(context, min, max)` gibi genişliğe bağlı `clamp`.

## 8. Mobil (özet — ayrıntı `references/flutter-mobile.md`)

- Birincil aksiyon başparmak bölgesinde (altta, ör. oyun detayında yapışkan
  alt "Bilet al" çubuğu). Dokunma alanı ≥ 48dp, aralarında ≥ 8dp.
- Dokunmaya <50ms görsel cevap; yükleme 100ms içinde görünür (skeleton).
- `SafeArea`, klavye (`resizeToAvoidBottomInset`), iOS geri kaydırma,
  Android geri tuşu (`PopScope`) — platform alışkanlıkları bozulmaz.
- Performans: uzun listede `ListView.builder`/`SliverList`, `const`
  widget'lar, animasyonda `Opacity` yerine `FadeTransition`, pahalı
  `BackdropFilter`/`saveLayer` yok, görsellerde `cacheWidth`.

Mobil checkpoint (claude-code-templates `mobile-design`, Flutter'a çevrildi):

```
Platform: iOS + Android (+ web ayrı layout)
Framework: Flutter + Riverpod
Dokunma: ≥ 48dp, 8dp boşluk, birincil CTA başparmak yayı
Liste: ListView.builder / SliverList, sabit id key
Hareket: transform/opacity; disableAnimations saygı
Yasak: ScrollView+map, her karta aynı hover büyüme, her yerde perde
```

Ayrıntı: `sources/mobile-design.md`, `references/flutter-mobile.md`.

## 9. Bu sandbox'ta doğrulama (Flutter SDK YOK)

- Parantez/süslü/köşeli denge: yorum ve string'leri ayıklayan betik
  (düz sayım, yorumdaki "1) 2)" yüzünden yanlış alarm verir).
- Her relative import'un gerçekten var olduğunu kontrol et (silinen dosyayı
  import eden eski sürüm geri birleştirilince web derlenmedi).
- Emin olmadığın paket API'sini paketin kaynağından doğrula (ör. pinput
  6.x `PinTheme.margin`, `separatorBuilder`).
- Bilinen çalışma zamanı tuzakları: `Container(margin:)` negatif olamaz;
  `BasePageWrapper` kullanmayan web sayfası kendi `Scaffold`'unu kurmalı
  (yoksa TextField "No Material widget found" ile çöker, metinler sarı çift
  alt çizgili görünür); çocuksuz `CustomPaint` gevşek kısıtta 0 boyuta düşer;
  `IntrinsicHeight` altında `LayoutBuilder` çöker; `Scaffold.bottomNavigationBar`
  içinde çarpansız `Center`/`Align` tüm ekran yüksekliğini kaplar ve sayfa
  gövdesini 0 px'e düşürür (boş sayfa) — `heightFactor: 1` ver.
- `build_runner` çalışmaz: codegen'li dosyaya yeni `@riverpod` ekleme;
  klasik `Provider`/`FutureProvider`/`NotifierProvider` kullan.
