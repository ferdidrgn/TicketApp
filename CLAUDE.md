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

Token dosyaları (`lib/core/theme/`) geçerli: `AppSpacing`, `AppRadius`
(asymSm/asymLg 30.09.2026'da tamamen kaldırıldı), `AppMotion`,
`AppShadows.levelN(tint)` — ham
`EdgeInsets`/`BorderRadius.circular(N)`/`BoxShadow`/`Duration` yerine bunlar.

## Yerleşik desenler

- **Bilet dili (onaylı imza):** `lib/shared/widgets/ticket/` — `ticket_kit.dart`
  (temel parçalar), `ticket_listing.dart` (oyun/seans bilet satırları, boş/hata
  durumu), `seat_plan.dart` (salon planı), `ticket_profile.dart` (oyuncu/sahne/
  topluluk künye sayfaları). Oyun kartı: `lib/shared/widgets/theatre_show_card.dart`.
  Yeni ekran bunları kullanır; yeni bir görsel dil icat edilmez.

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
- Bu sandbox'ta Flutter SDK YOK (`flutter` komutu bulunamıyor). Hiçbir
  değişiklik burada derlenip/çalıştırılıp doğrulanamıyor — sadece statik
  okuma + parantez/süslü parantez/köşeli parantez denge kontrolü
  (python one-liner) yapılabiliyor. Gerçek görsel/işlevsel test için
  kullanıcının kendi makinesinde `flutter pub get && flutter run` (mobil)
  veya `flutter run -d chrome` (web) çalıştırması gerekiyor.

## Agent/subagent kullanımı

Büyük işler paralel background agent'lara (`isolation: "worktree"`)
bölünüyor. Her UI agent'ının prompt'una "önce
`.claude/skills/tiyatrol-design/SKILL.md` ve `references/history.md`'yi
oku" talimatı ve yukarıdaki güncel kararlar (5 tema, yasaklar, token
kullanımı) açıkça yazılır — agent'lar kendi worktree'lerinde başlıyor ve
bunu otomatik görmeyebilir. Agent önce `git fetch` + dalın ucuna
`reset --hard` ile başlar, push'tan hemen önce yeniden rebase eder.
