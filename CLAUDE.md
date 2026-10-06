# TicketApp (TiyatRol) — proje hafızası

Bu dosya her Claude Code oturumunun başında otomatik okunur. Buraya yazılanlar
tekrar anlatılmasına gerek kalmadan hatırlanır — yeni bir agent/subagent
başlatıldığında bile (prompt içine ayrıca özetlenerek) bu kurallar geçerli
kalmalı.

## Tasarım — önce skill'i oku

**Her arayüz işinde (yeni ekran, redesign, kart, animasyon, responsive,
renk/tema) önce `.claude/skills/tiyatrol-design/SKILL.md` ve
`references/history.md` okunur.** Skill; frontend-design,
premium-web-design ve mobile-design skill'lerinin Flutter'a uyarlanmış
hâli + bu projede denenip reddedilen her şeyin kaydı. Süreç: tasarım planı
→ brief'e karşı gözden geçirme → (büyük kararlarda) HTML maketi ekran
görüntüsüyle sahibine onaylatma → Flutter kodu → eleştiri.

**Web + mobil (endüstriyel, zorunlu):** Tek kod tabanı Flutter; ürün hem
web hem Android/iOS (+ tablet). Web = büyütülmüş mobil DEĞİL. Yerleşim
yalnızca `lib/core/util/responsive_utils.dart` kırılımları ve
`context.isMobile` / `isTablet` / `isDesktop`: mobil <768, tablet 768–1023,
masaüstü ≥1024, geniş ≥1440. Kırılmada **kompozisyon** değişir (sütun,
yan panel, yapışkan CTA) — aynı ağacı `fontSize` ile şişirmek yok.
Token: `AppSpacing` / `AppRadius` / `AppMotion` / `AppShadows`. Web sayfası
`BasePageWrapper` kullanmıyorsa kendi `Scaffold`'u; hover + görünür odak;
yatay şeritte mouse sürükleme. Mobil: ≥48dp, başparmak CTA, `SafeArea`,
`ListView.builder`/`Sliver*`. Conditional export: `*_web.dart` /
`*_mobile.dart` / `*_stub.dart`. Ayrıntı: skill `references/flutter-web.md`
ve `flutter-mobile.md`.

Sahibinin güncel kararları (28.09.2026):
- **5 tema korunur** (appLight, appDark, system, materialLight,
  materialDark, custom). Tema değiştirme asla bozulmaz; yeni renkler
  `context.colors.*` / `ThemeExtension` üzerinden gelir, ekrana sabit
  `WebColors.x` gömülmez.
- **Renkler değişebilir** (eski "renkler asla değişmez" kuralı kaldırıldı).
  Yeni palet önce önerilir ve onaylatılır.
- **Sadelik ve gerçek ürün hissi:** her ekranın tek net birincil aksiyonu
  var; kart/detayda buton kalabalığı yok; "firmalara sunulabilir" görünüm.
- **Yasak:** "D harfi" asimetrik köşe (`AppRadius.asymSm/asymLg`), vesica
  kart, her ekranda perde/spot/parlama süsü, hotlink stok fotoğraf.

- **İki görsel dil (02–06.10.2026):** Bilet koçanı işlem/kimlik yüzeylerinde
  (giriş, biletlerim, koltuk, ödeme, alt menü, arama damgası). Keşif
  yüzeylerinde (ana sayfa, keşfet, arama göz atma, yakındakiler haritası)
  editöryal afiş dili: `HomePosterCard`, `HomeMoodPicker`, `HomeSpotlightCarousel`,
  tür mozaiği. Kaynak: `.claude/skills/tiyatrol-design/sources/`.

- **Etkileşim zorunlu (04.10.2026):** statik ekran yetersiz; her ekranda
  gerçek veriye bağlı etkileşim + hazır eklentiler + net işlem akışı
  (bkz. skill `references/interaction.md`).

Token dosyaları (`lib/core/theme/`) geçerli: `AppSpacing`, `AppRadius`
(asymSm/asymLg 30.09.2026'da tamamen kaldırıldı), `AppMotion`,
`AppShadows.levelN(tint)` — ham
`EdgeInsets`/`BorderRadius.circular(N)`/`BoxShadow`/`Duration` yerine bunlar.

## Yerleşik desenler

- **Bilet dili (onaylı imza):** `lib/shared/widgets/ticket/` — işlem
  yüzeyleri. Keşif kartı: `lib/features/home/presentation/widgets/common/home_showcase.dart`
  (`HomePosterCard`, vitrin, ruh hâli, yakınım daveti). Oyun bileti kartı
  hâlâ `theatre_show_card.dart` (arama/keşif seans satırları). Yeni keşif
  ekranı afiş dilini kullanır; her yüzeye koçan basılmaz.

- **Footer**: `lib/shared/widgets/footers/footer.dart` — web sayfalarının
  kayan içeriğinin en altına `const Footer()`. Sabit viewport'lu sayfalara
  (favoriler, biletlerim) eklenmez.
- **İletişim aksiyonları**: `lib/core/util/comminucation_actions.dart`
  (`TiyatrolCommunicationActions`) — gerçek e-posta/WhatsApp/Instagram/
  Facebook/konum; sahte `onTap` yok. WhatsApp numarası hâlâ yer tutucu
  (`905XXXXXXXXX`) — sahibinden gerçek numara bekleniyor.
- **Web sayfası = kendi `Scaffold`'u**: `BasePageWrapper` kullanmayan web
  sayfaları `Scaffold` kurar (yoksa TextField çöker).
- **Erişilebilirlik**: ikon-only butonlara ve etkileşimli kartlara
  `Semantics(label: ...)`.

## Mimari notlar

- Riverpod `@riverpod` codegen kullanılıyor (`part '*.g.dart'`) ama bu
  sandbox'ta `build_runner` ÇALIŞTIRILAMIYOR. Mevcut `.g.dart`'ı olan bir
  dosyaya yeni bir `@riverpod` provider EKLENEMEZ — klasik
  `Provider`/`FutureProvider.family` API'si kullan (örnek:
  `show_provider.dart`'taki `eventsByShowIdsProvider`).
- `flutter_riverpod: ^3.0.3` — `AsyncValue.valueOrNull` YOK, nullable
  `.value` kullan.
- Show↔Event ilişkisi iki bağımsız yönde tutuluyor: `Show.eventsId`
  (dizi) ve `Event.showId` (alan). `Event.showId` doluysa TEK doğruluk
  kaynağı odur; dizi sadece o alan boşsa yedek. Bu, "yanlış oyun
  gösteriliyor" tarzı bug'ların en sık kök nedeni — önce buraya bak.
- Flutter SDK sandbox'ta hazır gelmiyor ama KURULABİLİYOR (30.09.2026'da
  yapıldı): storage.googleapis.com'dan stable linux tarball'ı scratchpad'e
  indir → `flutter pub get` → `flutter analyze` (derleme hatası 0 olmalı)
  → `flutter build web --profile --no-web-resources-cdn`. Chromium
  (Playwright) ile sayfaları açıp ekran görüntüsü alarak doğrula.
  Sandbox ağ notları: gstatic (Firebase JS SDK) ve www.google.com
  (reCAPTCHA) engelli, proxy Firestore'un akış bağlantısını tamponluyor —
  bu yüzden test, Firestore/Auth EMÜLATÖRÜ + uydurma (sentetik) veriyle
  yapılır; üretim verisi kopyalanmaz. Emülatöre bağlanan satırlar sadece
  test derlemesinde geçici eklenir, asla commit edilmez.
- Derleyiciyle doğrulanmamış büyük değişiklik "bitti" sayılmaz: 62
  commit'lik rollout'ta alt menüdeki tek bir `Center` (heightFactor yok)
  mobilde tüm sekmeleri boş gösterdi — ancak tarayıcıda açınca görüldü.

## Agent/subagent kullanımı

Büyük işler paralel background agent'lara (`isolation: "worktree"`)
bölünüyor. Her UI agent'ının prompt'una "önce
`.claude/skills/tiyatrol-design/SKILL.md` ve `references/history.md`'yi
oku" talimatı ve yukarıdaki güncel kararlar (5 tema, yasaklar, token
kullanımı) açıkça yazılır — agent'lar kendi worktree'lerinde başlıyor ve
bunu otomatik görmeyebilir. Agent önce `git fetch` + dalın ucuna
`reset --hard` ile başlar, push'tan hemen önce yeniden rebase eder.
