# Ödeme ve bilet satış güvenliği (TiyatRol)

Durum: kod + kurallar + otomatik testler hazır. **Henüz deploy EDİLMEDİ** (ne fonksiyonlar ne kurallar).
Web ve mobil aynı backend'i kullanır: `functions/` (Cloud Functions 2nd gen, Node 20, `europe-west1`).

## 1. UYARI: mobil uygulama kırılır

`firestore.rules` artık istemciden **`Event.seats`**, **`Ticket`** (create/update/delete), **`Order`** ve
**`UserLimits`** yazımını kapatır. Mevcut Flutter uygulaması şunları istemciden yapıyor ve bu kurallarla
**çalışmaz**: `attemptReservation`, `releaseReservation`, `confirmPurchase`, `createTicket`
(`lib/features/events/data/datasources/event_remote_data_source_and_impl.dart`,
`lib/features/events/presentation/providers/event_provider.dart`, `tickets/.../ticket_remote_data_source...`).
Kuralları deploy etmeden önce mobil taşınmalı (bölüm 6) ya da kurallar mobil sürümle eş zamanlı yayınlanmalı.
Eski mobil sürümler kurallar yayınlandığında satın alamaz; zorunlu güncelleme gerekir.

## 2. Mimari

```
istemci (web/mobil) ──callable──► holdSeats ─► Event.seats 'reserved' + Order 'held'  (transaction)
                                 startPayment ► Order 'paying' + iyzico Checkout Form oturumu
iyzico ──POST token──► iyzicoCallback ─► token'ı iyzico'ya SORARAK doğrula ─► tek transaction:
                                         koltuk 'sold' + Ticket + Notification + Order 'paid'
                                 confirmFree ─► (ücretsiz) aynı bilet üretimi, UserLimits.freeTickets++
expireHolds (5 dk) ─► süresi dolan 'held'/'paying' siparişleri kapatır, koltukları serbest bırakır
```

Sözleşme (web ajanı bunu varsayar):

| Fonksiyon | Girdi | Çıktı |
|---|---|---|
| `holdSeats` | `{eventId, seatIds[≤3]}` | `{orderId, expiresAt(ms), total, currency:'TRY', free, seats:[{id,price}]}` |
| `releaseHold` | `{orderId}` | `{ok:true}` |
| `startPayment` | `{orderId, provider:'iyzico', returnUrl}` | `{provider, paymentPageUrl?, checkoutFormContent?, token}` |
| `confirmFree` | `{orderId}` | `{ticketIds:[...]}` (id = orderId, tek bilet, `buySeats` tüm koltukları içerir) |
| `iyzicoCallback` (HTTPS POST) | iyzico `token` | `302 ${SITE_URL}/odeme-sonuc?order=<id>&durum=basarili\|hata` |
| `expireHolds` | zamanlanmış (5 dk) | — |

Hata kodları (mesajlar Türkçe, kullanıcıya gösterilebilir): `unauthenticated`, `invalid-argument`,
`permission-denied`, `not-found`, `failed-precondition` (koltuk dolu / süre doldu / seans geçti),
`resource-exhausted` (3 koltuk, ücretsiz 3 bilet, hız sınırı), `unavailable` (ödeme sağlayıcısı), `internal`.

Veri modeli: `Order/{orderId}` (alanlar görev sözleşmesindeki gibi + `totalKurus`, `unitPriceKurus`, `paymentSession`,
`refundRequired`, `failureReason`, `ticketIds`). `Ticket/{orderId}` mobil `TicketModel` ile birebir alanlar
(`_id,_createdAt,_updatedAt,customerId,showId,stageId,eventId,orderPrice,orderMethod,buySeats,isPast,showName,
showImageUrl,stageName,eventDate`) + `orderId`. `orderMethod`: ödemeli `card`, ücretsiz `free`
(mobil `ticketPaymentLabel` `free` için ham metin gösterir; `'free' => 'Ücretsiz'` eklenmeli).
`Event.seats[sid]` (herkese açık, KİMLİKSİZ — bkz. bölüm 9): `{status:'available'}` | `{status:'reserved', orderId, holdExpiresAt(ms), reservedAt}` | `{status:'sold', orderId}` | `{status:'blocked'}`.
`UserLimits/{uid}` = `{freeTickets, holdWindowStart, holdCount}`.

İş kuralları (hepsi sunucuda, `functions/src/config.js` sabitleri):
- Fiyat yalnızca `Event.price`'tan (`"150"`, `"1.250,50"` desteklenir; boş/0 = ücretsiz; çözülemeyen = satış kapalı). Tutar kuruş tamsayısıyla hesaplanır. İstemciden fiyat/tutar alanı okunmaz (testle doğrulandı).
- Rezervasyon Firestore transaction'ında; iki eşzamanlı hold'dan biri `failed-precondition` alır.
- Tutma süresi 10 dk; ödeme başlayınca 30 dk'ya uzar (iyzico token ömrü). Süresi dolmuş `reserved` koltuk, `expireHolds` gecikse bile başkasınca alınabilir; eski sahip onaylayamaz.
- Etkinlik başına kullanıcı en fazla 3 aktif (reserved+sold) koltuk. Kullanıcının aynı etkinlikteki bekleyen (`held`) siparişi yeni seçimle otomatik iptal edilir (sayfa yenileme UX'i); `paying` olanlar değişmez.
- Ücretsiz etkinlik: tüm ücretsiz etkinliklerde toplam 3 bilet (`FREE_TICKET_LIMIT`); sayaç `UserLimits.freeTickets`, hold'da erken, `confirmFree` transaction'ında kesin kontrol. **Bilet iptali geliştirilirse sayaç azaltılmalıdır** (şu an iptal akışı yok).
- Geçmiş/başlamış seansa hold ve onay reddedilir (tarih "gg.aa.yyyy,ss:dd" = İstanbul saati).
- Hız sınırı: kullanıcı başına dakikada 8 hold denemesi (`UserLimits`, başarısız denemeler de sayılır).
- Callback doğrulaması (provider-bağımsız, `verify()`): `paymentStatus==='SUCCESS'`, `paidPrice` ve `price` == sipariş toplamı (kuruş), `currency==='TRY'`, `conversationId` ve `basketId` == orderId, token == `Order.providerToken`, sipariş `paying`, koltuklar hâlâ bu siparişte. Hepsi sağlanmazsa bilet üretilmez; ödeme alınmışsa sipariş `failed` + `refundRequired:true` işaretlenir (log: "ÖDEME ANOMALİSİ").
- İdempotency: callback tekrarları `Order.status==='paid'` ile kısa devre olur; bilet id'si = orderId ve `tx.create` kullanıldığından çift bilet fiziksel olarak imkânsız.
- Kaçan callback: `expireHolds`, süresi dolan `paying` siparişler için sağlayıcıya yeniden sorar; ödeme alınmışsa bileti üretir.

## 3. Kurulum (deploy ETMEDEN önce, sahibi yapar)

1. Gerekli API'ler: Cloud Functions, Cloud Build, Artifact Registry, Cloud Scheduler, **Secret Manager** (Blaze planı şart).
2. iyzico sandbox hesabı → API anahtarı + gizli anahtar. Repoya ASLA yazılmaz.
   ```
   firebase functions:secrets:set IYZICO_API_KEY      --project ticketappflutter
   firebase functions:secrets:set IYZICO_SECRET_KEY   --project ticketappflutter
   ```
3. Parametreler (deploy sırasında sorulur ya da `functions/.env.<proje>` dosyasında — bunlar sır değildir):
   - `IYZICO_BASE_URL` (varsayılan SANDBOX `https://sandbox-api.iyzipay.com`; canlı: `https://api.iyzipay.com`)
   - `SITE_URL` (varsayılan `https://tiyatrol-web.web.app`; özel alan adına geçince güncelle, `/odeme-sonuc` sayfasının kökü)
   - `ENFORCE_APP_CHECK` (varsayılan `false`, bölüm 5)
4. iyzico panelinde callback URL ayrıca tanımlanmaz; her istekte `callbackUrl` olarak
   `https://europe-west1-ticketappflutter.cloudfunctions.net/iyzicoCallback` gönderilir. Proje kimliği farklıysa `index.js > callbackUrl()` düzenlenir.
5. `cd functions && npm ci`; sonra (sırayla, kuralları mobil taşındıktan sonra):
   `firebase deploy --only functions` ve `firebase deploy --only firestore:rules,firestore:indexes`.
   `firestore.indexes.json` içindeki `Order(status, expiresAt)` bileşik indeksi `expireHolds` için **zorunludur**.
6. CORS: callable'lar yalnızca `functions/src/config.js > ALLOWED_ORIGINS` içindeki alan adlarından çağrılır (emülatörde localhost eklenir). Özel alan adı eklenirse oraya da ekleyin.
7. Yerel test/geliştirme: `functions/.secret.local` dosyasına (git'e girmez) sahte değerler yazılabilir. Gerçek anahtarı yerel dosyaya koymayın.

## 4. Tehdit modeli

| Tehdit | Önlem |
|---|---|
| İstemci fiyatı/tutarı oynatır | Fiyat yalnızca sunucuda `Event.price`'tan; istemci tutar alanı okunmaz; callback'te sağlayıcının `paidPrice`'ı siparişle kuruşu kuruşuna eşleştirilir |
| Başkasının koltuğunu çalma / sahte koltuk yazımı | İstemci `Event.seats` yazamaz (rules); yazımlar Admin SDK transaction'ı |
| Çift satış (yarış) | Event dokümanı üzerinde transaction; eşzamanlı test var |
| Sahte bilet üretme (`Ticket` create) | Rules: create kapalı; yalnızca doğrulanmış ödeme/onay üretir |
| Sahte callback (kendi `token`'ını POST etme) | Callback'e güvenilmez; token sunucuda iyzico `detail` ile sorgulanır, siparişle eşleşmeyen sonuçta bilet yok |
| Callback tekrarı | İdempotent (bkz. yukarı) |
| Başka siparişin başarılı ödemesini kendi siparişine bağlama | `conversationId`/`basketId`/token/tutar eşleşmesi zorunlu |
| Ücretsiz bilet limitini aşma / sıfırlama | Sayaç `UserLimits` rules ile yazılamaz; transaction'da kontrol; eşzamanlı onay testi var |
| Koltuk kilitleme (DoS) | 3 koltuk/etkinlik, 10 dk süre, hız sınırı, `expireHolds`; kullanıcı giriş yapmış olmalı |
| Başkasının siparişini okuma/iptal | Order okuma yalnızca sahibi; callable'larda sahiplik kontrolü (`permission-denied`) |
| Gizli anahtar sızıntısı | Yalnızca Secret Manager (`defineSecret`); repoda/`.env`'de yok; loglanmaz |
| Open redirect | Callback yönlendirmesi yalnızca `SITE_URL`; `returnUrl` izinli alan adı listesiyle doğrulanır ve yönlendirmede KULLANILMAZ |
| Bot/sahte istemci | `ENFORCE_APP_CHECK` (bölüm 5), CORS, kimlik zorunlu, hız sınırı |
| PII sızıntısı | Loglarda yalnızca orderId/hata kodu; istemciye ham hata dönmez (`internal` + genel mesaj); iyzico'ya yalnızca zorunlu alanlar |

## 5. App Check

Fonksiyonlar App Check belirtecini (varsa) doğrular. `ENFORCE_APP_CHECK=true` yapılınca belirtecsiz çağrılar reddedilir. Açmadan önce:
web için reCAPTCHA Enterprise/v3, Android Play Integrity, iOS App Attest sağlayıcıları Firebase konsolunda kaydedilmeli ve istemcilere
`firebase_app_check` (mobil) / App Check SDK (`site/`) eklenmeli; aksi hâlde tüm meşru çağrılar da reddedilir. Varsayılan KAPALI.

## 6. Mobil geçiş planı

Ön koşul: `cloud_functions` paketi (`FirebaseFunctions.instanceFor(region: 'europe-west1')`).

1. **Yeni data source** `PurchaseRemoteDataSource`: `holdSeats(eventId, seatIds)`, `releaseHold(orderId)`, `startPayment(orderId, 'iyzico', returnUrl)`, `confirmFree(orderId)`. Hata kodlarını (`FirebaseFunctionsException.code`) mevcut SnackBar akışına bağla; mesaj Türkçe ve gösterilebilir.
2. **Koltuk seçimi** (`seat_details.dart` / `seats_provider.dart`): koltuğa dokununca `attemptReservation` yerine yerel seçim; "Devam" butonunda tek `holdSeats` çağrısı. Geri sayım `expiresAt`'tan. Vazgeçince `releaseHold`. `canSelectMore` UI ipucu olarak kalır (kesin kontrol sunucuda).
3. **Ödeme**: ücretsiz → `confirmFree`; ücretli → `startPayment` → `paymentPageUrl` (veya `checkoutFormContent` HTML'i bir WebView'da) aç; iyzico dönüşü `iyzicoCallback` → `SITE_URL/odeme-sonuc` sayfası. Uygulama içinde WebView'ın yönlendirmesini `/odeme-sonuc` yakalayıp `durum` + `order` ile sonucu okur; kesin doğrulama için `Order/{id}` dokümanını dinle (`status == 'paid'`). Bilet `Ticket/{orderId}` olarak gelir; `myTicketsProvider` yenilenir.
4. **Sil**: `confirmPurchase`, `createTicket` çağrısı ve bildirim oluşturma (`event_provider.dart`), `attemptReservation`/`releaseReservation`/`initializeAndGetEventSeats` yazımları. Bildirimi artık sunucu yazar.
5. **Sıralama**: (a) fonksiyonları deploy et, web+mobil yeni akışla yayınla; (b) eski mobil sürümü zorunlu güncellemeyle düşür; (c) en son `firestore.rules`'u deploy et. Kuralı erken deploy etmek eski sürümde satın almayı bozar; geç deploy etmek açığı açık bırakır — (b) ile (c) arasını kısa tutun.
6. Admin paneli: koltuk bloklama/açma Event yazımı olduğu için admin hesabıyla çalışır (rules: admin yazabilir). Etkinlik silme/koltuk değiştirme, `Order.status in ('held','paying')` varken yapılmamalı.

## 7. Testler

`npm --prefix functions run test:emulator` (Java gerekli): Firestore + Auth + Functions emülatörü ayağa kalkar, `functions/test/*.test.js` koşar:
- `sales.test.js` — iş mantığı (gerçek Firestore emülatörü, sahte ödeme sağlayıcısı, enjekte edilebilir saat)
- `rules.test.js` — `@firebase/rules-unit-testing` ile `firestore.rules`
- `callable.test.js` — gerçek `index.js` (Functions emülatörü + Auth emülatörü, HTTP)
- `units.test.js` — fiyat/tarih çözümleme, iyzico IYZWSv2 imzası ve yanıt normalizasyonu

## 8. Kalan riskler / yapılacaklar

1. **iyzico entegrasyonu gerçek sandbox ile denenmedi** (yalnızca resmî dokümana göre yazılmış SAHTE sunucuyla uçtan uca test edildi, bölüm 11). İstek/yanıt biçimi ve IYZWSv2 imzası resmî dokümana göre yazıldı ve sahte HTTP istemcisiyle test edildi; ilk iş sandbox anahtarlarıyla uçtan uca deneme yapmak (özellikle `detail` yanıtındaki `basketId`/`conversationId`/`paidPrice` biçimi; doğrulama bilerek katı — eşleşmezse bilet üretilmez).
2. `buyer.identityNumber` iyzico'da zorunlu; TCKN toplanmadığı için sabit yer tutucu (`11111111111`, sandbox'ta kabul edilir) gönderiliyor. Canlıda iyzico/hukuk ile teyit edilmeli; gerekirse kullanıcıdan alınmalı.
3. ~~`Event.seats` uid sızdırıyor~~ — ÇÖZÜLDÜ (26.10.2026, bölüm 9). Kalan: mevcut üretim Event belgelerindeki ESKİ `customerId` alanları `node functions/tools/scrub-seat-owners.js` ile temizlenmedikçe okunabilir kalır (deploy sonrası bir kez çalıştırın).
4. İade/iptal akışı yok. `refundRequired:true` olan siparişler manuel incelenmeli (iyzico panelinden iade). Admin için `Order` listesi ve iade aracı yapılmalı. Bilet iptalinde `UserLimits.freeTickets` azaltılmalı.
5. `Notification` create kuralı istemciye açık kaldı (kendi adına); sunucu artık kendisi yazıyor, mobil taşıma bitince bu kural kapatılabilir.
6. `Seats/{stageId}` sahne planı ile koltuk üretimi sunucuda yapılır; plan değişirse mevcut etkinliklerin `seats` haritası güncellenmez (mevcut davranışla aynı).
7. Hız sınırı kullanıcı başınadır; çok sayıda hesapla dağıtık kilitleme için App Check + e-posta doğrulaması düşünülmeli.
8. `expireHolds` 5 dk'da bir çalışır; süre dolumu ile serbest kalma arasında en çok 5 dk gecikme olur (ancak süresi dolmuş koltuk gecikmeden bağımsız başkasınca alınabilir).
9. Node 20 runtime 2026 sonunda destek sonuna yaklaşır; `engines` ve `firebase.json` runtime'ı Node 22'ye yükseltilmeli (testler Node 24 ile koştu).

## 9. Gizlilik modeli (26.10.2026)

Prensip: **herkese açık belgeden başka bir kullanıcının uid'i / e-postası / adı okunamaz.**

| Koleksiyon | Okuma | Yazma |
|---|---|---|
| `Event` (koltuk haritası dahil) | herkes | yalnız admin (+ Cloud Functions). Koltuk girdisi: `{status, orderId?(opak), holdExpiresAt?, reservedAt?}` — kimlik YOK |
| `Order`, `UserLimits`, `Notification`, `User` | yalnız sahibi | Order/UserLimits: hiç kimse (yalnız Admin SDK); Notification: sahibi kendi adına; User: sahibi (role değiştiremez, role:'admin' ile OLUŞTURAMAZ) |
| `Ticket` | sahibi + admin | yalnız Admin SDK (admin yalnız arşiv özet alanlarını) |
| `Review` | herkes | sahibi; **`userName`/`userImage` kamuya açıktır — bilinçli ürün kararı** |
| `ReviewReport` | yalnız admin | giriş yapan kendi adına create |

- Sahiplik sunucuda `orderId` + `Order.userId` ile denetlenir. Kullanıcı başına koltuk limiti (koltukta kimlik olmadığından) `Ticket` (`customerId+eventId`) ve `paying` Order'lardan hesaplanır.
- Web "benim koltuğum": kullanıcının KENDİ `Order` belgeleri (`where userId==uid and eventId==...`; status `held`/`paying`, süresi dolmamış, `seatIds`). Başkasının tuttuğu koltuk yalnız "başkası tutuyor / dolu" görünür.
- `orderId` opaktır (rastgele); Order/Ticket yalnız sahibine okunur, orderId'den kimliğe ulaşılamaz.
- Her sunucu yazımı koltuktaki eski `customerId` alanını SİLER. Mevcut verinin toplu temizliği: `node functions/tools/scrub-seat-owners.js` (varsayılan emülatör + kuru çalıştırma; üretim için `--project <id> --i-know-this-is-production --apply`; çalıştırılmadı).
- **Güvenlik açığı düzeltildi:** eski `User` create kuralı `role` denetlemiyordu; yeni kullanıcı kendi `User/{uid}` belgesini `role:'admin'` ile oluşturup yönetici olabilirdi (`isAdmin()` bu belgeyi okur). Artık create'te role `user|guest|unknown` olmalı.
- Otomatik denetim: `functions/test/leak.test.js` (iki kullanıcılı; get/list/where/in/!=/limit/yazma/silme; admin ayrımı).
- **Geriye uyum (yönetici bloğu):** eski biçim `{status:'sold', customerId:'__ADMIN_BLOCKED__'}` (mobil admin ve mobil seans tohumlaması) sunucuda ve web'de hâlâ "kapalı" sayılır; sunucunun ürettiği yeni haritalar `{status:'blocked'}` kullanır. Bu işaret sabit bir değerdir, kullanıcı kimliği değil: sızıntı oluşturmaz. Mobil taşınınca `seatVisualOf` `blocked` durumunu `SeatVisual.blocked` yapmalı (şimdi bilinmeyen durum "müsait" çizilir; sunucu yine reddeder), admin blokla/aç `status:'blocked'`/`'available'` yazmalı.

## 10. Süre dolumu ve çökme davranışı — kim ne zaman neyi serbest bırakır

| Durum | Süre | Kim serbest bırakır | Ne olur |
|---|---|---|---|
| `held` (koltuk seçildi, ödeme yok) | 10 dk | (1) başka kullanıcının `holdSeats`'i, süre dolmuşsa anında devralır (lazy takeover); (2) `expireHolds` (5 dk'da bir) Order'ı `expired` yapar, koltukları `available` yapar; (3) kullanıcı `releaseHold` ile vazgeçer | İstemci kapansa/çökse bile süre dolunca koltuk alınabilir. Eski sahip onaylayamaz / ödeme başlatamaz |
| `held`, sayfa kapatıp açıldı | süre dolana dek | kullanıcı | Web, kullanıcının kendi `held` Order'ından devam ettirir ("Onayla"/"Ödemeye geç") ya da "Vazgeç" (tarayıcı belleğine bağlı değil: başka cihazdan da) |
| `paying` (iyzico sayfasında) | 30 dk | (1) başarılı callback → bilet; (2) başarısız callback → `failed`, koltuk serbest; (3) pencere dolunca `expireHolds` ÖNCE iyzico'ya sorar, ödeme yoksa `expired` + koltuk serbest; (4) pencere dolunca başka kullanıcı lazy takeover ile devralabilir | Kullanıcı sayfayı terk ederse en geç 30 dk sonra koltuk serbest |
| `paying` + GEÇ başarılı callback | — | `settle` | Koltuk hâlâ bu siparişteyse bilet üretilir. Koltuk başkasına geçtiyse ya da sipariş `expired/failed` ise **bilet YOK**, sipariş `failed` + `refundRequired:true` (+ `paymentId`) → manuel iade |
| iyzico `fraudStatus=0` (inceleme) | — | `settle` | Bilet verilmez, sipariş `paying` kalır; `expireHolds` karar gelene dek kapatmaz; onay gelince bilet |
| `free_confirmed` / `paid` | — | — | Koltuk `sold`, bilet üretildi; iptal akışı yok |

Web haritası: `holdExpiresAt` + 3 sn (saat sapması toleransı) geçmiş `reserved` koltuğu BOŞ çizer (sunucu da verir).
`expireHolds` zamanlanmış iştir: production'da **Cloud Scheduler gerekir (Blaze plan)**; emülatörde zamanlayıcı çalışmaz, testler `svc.expireHolds()`'u doğrudan çağırır. Zamanlayıcı çalışmazsa koltuklar lazy takeover ile satılabilir kalır, ancak `held/paying` Order'lar `expired`'a dönmez ve kaçan ödemeler kurtarılmaz — Scheduler'ı izleyin.
Kanıt: `functions/test/expiry.test.js` (enjekte saat) ve `payment-e2e.test.js` (veri geri alınarak).

### Manuel iade prosedürü (`refundRequired: true`)
1. Firebase konsolu → Firestore → `Order` → `refundRequired == true` (ya da günlükte "ÖDEME ANOMALİSİ"). Alanlar: `paymentId`, `total`, `failureReason` (`paid_but_unfulfillable`), `anomaly` (neden), `userId`.
2. iyzico merchant panelinde `paymentId` ile işlemi bulun; tutar `total` ile uyuşuyor mu bakın (uyuşmuyorsa olası manipülasyon: iade edin ve hesabı inceleyin).
3. İşlemi panelden **iptal (aynı gün) ya da iade** edin; kullanıcıya e-posta ile bilgi verin (koltuk başkasına geçtiyse başka koltuk/seans önerin).
4. Order'a elle `refundedAt`, `refundNote` yazıp `refundRequired:false` yapın (admin aracı yapılana dek konsoldan). Aynı `paymentId` iki kez iade edilmemeli.
5. `Ticket/{orderId}` OLMADIĞINI doğrulayın.

## 11. iyzico entegrasyonu: doğrulama ve sandbox adımları

`functions/providers/iyzico.js` resmî dokümana (docs.iyzico.com: CF-Initialize, CF-Retrieve, hmacsha256-auth) göre kontrol edildi (26.10.2026): imza `HMAC-SHA256(secret, randomKey + uriPath + body)` hex → `IYZWSv2 base64(apiKey:..&randomKey:..&signature:..)` doğru; `price`/`paidPrice`/`currency`/`basketId`/`conversationId`/`callbackUrl`/`locale`/`enabledInstallments`/`buyer.*`/`billingAddress`/`basketItems` doğru. Düzeltmeler: `buyer.gsmNumber` iyzico'da ZORUNLU (telefon yoksa yer tutucu `+905000000000`); `fraudStatus` işlenir (1 onay, 0 inceleme → bilet yok/bekle, -1 red); `checkoutFormContent` ham HTML ya da Base64 gelse de çözülür. Doküman `paymentStatus` değerlerini listelemiyor — `SUCCESS` varsayımı sandbox'ta doğrulanmalı. `identityNumber` hâlâ yer tutucu (bölüm 8/2).

Sahte sunucu: `functions/test/mock-iyzico/server.js` (imzayı YENİDEN hesaplar, zorunlu alanları ve sepet toplamını denetler). Functions emülatörü `functions/.env.local` (`IYZICO_BASE_URL=http://127.0.0.1:8787`, yalnız emülatör okur) ve `functions/.secret.local` (sahte anahtarlar, gitignore'da; yoksa şu iki satırı oluşturun: `IYZICO_API_KEY=sandbox-fake-api-key`, `IYZICO_SECRET_KEY=sandbox-fake-secret-key`) ile ona bağlanır. `payment-e2e.test.js`: kayıt→hold→startPayment→callback→bilet; tekrar callback→tek bilet; tutarı oynanmış→bilet yok+refundRequired; başarısız ödeme→koltuk serbest; geç callback→refundRequired; inceleme (fraud 0); ücretsiz akış.
**Bu, gerçek iyzico sandbox'ı DEĞİLDİR.** Sandbox deneme adımları:
1. iyzico sandbox hesabı + anahtarlar; `firebase functions:secrets:set IYZICO_API_KEY / IYZICO_SECRET_KEY` (sandbox), `IYZICO_BASE_URL=https://sandbox-api.iyzipay.com`.
2. Functions'ı sandbox/test projesine deploy edin (Blaze). `callbackUrl` herkese açık HTTPS olmalı (otomatik: cloudfunctions.net).
3. iyzico test kartlarıyla (başarılı / yetersiz bakiye / 3D) sipariş verin; `detail` yanıtında `paymentStatus`, `paidPrice`, `price`, `basketId`, `conversationId`, `fraudStatus` GERÇEKTE hangi biçimde geliyor kontrol edin (doğrulama KATI: eşleşmezse bilet üretilmez; "bilet gelmiyor" olarak görünür, `Order.anomaly`'e bakın).
4. 3D Secure sonrası callback'in `token`'ı form-POST getirdiğini ve 302'nin `SITE_URL/odeme-sonuc`'a gittiğini doğrulayın; ödeme formunun iframe'de çalıştığını/üst pencereyi açtığını kontrol edin.
5. Terk senaryosu: ödeme sayfasını kapatın, 35 dk bekleyin; `expireHolds` günlüğü ve koltuğun serbest kalması. Geç ödeme için `refundRequired` akışı.
6. İade: panelden iade deneyin (bölüm 10).

## 12. iyzico başvurusu öncesi kontrol listesi
(Sayfalar web tarafında ayrıca ekleniyor; burada yalnızca gereksinimler.)
- [ ] **Mesafeli satış sözleşmesi** (satıcı unvanı, adres, vergi no, hizmet, bedel, cayma/iade koşulları)
- [ ] **Ön bilgilendirme formu** (sipariş öncesi gösterilir, onay kutusu)
- [ ] **İade / iptal / değişim koşulları** (etkinlik iptalinde iade; tarihli hizmette cayma istisnası)
- [ ] **İletişim bilgileri** (ticari unvan, vergi no/MERSİS, adres, telefon, e-posta) sitede görünür
- [ ] Gizlilik/KVKK aydınlatma metni, çerez bilgisi; kart bilgisinin TiyatRol'a gelmediği açıklaması
- [ ] Canlı alan adı + SSL; fiyatlar TL, KDV bilgisi
- [ ] Gerçek `identityNumber` politikası iyzico ile netleşmiş (bölüm 8/2)
- [ ] Sandbox uçtan uca deneme tamam (bölüm 11); canlıya geçişte `IYZICO_BASE_URL` ve canlı anahtarlar Secret Manager'da
- [ ] Mobil geçiş tamam (bölüm 6) ve kurallar en son deploy; eski sürüm zorunlu güncelleme
- [ ] `expireHolds` için Cloud Scheduler/Blaze; "ÖDEME ANOMALİSİ" günlük alarmı

## 13. Mobil geçiş notu (gizlilik değişikliğinden etkilenen yerler)
Koltukta `customerId` OKUNMAZ (yok). "Benim koltuğum" kullanıcının `Order` belgelerinden (`status in held/paying`, `where userId==uid`) ya da `Ticket`'tan (satılmış, `buySeats`) çıkarılır. `seats_provider.dart` (`cId == customerId` sayımı), `seat_plan.dart` (`ownerId`), `seat_info.dart`, admin bilet sekmesi ve `event_remote_data_source` blok/tohumlama kodu bu yüzden değişmeli; `blocked` durumu desteklenmeli (bölüm 9). `Notification` create kuralı mobil taşıma bitince kapatılabilir. Not: `site/tools/mock-functions/` eski (sunucusuz) geliştirme sahtesidir; artık gerçek functions emülatörü kullanın (`firebase emulators:start --only firestore,auth,functions` + `node site/tools/seed-emu.mjs`, tarayıcıda `localStorage['tiyatrol.emu']='1'` AYARLANIP SAYFA YENİLENDİKTEN SONRA giriş yapılmalı — yoksa gerçek Auth'a istek gider).

## 14. Satış modları, rezervasyon, iptal, kapı kontrolü, sistem sağlığı (26.10.2026)

iyzico canlı olana kadar varsayılan mod **rezervasyon**: bilet onaylanır, ödeme etkinlik günü sahnede alınır.

### Modlar — `Config/satis` (herkes okur, yalnız admin yazar; kurallar şemayı doğrular)
`{ mode: 'kapali' | 'rezervasyon' | 'online', rezervasyonLimit: 3, iptalSaat: 24 }`. Belge yoksa/bozuksa varsayılan `rezervasyon / 3 / 24`.
Sunucu **her çağrıda** okur (önbellek yok); mod değişimi anında geçerlidir.

| Mod | `holdSeats` | `confirmFree` | `confirmReservation` | `startPayment` |
|---|---|---|---|---|
| kapali | reddedilir ("Bilet satışı şu anda kapalı.") | açık (mevcut hold'lar için) | reddedilir | reddedilir |
| rezervasyon | açık | açık | açık | reddedilir ("Online ödeme şu anda çalışmıyor…") |
| online | açık | açık | reddedilir | açık (iyzico kodu aynen) |

### Rezervasyon (`confirmReservation`)
Yalnızca ücretli, `held`, süresi dolmamış, sahibi çağıran sipariş. Tek transaction: koltuklar `sold`, tek Ticket (id = orderId,
`orderMethod: 'venue'`, `paymentStatus: 'pay_at_venue'`, tutar sunucudan), bildirim, `UserLimits.reservations` artar.
Limit **koltuk** bazlıdır (ücretsiz bilet sayacı gibi): tüm etkinliklerde toplam aktif rezervasyon koltuğu ≤ `rezervasyonLimit`.
`cancelled` ve `no_show` sayaçtan düşer; `paid` (sahnede ödendi) hâlâ aktif sayılır. Aynı sipariş tekrar onaylanırsa idempotent.
Sayaç transaction içinde okunup yazıldığından eşzamanlı çağrılar limiti aşamaz (test: 5 eşzamanlı onay, tam 3 başarılı).

### İptal (`cancelTicket`)
Sahibi kendi `venue` veya `free` biletini, seansa en az `iptalSaat` saat varsa iptal eder: koltuklar `available` (yalnızca hâlâ bu bilete
ait olanlar), `paymentStatus: 'cancelled'`, `cancelledAt`, ilgili sayaç (`reservations` / `freeTickets`) azalır; ücretsiz limit
sayacının düşmemesi açığı kapandı. İptal edilen bilet "etkinlikte en fazla 3 koltuk" sayımına girmez. Kartla ödenmiş bilet
kullanıcı tarafından **iptal edilemez** (`failed-precondition`, iade için iletişim); kapıdan geçmiş bilet de edilemez. Tekrar iptal idempotent.

### Yönetici işlemleri (yalnız `User/{uid}.role == 'admin'`, sunucuda denetlenir)
- `adminSetTicketStatus({ticketId, paymentStatus})`: `venue` biletinde `paid / pay_at_venue / no_show / cancelled`; `free`'de `no_show / cancelled`;
  `card`'da yalnız `no_show` (iade ödeme panelinden). İptal edilen yeniden açılmaz. Sayaçlar tutarlı güncellenir.
- `adminCheckIn({ticketId})`: QR'daki değer bilet kimliğidir. İlk okuma `{ok:true}` ve `usedAt` yazar; ikinci okuma `{ok:false, already:true}`;
  iptal/gelmedi `{ok:false}` (+ `ticket.paymentStatus`); bilinmeyen kod `not-found`. Eşzamanlı okumalarda yalnız biri geçerli sayılır.
  `pay_at_venue` bilet geçerlidir ama panel "ÖDEME ALINACAK" uyarısı gösterir.
- Ticket yazımı yine yalnız sunucudadır; admin istemcisi `paymentStatus/usedAt` alanlarını **yazamaz** (kural testi var).

### Sistem sağlığı (`adminHealth`, panelde "Biletler & Kapı")
`expireHolds` her çalışmada `System/expireHolds` {lastRunAt, expiredOrders, settledPaid, releasedSeats} yazar (`System` yalnız admin okur).
`adminHealth`: kalp atışı (15 dk'dan eskiyse `stale`, panel kırmızı), 10 dk'dan uzun süredir `held`/`paying` kalan siparişler,
bugünkü/toplam rezervasyon ve ücretsiz bilet sayıları (İstanbul günü; **iptal edilenler sayılmaz**, ayrıca `cancelled:{today,total}`), hatırlatma görevi sağlığı (`reminders`), `refundRequired` siparişler. Bugünkü sayı sorgusu için
`Ticket(orderMethod, _createdAt)` bileşik dizini `firestore.indexes.json`'a eklendi; **deploy'da indexes de yayınlanmalı**.

### Bildirim, istatistik, sahne kumandası
Görüntülenme sayacı (`trackView`), yönetim dashboard'u (`adminStats`), bildirim gönderme (`adminSendNotification`, alarm türü, şablonlar), otomatik hatırlatma (`eventReminders`) ve
iptal edilenler listesi (`adminCancelled`): ayrıntı, kurulum, maliyet ve sınırlar **`docs/BILDIRIM-ISTATISTIK.md`**'de.

### Testler
`npm --prefix functions run test:emulator`: 97 test (71 önceki + 26 yeni: `reservation.test.js`, `rules.test.js`, `callable.test.js`).
Mevcut ödeme testleri `Config/satis = online` ile çalışır (`helpers.makeService({satis})`, `setSatis`).
