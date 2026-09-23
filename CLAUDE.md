# TicketApp (TiyatRol) — proje hafızası

Bu dosya her Claude Code oturumunun başında otomatik okunur. Buraya yazılanlar
tekrar anlatılmasına gerek kalmadan hatırlanır — yeni bir agent/subagent
başlatıldığında bile (prompt içine ayrıca özetlenerek) bu kurallar geçerli
kalmalı.

## Tasarım sistemi — "The Digital Stage"

Token dosyaları `lib/core/theme/`:
- `AppSpacing` — xs/sm/md/lg/xl/xxl/xxxl/huge/section
- `AppRadius` — xs..xl, `pill`, ve uygulamanın imza asimetrik köşeleri
  `asymSm`/`asymLg` (BorderRadius.only) — bir-iki vurgu noktasında kullan,
  her yerde değil.
- `AppMotion` — fast/normal/slow `Duration`; `standard`/`symmetric`/
  `dramatic` `Curve`.
- `AppShadows` — level0..level5, her biri bir `tint` Color alır.

Kural: yeni/değiştirilen her widget'ta ham `EdgeInsets`/`SizedBox` yerine
`AppSpacing`, ham `BorderRadius.circular(N)` yerine `AppRadius`, ham
`BoxShadow` yerine `AppShadows.levelN(tint)`, ham `Duration`/`Curves` yerine
`AppMotion` kullanılır.

## Tasarım felsefesi — "Perde açıldı" standardı

Kullanıcının verdiği kapsamlı Flutter Product Designer/Engineer talimatının
özeti — her yeni/redesign edilen ekranda bu süzgeçten geçir. Amaç "modern
Flutter UI" değil: kullanıcı uygulamayı açtığında "bu sıradan bir bilet
uygulaması" değil, "tiyatro dünyasına açılan dijital bir sahne" hissetmeli.
Jenerik AI-dashboard görünümünden KAÇIN: rastgele mor/pembe gradyan, her
yerde glassmorphism, her kartta border, her elemanda shadow, her yerde
30+ rounded corner, 20 farklı font, rastgele animasyon, aşırı emoji,
Bootstrap tarzı birbirinin aynı kartlar.

- **Konsept zinciri** (açılış→perde→sahne→oyunlar→oyuncular→seanslar→
  koltuk→bilet→sahneye giriş) UI'a ince/sofistike uygulanır: hafif curtain
  reveal, spotlight-like focus, layered depth, subtle vignette, parallax —
  zaten var olan `curtainTransition` (`page_transitions.dart`) ve
  `theatre_show_card.dart`'ın hover reveal'ı bu dilin referans örnekleri,
  yeni yerlerde bunlara benzer teknik kullan, kopyala yapıştır değil.
- **Her ekranda 7 katman düşün**: structure, typography, color, depth,
  motion, interaction, content hierarchy. Her UI elemanının bir amacı
  olmalı — sırf güzel göründüğü için efekt yok.
- **Typography hiyerarşisi**: display → headline → section title → card
  title → body → metadata. Türkçe karakter desteği ve okunabilirlik
  (özellikle web performansı ve mobil) her zaman öncelikli. Mevcut
  `google_fonts` kurulumunu kullan, yeni font dependency ekleme.
- **Derinlik/gölge**: `AppShadows.level0..level5` zaten bu hiyerarşiyi
  temsil ediyor (flat→subtle→card→featured→modal→hero/floating). Aynı
  anda çok fazla shadow üst üste kullanma; bazı yerlerde shadow yerine
  contrast/blur/opacity/border/gradient/background-separation tercih et.
- **Glass/blur**: ana tasarım dili DEĞİL — sadece overlay, bottom sheet,
  floating controls, media controls, nav overlay, hero'da gerektiğinde.
  "Her şeyi cam yapma."
- **Responsive gerçek olmalı**: `if (width > 600)` ile aynı widget'ı
  büyütmek DEĞİL — proje zaten bu prensibi uyguluyor (`home_page_mobile.
  dart`/`home_page_web.dart`, `show_detail_page_mobil.dart`/
  `show_detail_page_web.dart` gibi platforma özel gerçek dosya ayrımı) —
  yeni/redesign edilen her sayfada bu ayrım korunur, "mobile'ı büyütüp web
  diye sunma" kuralı geçerli. Web: geniş nav, multi-column, sidebar/filter,
  hover state, büyük hero, klavye/mouse etkileşimi. Mobil: thumb-friendly,
  bottom nav/sheet, gesture, dikey storytelling.
- **Hero**: "büyük resim + başlık + buton" ile yetinme — layered
  background, poster, gradient, hafif parallax/lighting, CTA + metadata
  birlikte (bkz. `home_page_web.dart`'taki `_HeroBand`/
  `_HeroBackdropPhoto` referans teknik).
- **Animasyon felsefesi**: sadece 4 amaçtan birine hizmet ediyorsa kullan
  — orientation, feedback, continuity, delight. Süreler kısa/kontrollü
  (`AppMotion.fast/normal/slow`). Sayfa geçişlerinde sert kesim yerine
  continuity (`Hero` widget: poster→detay hero gibi).
- **Detay sayfası iskeleti** (oyun/oyuncu/sahne): fullscreen hero (poster+
  başlık+tür+süre+CTA) → hikaye → kadro → fragman → mekân → tarihler →
  seanslar → bilet CTA. Mobilde dikey storytelling, desktop'ta hero+bilgi
  split layout.
- **Koltuk seçimi**: salonun gerçek geometrisini yansıtan esnek sistem,
  generic grid değil; state'ler available/selected/sold/blocked/premium/
  accessible; seçimde scale+color transition+subtle glow+spring motion.
- **Bilet**: bilgi kartı değil, fiziksel bilet hissi (QR reveal: fade+
  scale).
- **Boş/loading/hata durumları**: boş ekranlarda anlamlı metin + CTA
  (ör. "Henüz favori oyunun yok. Sahneyi keşfetmeye ne dersin? [OYUNLARI
  KEŞFET]"); her yerde çıplak `CircularProgressIndicator` yerine mevcut
  `shimmer`/`skeletonizer` paketleri; hata durumunda "bir şeyler ters
  gitti" ile bitirme — neden + ne yapılabilir + retry butonu birlikte.
- **Erişilebilirlik**: contrast, text size, touch target, `Semantics`
  label, web'de klavye navigasyonu, screen reader, reduced-motion desteği,
  focus state — premium tasarım erişilebilirliği FEDA ETMEZ.
- **Performans**: blur/shadow/büyük görsel/animasyon/parallax özellikle
  web'de dikkatli kullanılır; listelerde gereksiz rebuild yok; image
  caching (`cached_network_image`) zaten kullanılıyor, bundan yararlan.
- **Paket felsefesi**: yeni dependency eklemeden önce önce mevcut
  `pubspec.yaml`'daki paketleri değerlendir (`flutter_riverpod`,
  `go_router`, `cached_network_image`, `video_player`, `google_fonts`,
  `shimmer`, `skeletonizer`, `confetti`, `flutter_staggered_grid_view`,
  `flutter_staggered_animations`, `visibility_detector`, `dynamic_color`,
  `qr_flutter`, `url_launcher`, `share_plus`, `curved_navigation_bar`).
  Flutter SDK zaten yapabiliyor mu / projede benzer paket zaten var mı diye
  önce bak — yeni paket son çare.
- **Kalite testi**: her ekran bitince sor — "Bu ekran gerçekten bir
  tiyatro ürününe mi ait, yoksa herhangi bir Flutter template'i mi?"
  İkinciyse yeniden düşün. Öncelik sırası: önce kullanılabilirlik, sonra
  estetik, sonra motion, sonra delight — gösteriş kullanılabilirliğin
  önüne geçemez.
- **Teknik sınır**: Flutter/Dart dışına çıkma — React/Next.js/ayrı HTML-
  CSS frontend YOK, Flutter Web birinci sınıf platform olarak ele alınır.

## SABİT KURAL — RENKLER ASLA DEĞİŞMEZ

`lib/core/theme/app_colors.dart` içindeki `WebColors`, `AppLightColors`,
`AppDarkColors` sabitlerinin hiçbir HEX değeri değiştirilmez. Kullanıcının
kendi talimatı: "renk olarak renkler kalsın. app renkleri ve web renkleri bu
şekilde kalsın." Bütün renk erişimi `context.colors.*`
(`Theme.of(context).colorScheme`) ya da mevcut `WebColors.*` sabitleri
üzerinden — asla yeni bir hex değeri icat etme, asla bir token'ın neye
karşılık geldiğini değiştirme.

## Yerleşik desenler (yeni sayfa/widget yazarken bunlara bak)

- **Footer**: `lib/shared/widgets/footers/footer.dart` — masaüstü/web
  sayfalarının scrollable içeriğinin en altına `const Footer()` (ya da
  `CustomScrollView` ise `SliverToBoxAdapter(child: Footer())`). Sabit
  viewport'lu (dış scroll'u olmayan) sayfalara EKLENMEZ (ör. favoriler,
  biletlerim — bunlar bilinçli olarak footer'sız bırakıldı).
- **Hover'da perde açılışı + rastgele gerçek görsel**: `lib/shared/widgets/
  theatre_show_card.dart` — referans teknik. `show.photosShowId`'den
  `initState`'te bir kez rastgele seçilen görsel, hover'da
  `TweenAnimationBuilder<double>` ile `ClipRect(Align(widthFactor: t))`
  kullanılarak açılıyor (`page_transitions.dart`'taki `curtainTransition`
  ile aynı teknik).
- **İletişim aksiyonları**: `lib/core/util/comminucation_actions.dart`
  (`TiyatrolCommunicationActions`) — gerçek e-posta/WhatsApp/Instagram/
  Facebook/konum aksiyonları. Sahte/boş `onTap` yerine hep bunlar kullanılır.
- **Erişilebilirlik**: ikon-only butonlara ve etkileşimli kartlara
  `Semantics(label: ...)` eklenir — bu neredeyse hiç yoktu, eklenen her
  sayfada bu boşluk kapatılır.

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
- Bu sandbox'ta Flutter SDK YOK (`flutter` komutu bulunamıyor). Hiçbir
  değişiklik burada derlenip/çalıştırılıp doğrulanamıyor — sadece statik
  okuma + parantez/süslü parantez/köşeli parantez denge kontrolü
  (python one-liner) yapılabiliyor. Gerçek görsel/işlevsel test için
  kullanıcının kendi makinesinde `flutter pub get && flutter run` (mobil)
  veya `flutter run -d chrome` (web) çalıştırması gerekiyor.

## Agent/subagent kullanımı

Büyük işler paralel background agent'lara (`isolation: "worktree"`)
bölünüyor. Her agent prompt'una yukarıdaki tasarım kuralları (özellikle
renk kısıtı ve token kullanımı) açıkça yazılıyor — bu dosya var olsa bile,
agent'lar kendi izole worktree'lerinde başlıyor ve bu dosyayı otomatik
görmeyebilir, o yüzden prompt içine tekrar özetlenmesi gerekiyor.
