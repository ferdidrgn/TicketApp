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
