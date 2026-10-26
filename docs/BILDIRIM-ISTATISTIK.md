# Bildirim, istatistik ve sahne kumandası (26.10.2026)

Bu belge `functions/src/{notify,stats}.js`, yönetim paneli (`site/js/admin/{dashboard,sahne,kapi}.js`) ve ilgili kurallarla ilgilidir.
Satış/ödeme tarafı: `docs/ODEME-GUVENLIK.md`. **Deploy edilmedi**; aşağıdaki "Kurulum" adımları sahibi tarafından yapılır.

## 1. Neler var

| Parça | Ne yapar | Kim çağırır |
|---|---|---|
| `adminHealth` (güncellendi) | `reservations` / `freeTickets` artık **iptal edilenleri saymaz**; yeni `cancelled:{today,total}` ve `reminders` (hatırlatma sağlığı) | yönetici |
| `adminCancelled({limit})` | İptal edilen biletler (en yeni önce): müşteri adı, ne zaman, kim iptal etti (`customer`/`admin`) | yönetici |
| `trackView` (HTTPS, POST) | Oyun/oyuncu/sahne/topluluk görüntülenme sayacı | herkese açık site (anonim) |
| `adminStats({month?})` | Dashboard verisi: KPI'lar, trend, oyun/mekân tabloları, doluluk, dönüşüm | yönetici |
| `adminNotifyPreview({target, template?, params?, title?, body?})` | Gönderimden önce alıcı sayısı + şablon listesi + üretilmiş metin önizlemesi | yönetici |
| `adminSendNotification({target, title, body, kind, template?, params?, confirm?, requestId?})` | Bildirim gönderir (FCM + uygulama içi `Notification` + `NotificationLog`) | yönetici |
| `eventReminders` (zamanlanmış, 15 dk) | Seansa ~24 sa ve ~2 sa kala biletlilere otomatik hatırlatma | Cloud Scheduler |

Tüm `admin*` callable'lar sunucuda `User/{uid}.role == 'admin'` denetler; panel yalnızca arayüzdür.

## 2. İptal sayaçları (Görev 1)

- `reservations` = `orderMethod=='venue'` biletler − bunlardan `paymentStatus=='cancelled'` olanlar (bugün ve toplam). `freeTickets` aynı şekilde.
  `no_show` (gelmedi) **aktif sayılır**, iptal değildir.
- `cancelled.total` = `paymentStatus=='cancelled'` bilet sayısı; `cancelled.today` = `cancelledAt` bugün (İstanbul) olanlar. Yani "bugün iptal edilen"
  dün alınıp bugün iptal edileni de sayar; "bugün rezervasyon" ise bugün oluşturulup hâlâ aktif olanlardır.
- İptal artık kim tarafından yapıldığını kaydeder: Ticket'ta `cancelledBy: 'customer'|'admin'` (+ yönetici için `cancelledByUid`). Eski kayıtlarda alan yoktur ("Bilinmiyor").
- Panel: "Biletler & Kapı" → sistem sağlığında **İptal edilen (bugün / toplam)** kutusu (tıklayınca bölüm açılır), **İptal edilenler** bölümü (kim, ne zaman, kim iptal etti),
  bilet listesinde varsayılan süzgeç **Aktif (iptaller hariç)** (isteğe bağlı: Tüm durumlar / yalnız İptal).
- **Yeni dizinler** (`firestore.indexes.json`, deploy'da `--only firestore:indexes` ile yayınlanmalı; emülatör dizin istemez, üretim ister):
  1. `Ticket(orderMethod, paymentStatus, _createdAt)` — "bugün iptal" / "bu ay iptal" sayımları.
  2. `Ticket(showId, _createdAt)` — oyun başına "bu ay oluşan bilet" sayımı (dashboard).
  Mevcut `Ticket(orderMethod, _createdAt)` dizini kalır. `cancelledAt` / `paymentStatus` / `usedAt` tek alanlı otomatik dizinleri yeterlidir.

## 3. Görüntülenme istatistikleri (Görev 2)

### trackView
- `POST https://europe-west1-<proje>.cloudfunctions.net/trackView`, gövde `{"k":"show|player|stage|team","id":"<belge kimliği>"}`
  (`Content-Type: text/plain` önerilir → CORS ön kontrolü gerekmez; `application/json` da kabul edilir).
- Sunucu: yalnız POST (aksi 405); `k`/`id` doğrulama (`[A-Za-z0-9_-]{1,64}`, geçersiz → 400); `Origin` izinli listede değilse, bot UA'sıysa
  (Googlebot, curl, headless… regex), IP/hedef hız sınırı aşıldıysa (instance başına IP: 30/dk, aynı IP+hedef: 6/dk) veya belge yoksa
  **sessizce 204** (yazma yok). Başarılıda yine 204 — yanıttan hangi kuralın tetiklendiği anlaşılmaz.
- Yalnız **var olan** `Show/Player/Stage/Team` kimlikleri sayılır (instance'ta 1 saat önbellek; var olmayan 5 dk) → sahte kimlikle sayaç belgesi şişirilemez.
- Yazma: bir `batch` ile **2 yazma**: `Stats/views/days/{yyyy-MM-dd}` ve `Stats/views/months/{yyyy-MM}` (Europe/Istanbul günü/ayı); her ikisinde
  `total`, `<k>_total`, `<k>_<id>` alanları `FieldValue.increment(1)`. Kişisel veri, IP, UA, çerez **saklanmaz**.
- Rules: `Stats/**` yalnız admin okur, kimse yazamaz; `NotificationLog` aynı.
- **İstemci**: `site/js/izle.js` (`ui.js` yükler; adres `/oyun|oyuncu|sahne|topluluk/<ad>-<id>` ise `{k,id}` POST eder). Oturum başına bir kez, DNT açıksa ve yerel geliştirmede (emülatör bayrağı yoksa) göndermez. JSON gövde CORS ön kontrolü (OPTIONS) tetikler; `trackView` bunu `cors` seçeneğiyle yanıtlar.

### adminStats
Dönen: `kpi` (aylık görüntülenme, aktif rezervasyon/ücretsiz bilet [bu ay + toplam], yaklaşan seans, aktif oyun, iptal oranı, gelmeme oranı, kapıdan geçen, dönüşüm),
`days` (ayın günlük görüntülenmesi), `trend` (12 ay toplam + en çok görüntülenen 12 oyunun 12 aylık serisi), `topShows` (ilk 20 oyun: görüntülenme, bilet, bu ay bilet,
dönüşüm, seans, doluluk), `sessions` (yaklaşan seanslar: satılan/tutulan/toplam koltuk, doluluk), `venues` (mekân sıralaması), `topStages/topPlayers/topTeams`.
- Doluluk = satılan koltuk / (koltuk − engelli koltuk) `Event.seats`'ten. Koltuk düzeni henüz oluşmamış seansta (`seats` boş) doluluk `null`.
- İptal/gelmeme oranları **tüm zamanlar** üzerindendir (ay seçimi yalnız görüntülenme + "bu ay" bilet sayılarını değiştirir).
- Dönüşüm = bu ay oluşturulan bilet / bu ay oyun sayfası görüntülenmesi (oyun başına: o oyunun bu ay oluşan bileti / görüntülenmesi; iptaller dahil, çünkü oluşturma anı ölçülür).
- Oyun eşlemesi: `Event.showId` tek doğruluk kaynağı, boşsa `Show.eventsId` yedek (CLAUDE.md kuralı).

### Dashboard (panel → Genel bakış)
Ay seçici (son 12 ay), KPI kartları, günlük sütun grafiği, aylık çizgi grafiği (oyun seçici), en çok görüntülenen oyunlar, seans doluluğu, oyun tablosu, mekân sıralaması.
Grafikler satır içi SVG (harici kütüphane yok); renkler `--accent/--ink-*/--line` ile tema değişince değişir; genişlik kapsayıcıya göre çizilir (telefonda okunur);
dokunma/imleçle değer okuması var. Sonuç ay başına **2 dk** bellekte tutulur (maliyet); "Yenile" önbelleği atlar.

## 4. Bildirim gönderme (Görev 3)

### Hedefler ve içerik
`target.type`: `all` → FCM konusu `all_users` (mobil `FCMManager` zaten abone) · `user` → `User.fcmToken` · `show`/`event` → o oyunun/seansın **aktif** biletlerinin
`customerId`'leri (iptal/gelmedi hariç, tekil) → `User.fcmToken` (boşlar atlanır; aynı cihaz token'ı birden çok hesapta tekilleştirilir) → 500'lük `sendEachForMulticast` parçaları.
Kalıcı geçersiz token (`registration-token-not-registered`) kullanıcıdan temizlenir.
Her alıcı için `Notification/ann_<gönderimKimliği>_<uid>` (`userId, title, body, isRead:false, type:'announcement'|'alarm', eventId?, showId?, _createdAt, createdAt`) ve
tek bir `NotificationLog/<gönderimKimliği>` (kim gönderdi, hedef, şablon, tür, başlık/gövde, alıcı/token/başarılı/başarısız sayıları, parça sayısı, zaman) yazılır.
`all` hedefinde uygulama içi belgeler **tüm `User` belgeleri için** yazılır (üst sınır 5000 kullanıcı; üstünde yalnız push gider, `NotificationLog.inAppSkipped:true`).
Mobil `NotificationType` bilinmeyen türleri `unknown` olarak okur (çökmez); `announcement/alarm/reminder` için özel simge/rozet gerekirse `lib/` tarafı ayrıca genişletilmeli.

### Şablonlar (sunucuda sabit; panelde düğme)
| id | Metin | Tür | Zaman/hedef kuralı |
|---|---|---|---|
| `baslamak_uzere` (dk = 10 \| 5) | "{oyun} {dk} dakika sonra başlıyor" | **alarm** | yalnız seans hedefi, seansa ±24 sa |
| `basladi` | "{oyun} başladı — lütfen telefonlarınızı sessize alın / kapatın" | normal | aynı |
| `ara` (dk 5–30) | "Birinci perde bitti — {dk} dakika ara" | normal | aynı |
| `ara_bitiyor` | "Ara bitiyor — 5 dk içinde yerlerimizi alalım" | **alarm** | aynı |
| `bitti` | "{oyun} bitti — teşekkürler, izlenimini yaz" | normal | aynı |
| `ertelendi`, `iptal` | özel metin (başlık varsayılanı: "{oyun} seansı ertelendi/iptal edildi") | normal | seans veya oyun hedefi; zaman sınırı yok |
| `genel` | özel başlık + mesaj | normal/alarm | her hedef, zaman sınırı yok |

Değişkenler `{oyun}`, `{sahne}`, `{dk}`, `{saat}`. Sabit şablonlarda metin **sunucuda üretilir** (istemcinin gönderdiği başlık/gövde yok sayılır); taşan başlık 60'a kısaltılır.

### Alarm yükü
- Android: `priority:'high'`, `ttl: 120000 ms`, `notification.channelId:'tiyatrol_alarm'`, `sound:'default'`, bildirim önceliği `max`, titreşim.
- iOS (APNs): `apns-priority: 10`, `apns-push-type: alert`, `apns-expiration` (+2 dk), `aps.sound:'default'`, `aps.interruption-level:'time-sensitive'`.
- `data`: `{kind:'alarm', eventId?, route:'/notifications'}` (tümü string). Normal bildirim: `android.priority:'normal'`, alarm alanları yok.

### Kötüye kullanım koruması
Başlık ≤ 60, gövde ≤ 240 karakter · yönetici başına **saatlik 30 gönderim** (`UserLimits/{uid}.notifyWindowStart/notifyCount`) ·
`all` ve alıcı > 1 olan her gönderimde `confirm:true` zorunlu (yoksa `failed-precondition`) · sahne şablonları yalnız ±24 sa içindeki seanslarda ·
**yinelenen gönderim**: panel her önizlemede bir `requestId` üretir; aynı `requestId` (ya da kimliksizse aynı içerik + 10 dk dilimi) ikinci kez gelirse
`{duplicate:true}` döner, yeniden gönderilmez ve `Notification` çoğalmaz (id'ler deterministik).

### Panel: "Sahne kumandası"
Seans seçici (±24 sa'dakiler üstte), **önceden** "N bilet sahibi · M push alabilir", büyük şablon düğmeleri (telefonda tek sütun, ≥72 px), "Ara süresi" ayarı,
önizleme penceresi (bildirimin nasıl görüneceği + alıcı sayısı + "Gönder"), sonuç özeti, serbest mesaj formu (seans/oyun/herkes/tek kişi, normal/alarm),
**Son gönderimler** (`NotificationLog` son 20) ve otomatik hatırlatma anahtarı.

### Bilinen sınırlar
- **Tek token**: mobil uygulama `User.fcmToken`'ı tek alan olarak tutar. Birden çok cihazı olan kullanıcıya push yalnız son giriş yapılan cihaza gider
  (uygulama içi kutu her cihazda görünür). Çözüm: `User.fcmTokens` (dizi/harita) — `lib/` değişikliği gerektirir, bu işte yapılmadı. `all` hedefi konu aboneliği kullandığından tüm cihazlara ulaşır.
- Girişsiz (misafir) kullanıcılar yalnız `all` (konu) ile ulaşılır; `show/event/user` hedefleri hesap gerektirir.
- Push "iletildi" garantisi yoktur; `success` FCM'in kabul ettiği mesaj sayısıdır.

## 5. Otomatik hatırlatmalar (Görev 4)

- `eventReminders`, **her 15 dk**. Pencereler: seansa 22–24 sa kala → "Yarın/Bugün seansın var · {oyun}, {saat}, {sahne}", 1–2 sa kala → "Seansa 2 saat kaldı".
  Bu yüzden çalışmalardan biri kaçsa bir sonraki yakalar. Normal (alarm değil) bildirimdir.
- **İdempotent**: kullanıcı başına `Notification/rem24_<event>_<uid>` / `rem2_…` belgesi `create()` ile yazılır (eşzamanlı/yeniden çalışmada ikincisi `ALREADY_EXISTS` alır → push yok),
  ardından biletlere `remind24At` / `remind2At` işaretlenir. Sırayla: belge → push → bayrak; push sırasında çökme olursa o kullanıcı için **en fazla bir** push kaçar (çift gönderim olmaz).
- Atlananlar: iptal/gelmedi biletler, kapıdan geçmiş biletler, token'sız kullanıcılar (uygulama içi kutuya yine yazılır).
- Seans bulma: `Event.date` metin ("gg.aa.yyyy,ss:dd") ise bugünün ve +24 sa'nın **gün öneki** sorgulanır (`date >= "26.10.2026,"`), Timestamp ise aralık sorgusu. **Sıfır dolgulu** biçim varsayılır (panel öyle yazar);
  `5.1.2026,20:00` gibi dolgusuz yazılmış eski kayıtlar bulunamaz.
- Anahtar: `Config/bildirim { autoReminders: true|false }` (varsayılan **açık**; belge yoksa açık). Panel: Sahne kumandası → "Otomatik hatırlatmalar". Kurallar: yalnız admin yazar, değer mantıksal olmalı.
- Kalp atışı: `System/eventReminders { lastRunAt, enabled, events, sent24, sent2, failed, users }`; kapalıyken de yazılır. `adminHealth.reminders.stale` (açıkken 45 dk'dır çalışmadıysa) → "Biletler & Kapı" ve Sahne kumandası kırmızı uyarı verir.

## 6. Kurulum (sahibi yapar)

1. `firebase deploy --only firestore:rules,firestore:indexes` (yeni kurallar: `Stats`, `NotificationLog`, `Config/bildirim`; yeni 2 dizin — oluşması birkaç dakika sürer, o sürede `adminStats` / `adminHealth` "index required" hatası verebilir).
2. `firebase deploy --only functions` — `eventReminders` için **Cloud Scheduler API** açık ve proje Blaze olmalı (deploy işi otomatik oluşturur; `expireHolds` ile birlikte 2 iş). Secrets: mevcut iyzico sırları yeterli; FCM için ek anahtar gerekmez (Admin SDK varsayılan hizmet hesabı).
3. Hizmet hesabının FCM göndermesi için Firebase Cloud Messaging API (v1) etkin olmalı (yeni projelerde varsayılan).
4. Sayaç istemcisi (`izle.js`) zaten sitede; ek adım yok.
5. **Mobil** (`lib/` bu işte düzenlenmedi): (a) Android'de `tiyatrol_alarm` bildirim kanalı (önem: yüksek, alarm/bildirim sesi) uygulama açılışında oluşturulmalı — kanal yoksa FCM varsayılan kanala düşer ve alarm sıradan bildirim gibi davranır;
   (b) iOS'ta Xcode → Signing & Capabilities → **Time Sensitive Notifications** eklenmeli; (c) `data.route`/`data.kind` `FCMManager._handleNotificationTap` içinde kullanılabilir.

## 7. Maliyet notları (tahmin; Firestore fiyatı $0,06/100 bin okuma, $0,18/100 bin yazma; ücretsiz kota: 50 bin okuma + 20 bin yazma/gün)

FCM mesajları **ücretsizdir**. Aşağıdakiler Firestore okuma/yazma ve fonksiyon çağrısıdır (2 milyon çağrı/ay ücretsiz).

| İşlem | Okuma | Yazma |
|---|---|---|
| Bir görüntülenme (`trackView`) | 0 (ilk kez/instance/saat: +1 varlık denetimi) | 2 |
| `adminStats` bir çağrı | ≈ 12 (aylar) + ≤31 (günler) + #Show + #Stage + #Event + ~70 sayım sorgusu (≥1 okuma/sorgu) → **~600–1500** (100 oyun / 400 seans) | 0 |
| `adminHealth` | ~12 sayım sorgusu + 6 belge | 0 |
| `adminCancelled` | ≤ limit bilet + ≤ limit kullanıcı (en çok 200+200) | 0 |
| `adminNotifyPreview` | hedef bilet sayısı + alıcı başına 1 kullanıcı | 0 |
| `adminSendNotification` (N alıcı) | bilet sayısı + N (token) + ~4 | N (Notification) + 3 |
| `…` herkese (K kullanıcı, ≤5000) | K sayım/sayfa okuması | K |
| `eventReminders` boşta (96 çalışma/gün) | ~3–10 | 1 (kalp atışı) → ~700 okuma + 96 yazma/gün |
| `eventReminders` pencere içi seans | pencere içindeki her çalışmada o seansın biletleri kadar (24 sa penceresi 8 çalışma, 2 sa penceresi 4 çalışma) → 200 biletli seans ≈ 2400 okuma | alıcı başına 1 + bilet başına 1 bayrak |

Örnek: günde 2.000 görüntülenme ≈ 4.000 yazma (ücretsiz kotada). Panelin Genel bakış'ı açılışta 1 `adminStats` çağırır (ay başına 2 dk önbellek).

## 8. Sesli alarm sınırları (dürüst özet)
- **iOS**: "Kritik Uyarı" (sessiz modu aşan) Apple'ın özel yetkisini gerektirir; uygulamada yok. Kullanılan `time-sensitive` yalnız Odak/Rahatsız Etme'yi aşabilir; **telefonun sessiz anahtarı/sesi kapalıysa ses çalmaz**.
- **Android**: ses, kullanıcının o **kanal** için seçtiği önem/ses ayarına bağlıdır; Rahatsız Etme veya kanal sessize alınmışsa çalmaz. Kanal uygulamada oluşturulmadıysa (bölüm 6.5a) alarm normal bildirim gibi davranır.
- TTL 2 dk: cihaz çevrimdışıysa geç gelen "5 dk sonra başlıyor" bildirimi düşürülür (iOS için `apns-expiration`).
- Sonuç: alarm, **dikkat çekme** amaçlıdır; sahne akışı için yedek olarak anons/zil kullanılmalıdır. Sessiz modda ses **garanti edilmez**.

## 9. Gizlilik / KVKK
- Görüntülenme sayaçları toplu sayıdır: IP, UA, çerez, oturum kimliği **saklanmaz**; tarayıcı `sessionStorage` bayrağı yalnız aynı oturumda tekrarı önler; DNT/GPC'ye uyulur.
  Not: Cloud Functions/Cloud Logging altyapısı HTTP isteklerini (IP dahil) kendi günlüklerinde tutabilir; uygulama kodu bunları yazmaz. Aydınlatma metninde belirtilmesi önerilir.
- `User.fcmToken` cihaz tanımlayıcısıdır (kişisel veri sayılır); yalnız bildirim gönderimi için kullanılır, `NotificationLog`'a **yazılmaz**. Günlük, gönderen yönetici kimliği/adı + hedef + sayıları içerir, alıcı listesi içermez.
- `Notification` belgeleri alıcıya aittir (kullanıcı silebilir); hesap silinince ilgili belgelerin silinmesi mevcut hesap silme akışına bağlıdır (bu işte değiştirilmedi).
- Hedefleme yalnızca yönetici panelinden, sunucuda rol denetimiyle yapılır; istemci başkası adına bildirim yazamaz (kural testi var).

## 10. Testler
`npm --prefix functions run test:emulator` (Firestore + Auth + Functions emülatörleri; Java gerekli). FCM **hiç çağrılmaz**: testlerde `messaging` enjekte edilen sahtedir.
Yeni dosyalar: `cancel-counter.test.js`, `stats.test.js`, `notify.test.js` (+ `rules.test.js`, `callable.test.js` eklemeleri).
