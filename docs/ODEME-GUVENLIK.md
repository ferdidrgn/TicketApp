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
`Event.seats[sid]` = `{status, customerId, reservedAt, orderId, holdExpiresAt(ms), soldAt}`; mevcut biçim korunur.
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

1. **iyzico entegrasyonu gerçek sandbox ile denenmedi.** İstek/yanıt biçimi ve IYZWSv2 imzası resmî dokümana göre yazıldı ve sahte HTTP istemcisiyle test edildi; ilk iş sandbox anahtarlarıyla uçtan uca deneme yapmak (özellikle `detail` yanıtındaki `basketId`/`conversationId`/`paidPrice` biçimi; doğrulama bilerek katı — eşleşmezse bilet üretilmez).
2. `buyer.identityNumber` iyzico'da zorunlu; TCKN toplanmadığı için sabit yer tutucu (`11111111111`, sandbox'ta kabul edilir) gönderiliyor. Canlıda iyzico/hukuk ile teyit edilmeli; gerekirse kullanıcıdan alınmalı.
3. `Event.seats` **herkese açık okunuyor** ve `customerId` (uid) içeriyor: koltuk sahibi uid'ler görünür. Çözüm: koltuk planını `customerId`'siz bir `SeatMap` görünümüne ya da alt koleksiyona taşımak (şu an veri modeli korunuyor).
4. İade/iptal akışı yok. `refundRequired:true` olan siparişler manuel incelenmeli (iyzico panelinden iade). Admin için `Order` listesi ve iade aracı yapılmalı. Bilet iptalinde `UserLimits.freeTickets` azaltılmalı.
5. `Notification` create kuralı istemciye açık kaldı (kendi adına); sunucu artık kendisi yazıyor, mobil taşıma bitince bu kural kapatılabilir.
6. `Seats/{stageId}` sahne planı ile koltuk üretimi sunucuda yapılır; plan değişirse mevcut etkinliklerin `seats` haritası güncellenmez (mevcut davranışla aynı).
7. Hız sınırı kullanıcı başınadır; çok sayıda hesapla dağıtık kilitleme için App Check + e-posta doğrulaması düşünülmeli.
8. `expireHolds` 5 dk'da bir çalışır; süre dolumu ile serbest kalma arasında en çok 5 dk gecikme olur (ancak süresi dolmuş koltuk gecikmeden bağımsız başkasınca alınabilir).
9. Node 20 runtime 2026 sonunda destek sonuna yaklaşır; `engines` ve `firebase.json` runtime'ı Node 22'ye yükseltilmeli (testler Node 24 ile koştu).
