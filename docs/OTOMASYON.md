# Otomasyon (GitHub Actions) — ne yapar, sahibin yapacakları

Durum: 28.10.2026. **Bu iş akışları GitHub'da henüz hiç çalıştırılmadı** (yalnız YAML sözdizimi ve `health-check.mjs --dry-run` yerelde doğrulandı). İlk çalıştırmada Actions sekmesinden kontrol et.

## İş akışları

| Dosya | Tetik | Ne yapar |
|---|---|---|
| `ci.yml` | PR + `main` push | Flutter analyze/test, site derlemesi, **yeni:** `functions-test` (Java 21 + Node 20 + Firestore/Auth/Functions/Storage emülatörü; `functions/test/*.test.js`, 20 dk zaman aşımı) |
| `deploy-web.yml` | `main` push (`site/**`), elle, **yeni:** her gün 05:00 ve 17:00 UTC | Siteyi önişler (sitemap, JSON-LD, oyun sayfaları) ve Hosting'e yayınlar. Cron, yeni oyun/seans eklenince sitenin kendiliğinden güncellenmesini sağlar |
| `health-check.yml` | **yeni:** 3 saatte bir + elle | Canlı site + zamanlayıcı kalp atışı denetimi; sorunda Telegram + başarısız-iş e-postası |
| `weekly-digest.yml` | **yeni:** pazartesi 09:00 TR + elle | Son 7 günün görüntülenme/seans/doluluk toplu özeti -> Telegram (bkz. aşağıdaki bölüm) |
| `deploy-backend.yml`, `deploy-android.yml`, `deploy-ios.yml` | elle | Değişmedi (bkz. `DEPLOY-SIRASI.md`) |
| `.github/dependabot.yml` | haftalık (pazartesi 06:00 TR) | github-actions, `functions/` npm, Flutter pub için gruplanmış (minor+patch) PR'lar, ekosistem başına en çok 5 açık PR |

**Önemli:** `schedule` iş akışları yalnız **varsayılan dalda (`main`)** çalışır. `tiyatrol-web-perde` dalı `main`'e birleşene kadar cron ve health-check TETİKLENMEZ (elle `workflow_dispatch` de iş akışı dosyası varsayılan dalda olmadıkça listede görünmez).

## Sağlık denetimi (`site/tools/health-check.mjs`)

Bağımlılıksız Node betiği.
1. Site: `/`, `/vitrin`, `/kesfet` HTTP 200 ve gövdede "TiyatRol"; `/.well-known/assetlinks.json` 200 ve `android_app`.
2. Firestore `System/expireHolds` (eşik **20 dk**), `System/eventReminders` (**45 dk**), `System/processAccountDeletions` (**36 saat**) belgelerinin `lastRunAt` alanı. Yaş betikte hesaplanır (belgede `ageMinutes` alanı yoktur; o `adminHealth` yanıtındadır).
   - **Belge yoksa (404) = "henüz kurulmadı": yalnız bilgi, uyarı/hata YOK** (deploy öncesi ilk çalışmalar). Fonksiyonlar deploy edilip zamanlayıcı bir kez çalışınca denetim başlar.
   - Kimlik: `FIREBASE_SERVICE_ACCOUNT` içinden RS256 JWT -> OAuth2 jeton (`datastore` kapsamı). Secret yoksa bu adım atlanır.
3. Sorun varsa: Telegram mesajı (secret'lar varsa) ve çıkış kodu 1 -> iş akışı kırmızı -> **GitHub'ın "run failed" e-postası yedek uyarıdır** (GitHub > Settings > Notifications > Actions: "Send notifications for failed workflows only" açık olsun).
4. Telegram secret'ları yoksa betik hata vermez, yalnız log'a yazar.

Yerel sınama (ağsız, sırsız): `node site/tools/health-check.mjs --dry-run` (sağlıklı / belge yok / eşik aşıldı / site 500 senaryolarını sahte yanıtlarla çalıştırır, JWT imzasını doğrular).

## Haftalık özet (`site/tools/weekly-digest.mjs`)

Bağımlılıksız Node betiği; health-check'in servis hesabı JWT yöntemini (`erisimJetonu`) yeniden kullanır. **Yalnız toplu sayılar, kişisel veri yok.** Salt okuma (Cloud Datastore Viewer yeter; health-check için eklenen rol aynı).
- Görüntülenme: `Stats/views/days/{gün}` son 7 gün (dünden geriye, Europe/Istanbul) ve önceki 7 gün (yüzde değişim), en yoğun gün, `Stats/views/months/{ay}` ay toplamı, en çok görüntülenen 3 oyun (`show_<id>` sayaçları; ad için `Show/{id}`).
- Yaklaşan seanslar: `Event` listesi (yalnız `date` + `seats`); önümüzdeki 7 günde seans sayısı, doluluk % (blokeli koltuk düşer, mağaza kuralıyla aynı), tükenen / %85 üstü seans sayısı. `seats`'ten yalnız sayı hesaplanır.
- **Yeni favori sayısı özette YOK:** `User.favorite*` alanlarında tarih tutulmadığından "yeni" hesaplanamaz.
- Telegram secret'ları yoksa özet log'a yazılır (başarısız olmaz). `FIREBASE_SERVICE_ACCOUNT` yoksa adım atlanır. Kısmi okuma hatalarında özet yine gönderilir, sonuna "Okunamayanlar" eklenir. Çıkış 1 yalnız servis hesabı bozuksa/jeton alınamıyorsa.
- Yerel sınama: `node site/tools/weekly-digest.mjs --dry-run` (sahte yanıtlar, ağ yok). Maliyet: ayda ~4 çalışma, ~400 belge okuması/çalışma.

## Sahibin eklemesi gereken secret'lar

GitHub > depo > Settings > Secrets and variables > Actions > New repository secret.

1. **`FIREBASE_SERVICE_ACCOUNT`** — zaten var (deploy'lar için). Sağlık denetimi Firestore'u okuyacağı için servis hesabında **Cloud Datastore Viewer** (`roles/datastore.viewer`) rolü de olmalı: Google Cloud Console > IAM > servis hesabının satırı > Edit > Add role. (Deploy rolleri Firestore *belge* okumasını kapsamayabilir; 403 alırsan uyarı metni bunu söyler.)
2. **`TELEGRAM_BOT_TOKEN`** — Telegram'da `@BotFather`'a yaz > `/newbot` > ad ve kullanıcı adı ver > verdiği token'ı (`123456:ABC...`) kaydet.
3. **`TELEGRAM_CHAT_ID`** — oluşturduğun bota Telegram'dan bir mesaj yaz (örn. `/start`), sonra tarayıcıda `https://api.telegram.org/bot<TOKEN>/getUpdates` aç; JSON'daki `message.chat.id` değeri chat id'dir (grup için eksi işaretli sayı). Token'ı kimseyle paylaşma.

Telegram yerine e-posta tercih edilirse: ek kurulum gerekmez — GitHub zaten başarısız çalışma için e-posta atar (sağlık denetimi sorun bulunca kırmızı biter). İstenirse sonradan SMTP'li bir `dawidd6/action-send-mail` adımı eklenir (Gmail uygulama şifresi gerekir); şimdilik gereksiz.

## Maliyet notları

- **Public depo:** standart GitHub-hosted runner dakikaları **ücretsiz ve sınırsız**.
- **Özel (private) depo:** Free planda ayda **2.000 dk** (Linux; macOS 10x, Windows 2x sayılır). Bu iş yükü kabaca: deploy-web cron 2/gün x ~2 dk = ~120 dk/ay; health-check 8/gün x ~0,5 dk (dakika yukarı yuvarlanır, ~1 dk) = ~240 dk/ay; CI `functions-test` PR başına ~5-8 dk. Toplam 2.000 dk'nın altında kalması beklenir; `ios` deploy'u macOS olduğu için 10x sayılır, onu elle ve seyrek çalıştır. Gerekirse health-check'i `0 */6 * * *`'a çek.
- Firebase tarafı: cron dağıtımları Hosting dağıtım kotasını kullanmaz sayılacak kadar küçüktür ama her çalışma yeni bir Hosting sürümü yaratır (sürüm saklama ayarı Console > Hosting'dedir). Firestore okuma: build başına birkaç yüz okuma, günde 2 kez; health-check başına 3 okuma — ücretsiz kotanın (50 bin/gün) çok altında.
- Dependabot ücretsizdir.

## 60 gün hareketsizlik riski (cron durması)

GitHub, **depoda 60 gün hiç etkinlik (commit vb.) olmazsa zamanlanmış iş akışlarını otomatik devre dışı bırakır** (özellikle public depolar; özel depoda da aynı kural belgelenmiştir). Aktif geliştirmede sorun olmaz; ama sezon arası sessiz dönemlerde cron sessizce durup site eskiyebilir.

Çözüm (uygulandı): `deploy-web.yml` ve `health-check.yml` içinde, **başarılı bir cron çalışmasının sonunda** `gh api -X PUT .../actions/workflows/<dosya>/enable` ile iş akışı yeniden "enable" edilir; bu, devre dışı bırakma sayacını sıfırlar (liskin/gh-workflow-keepalive aynı yöntemi kullanır). Adım `continue-on-error`'dır; deploy'u asla bozmaz. **İlk GitHub çalışmasında doğrulanmadı;** davranış GitHub tarafında değişebilir. Yedek: health-check'in e-posta/Telegram'ı susarsa Actions sekmesinde "This scheduled workflow is disabled because there hasn't been activity" bandına bak ve "Enable workflow" de. Aylık anlamsız commit önerilmez (geçmişi kirletir).

## İkinci aşama (tasarım notu, YAPILMADI): admin panelinde "Siteyi şimdi yenile"

`deploy-web.yml` zaten `workflow_dispatch`'lıdır; eksik olan tetikleyici. Önerilen tasarım:
1. GitHub'da **ince yetkili (fine-grained) PAT**: yalnız bu depo, izin `Actions: Read and write` (başka hiçbir şey), mümkünse kısa ömürlü; veya bir GitHub App (daha sağlam, jeton rotasyonu otomatik).
2. Token'ı Secret Manager'a koy (`GITHUB_DISPATCH_TOKEN`, `firebase functions:secrets:set`).
3. Admin-only callable `adminRefreshSite` (yetki: `User.role == admin`, hız sınırı: 10 dk'da 1): `POST https://api.github.com/repos/<sahip>/<depo>/actions/workflows/deploy-web.yml/dispatches` gövde `{"ref":"main"}`, başlıklar `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`; 204 = başarı. Token asla istemciye/loga yazılmaz.
4. Panelde düğme: "Siteyi şimdi yenile" + son çalışma durumu için (isteğe bağlı) aynı callable içinde `GET .../actions/workflows/deploy-web.yml/runs?per_page=1`.
5. Alternatif (callable'sız): panel düğmesi yerine mobil/PC'den GitHub'ın "Run workflow" düğmesi — sıfır kod, sıfır sır.
Bu iş `functions/`'a dokunduğu için bu turda yapılmadı.

## İlk çalıştırma kontrol listesi

- [ ] `tiyatrol-web-perde` -> `main` birleşti (cron/health-check için şart).
- [ ] `FIREBASE_SERVICE_ACCOUNT`'a Cloud Datastore Viewer eklendi.
- [ ] Telegram secret'ları eklendi (isteğe bağlı) ve Actions > Health Check > Run workflow ile deneme yapıldı (sorun yokken "sorun yok" yazmalı; deploy öncesiyse "belgesi yok" bilgileri).
- [ ] `ci.yml` > `functions-test` ilk çalışmada yeşil mi? **Doğrulanmadı:** `firebase-tools@14` ile `emulators:exec --config firebase.ci.json` (Storage emülatörü için CI'da üretilen geçici yapılandırma), `functions/.secret.local` sahte sırları, Java 21 ve emülatör indirme süresi ilk kez GitHub'da denenecek. Kırmızıysa log'un ilk hatasına bak; yaygın nedenler: emülatör JAR indirme zaman aşımı, Storage emülatörü yapılandırması, testlerin `.fb-test.json`/yerel yol varsayımı.
- [ ] Dependabot PR'ları ilk pazartesi gelir; Flutter major yükseltmelerini körlemesine birleştirme.
