# Hesap silme (30 gün bekleme süreli) — istemci sözleşmesi ve işletim notları

Durum: 28.10.2026. Backend: `functions/src/accountDeletion.js`, callable'lar `functions/index.js`, testler `functions/test/account-deletion.test.js`.
Mobil (`lib/`) ve web (`site/`) istemcileri BU sözleşmeye göre yazılır. **Deploy edilmeden çalışmaz** (bkz. §9).

## 1. Sahibin kuralları

1. Kullanıcının zamanı GELMEMİŞ (etkinlik tarihi şu andan sonra) aktif bileti/rezervasyonu varsa silme isteği **reddedilir**.
2. Yoksa hesap hemen silinmez: **30 gün sonra silinecek** olarak işaretlenir. Kullanıcı 30 gün içinde giriş yapıp vazgeçebilir.
3. 30. gün dolunca hesap **sunucuda zamanlanmış fonksiyonla** otomatik silinir (`processAccountDeletions`, günde 1).
4. Misafir (anonim) hesap: bilet/veri yok -> bekleme yok, hemen silinir.

## 2. Callable'lar (europe-west1, giriş gerekli)

Hepsi `httpsCallable` / `functions.httpsCallable` ile çağrılır; veri `{}` (parametre yok). Hata: `HttpsError` (`code`, `message`, `details`).

### 2.1 `requestAccountDeletion()`

| Durum | Sonuç |
|---|---|
| Gelecek tarihli aktif bilet var | `failed-precondition`, `message` = `UPCOMING_TICKETS`, `details` = `{ code:'UPCOMING_TICKETS', count, nextEventDate? (ISO, UTC; tarihi bilinmeyen bilet yüzünden reddedilmişse YOK), nextEventTitle? }`. **Hiçbir veri değişmez.** |
| Bilet yok, normal hesap | `{ status:'pending', scheduledAt:<ISO>, requestedAt:<ISO>, already:false }` |
| Zaten pending (tekrar çağrı) | `{ status:'pending', scheduledAt:<aynı ISO>, requestedAt, already:true }` — süre UZAMAZ (idempotent) |
| Anonim (misafir) hesap | `{ status:'deleted' }` — Auth kullanıcısı ve User belgesi silindi; istemci oturumu yerel olarak kapatmalı |
| Silme işleniyor (`deleting`) | `failed-precondition`, `details.code = 'DELETION_IN_PROGRESS'` |

`message` alanı ham kod olarak (`UPCOMING_TICKETS`) gelir (PHONE_REQUIRED ile aynı desen); **gösterilecek metni istemci üretir** (§5). `nextEventDate` yerel biçimlendirme için ISO verilir (Europe/Istanbul gösterin).

Başarılı `pending` sonrası sunucu: `AccountDeletion/{uid}` ve `User/{uid}.deletion*` alanlarını yazar, kullanıcının **askıdaki koltuk tutmalarını (held sipariş) serbest bırakır** ve **tüm refresh token'ları iptal eder** (`revokeRefreshTokens`; diğer cihazlar bir süre sonra çıkış yapar). Mevcut ID token ~1 saat geçerli kalır; **istemci bu çağrıdan hemen sonra kendi oturumunu kapatmalı (`signOut`)** ve "Hesabınız … tarihinde silinecek" ekranını göstermelidir. Kullanıcı tekrar giriş yapabilir (hesap devre dışı BIRAKILMAZ) ve vazgeçebilir.

Aktif koltuk tutma kararı: tutmalar (held) **sayılmaz, serbest bırakılır**. Ödeme sürecinde (`paying`) sipariş varsa isteği engellemez; sipariş bilete dönüşürse zamanlanmış fonksiyon silme anında yeniden kontrol eder (§4).

### 2.2 `cancelAccountDeletion()`

Vazgeçme. `{ status:'active', wasPending:boolean }`. Pending değilse (kayıt yok) da `{status:'active', wasPending:false}` (idempotent). Bekleme süresi dolmuş ama henüz işlenmemişse de iptal edilebilir. İşlem başlamışsa (`deleting`) `failed-precondition` + `details.code='DELETION_IN_PROGRESS'`. Başarıda `User.deletion*` alanları silinir, `AccountDeletion/{uid}` kaldırılır. Vazgeçen kullanıcının token'ları zaten iptal edilmiş olabilir: istemci vazgeçmeden önce YENİDEN giriş yapmış olmalıdır (giriş = zaten yeni token).

### 2.3 `getAccountDeletionStatus()`

`{ status:'active' }` | `{ status:'pending', scheduledAt:<ISO>, requestedAt:<ISO> }` | `{ status:'deleting', scheduledAt }`. Sunucu otoritesidir (User alanları yedek aynadır).

**Başlangıç okuması (önerilen, kolay):** giriş sonrası istemci `User/{uid}` belgesini zaten okuyor; orada
`deletionStatus` (`'pending'` ya da alan yok) ve `deletionScheduledAt` (Firestore `Timestamp`), `deletionRequestedAt` (`Timestamp`) bulunur.
`deletionStatus == 'pending'` ise giriş ekranı yerine "hesap silinmek üzere" ekranı (vazgeç / çıkış) gösterilir. Belge yoksa/alan yoksa `getAccountDeletionStatus()` çağrılabilir. İstemci bu alanları **yazamaz** (rules).

### 2.4 Yönetici

- `adminProcessAccountDeletions()` — yalnız `User.role == 'admin'`; zamanlayıcı yoksa/arızalıysa elle tetikler. Yanıt: `{ processed, deleted, postponed, failed, scanned, remainingDue }`.
- `adminHealth()` yanıtına eklenen `accountDeletion` alanı (admin paneli gösterir): `{ pending, deleting, overdue, lastRunAt (ms|null), ageMinutes, processed, deleted, postponed, failed, failing, stale }`. `overdue` = vadesi geçmiş ama işlenmemiş kayıt; `failing` = 3+ denemede hata veren kayıt (`errorCount >= 3`; `lastError` kodu `AccountDeletion/{uid}` içinde, admin okur).

## 3. Satış callable'ları ve bekleme süresi

`holdSeats`, `confirmFree`, `confirmReservation`, `startPayment`: kullanıcı `pending`/`deleting` ise
`failed-precondition`, `message = 'ACCOUNT_DELETION_PENDING'`, `details = { code:'ACCOUNT_DELETION_PENDING', scheduledAt:<ISO> }`.
İstemci: "Hesabınız silinmek üzere işaretli. Bilet alabilmek için önce silme talebinizi iptal edin." + iptal butonu.
`cancelTicket` ve `releaseHold` **serbest** (kullanıcı biletini iptal edebilir).

**Kapı sırası** (bir çağrıda ilk eşleşen hata): giriş (`unauthenticated`) -> **`ACCOUNT_DELETION_PENDING`** -> `PHONE_REQUIRED` -> `SALT_MISSING` -> diğer iş kuralları. Gerekçe: silinmek üzere işaretli kullanıcıya önce telefon doğrulatmak anlamsız.

## 4. Akış (metin diyagramı)

```
requestAccountDeletion
  |- anonim hesap?  -> (gelecek bilet yoksa) veriyi sil + Auth sil -> {status:'deleted'}
  |- gelecek tarihli aktif bilet?  -> UPCOMING_TICKETS (veri değişmez)
  |- AccountDeletion/{uid}=pending, User.deletion* yaz, held tutmaları bırak, tokenları iptal et
  '-> {status:'pending', scheduledAt = şimdi + 30 gün}

(30 gün boyunca)  kullanıcı giriş yapar -> status oku -> cancelAccountDeletion -> {status:'active'}
                  satış callable'ları ACCOUNT_DELETION_PENDING; cancelTicket serbest

processAccountDeletions (her gün 03:00 Europe/Istanbul)  scheduledAt <= şimdi olan kayıtlar, yığınlı:
  1. pending -> deleting (atomik kilit)
  2. gelecek bilet TEKRAR kontrol:
        var -> ERTELE: scheduledAt = son etkinlik tarihi + 1 gün, status 'pending', kullanıcıya Notification (type 'accountDeletion')
  3. SIRA (her adım idempotent; hata olursa sonrakiler çalışmaz, User/Auth en sonda olduğundan kayıt kurtarılabilir kalır):
       a. Storage: ppics/{uid}.* ve ppics/{uid}/* (ön ek; jpg/png/webp/alt klasör)       [hata -> Firestore'a HİÇ dokunulmaz]
       b. Eski biçim Event.seats[*].customerId == uid alanını sil (yalnız kullanıcının bilet/siparişindeki etkinlikler)
       c. Ticket / Order anonimleştir (customerId/userId -> deleted-<hash>, phoneKey ve eski kişisel alanlar silinir; belge KALIR)
       d. NotificationLog.sentBy == uid (yönetici ise) anonimleştir
       e. Notification, Review, ReviewReport, UserLimits/{uid} (aynası) sil
       f. Auth kullanıcısını sil (user-not-found = başarı)      g. User/{uid} sil
       h. AccountDeletion/{uid} -> {status:'deleted', deletedAt}  (kişisel alan yok; UserLimits/ph_* sayacı KASITLI kalır)
  her adım idempotent; hata -> kayıt 'pending'e döner (attempts++), ertesi gün yeniden denenir
```

## 5. Mesaj önerileri (Türkçe)

- Reddedildi (`UPCOMING_TICKETS`): `Gelecek etkinlik biletiniz var: {count} bilet, en yakını {nextEventTitle} — {gg.aa.yyyy ss:dd}. Hesabınızı silebilmek için etkinlikten sonra tekrar deneyin ya da biletlerinizi iptal edin.` (Online ödenmiş biletler uygulamadan iptal edilemez: "İptal için bizimle iletişime geçin.")
- Onay penceresi: `Hesabınız 30 gün sonra silinecek. Bu süre içinde giriş yapıp vazgeçebilirsiniz. Süre dolunca hesabınız ve kişisel verileriniz kalıcı olarak silinir; bilet kayıtları yasal saklama gereği kişisel bilgiler olmadan tutulur.`
- Başarı: `Hesabınız {gg.aa.yyyy} tarihinde silinecek; bu süre içinde giriş yapıp vazgeçebilirsiniz.`
- Giriş sonrası banner (pending): `Hesabınız {tarih} tarihinde silinecek. Vazgeç` 
- Satış engeli (`ACCOUNT_DELETION_PENDING`): `Hesabınız silinmek üzere işaretli. Bilet alabilmek için önce silme talebinizi iptal edin.`
- Vazgeç başarılı: `Silme talebiniz iptal edildi. Hesabınız aktif.`
- Silme işleniyor (`DELETION_IN_PROGRESS`): `Hesabınızın silinme işlemi başladı, artık vazgeçilemez.`
- Anında silinen misafir: `Misafir hesabınız silindi.`

## 6. Saklama / anonimleştirme tablosu

| Veri | Silme anında | Neden |
|---|---|---|
| Firebase Auth kullanıcısı | **Silinir** | Kimlik |
| `User/{uid}` (ad, e-posta, telefon, favoriler, fcmToken, görsel adı) | **Silinir** | Kişisel veri |
| `Notification` (userId==uid) | **Silinir** | Kişisel |
| `Review`, `ReviewReport` (userId==uid) | **Silinir** | Kamuya açık ad/fotoğraf içerir |
| Storage `ppics/{uid}.*` (jpg/png/alt klasör) | **Silinir** (ön ek ile) | Profil görseli (istemci yolu `ppics/{uid}.jpg`) |
| `Event.seats[*].customerId` (eski biçim kalıntı) | Alan silinir | Yeni biçimde zaten tutulmaz |
| `NotificationLog.sentBy/sentByName` (yöneticiyse) | Anonimleşir | Ad |
| `UserLimits/{uid}` (uid aynası) | **Silinir** | Uid'e bağlı |
| `UserLimits/ph_*` (telefon HASH sayacı) | **KALIR** (KASITLI) | Aynı numarayla yeniden kayıtta ücretsiz bilet/rezervasyon hakkı sıfırlanmasın (docs/ODEME-GUVENLIK.md §15). Düz numara değil, tuzlu hash; yalnızca sayaç |
| `Ticket` | **KALIR, anonimleşir**: `customerId` -> `deleted-<hash>` | Mali/yasal saklama; koltuk, tutar, tarih, durum, oyun adı kalır, istatistik bozulmaz |
| `Order` | **KALIR, anonimleşir**: `userId` -> `deleted-<hash>`, `phoneKey` kaldırılır | Aynı; `paymentId`/tutar iade ve muhasebe için kalır |
| `AccountDeletion/{uid}` | `{status:'deleted', deletedAt}` (belge kimliği = silinmiş uid; Auth'ta karşılığı yok) | İşlem günlüğü; **düz telefon/e-posta yok**, phoneKey silinir |

`deleted-<hash>` = `'deleted-' + sha256('acctdel:' + uid)` ilk 16 hex. Aynı kullanıcının kayıtları birbirine bağlı kalır, kişiye bağlanamaz.

## 7. Gizlilik metni taslağı

> **Hesabın silinmesi.** Hesabınızı uygulamadan silme talebinde bulunabilirsiniz. Gelecek tarihli biletiniz yoksa hesabınız 30 gün sonra silinmek üzere işaretlenir; bu sürede giriş yaparak vazgeçebilirsiniz. Süre dolunca hesabınız, profil bilgileriniz (ad, e-posta, telefon, favoriler, profil fotoğrafı), bildirimleriniz ve yorumlarınız kalıcı olarak silinir. Vergi ve ticaret mevzuatındaki saklama yükümlülükleri gereği bilet ve sipariş kayıtları (koltuk, tutar, tarih) kimliğinizle ilişkilendirilemeyecek şekilde anonimleştirilerek saklanır. Kötüye kullanımı önlemek için telefon numaranızdan geri döndürülemez biçimde türetilmiş bir kod ve bununla ilişkili ücretsiz bilet/rezervasyon sayaçları saklanmaya devam eder.

(Hukuki danışmanla gözden geçirilmeli; metin yasal tavsiye değildir.)

## 8. Zamanlayıcı kurulumu

`processAccountDeletions`: `onSchedule('0 3 * * *', timeZone 'Europe/Istanbul')`. Cloud Scheduler gerektirir -> **Blaze planı** (functions deploy zaten Blaze ister; `expireHolds`/`eventReminders` ile aynı). İlk deploy'da Scheduler işi otomatik oluşur. Zamanlayıcı çalışmazsa admin panelinden `adminProcessAccountDeletions` elle çalıştırılır; `adminHealth.accountDeletion.stale` uyarır (>36 saat çalışmamış ve vadesi geçmiş kayıt varsa). Heartbeat: `System/processAccountDeletions` `{ lastRunAt, processed, deleted, postponed, failed }`. Bir çalışmada en çok 100 kullanıcı / 7 dakika işlenir (kalanı ertesi gün; `adminProcessAccountDeletions` ile elle devam edilir).
Yeni Firestore index'i GEREKMEZ (tek alanlı `scheduledAt` / `status` sorguları).

## 9. Deploy sırası ve riskler

- `firestore.rules` yeni alanları korur ve `User` belge **silmesini** istemciden kapatır (silme artık yalnız sunucuda): eski mobil sürüm `deleteUser` ile doğrudan belge silerse reddedilir. Mobil bu sözleşmeye geçmeden rules'u deploy etmeyin. (Firebase Auth `user.delete()` istemci tarafında hâlâ teknik olarak mümkün: istemci doğrudan çağırmamalı; bilet kuralı yalnızca callable yolunda zorlanır.)
- Önce functions, sonra rules (ODEME-GUVENLIK ile aynı sıra).
- Risk: eski biçim `Event.seats[*].customerId` yalnızca kullanıcının bilet/siparişinde geçen etkinliklerde temizlenir; bilete dönüşmemiş, siparişsiz eski "reserved" koltuk kalıntıları bulunamaz.
- Risk: gerçek GCS'e karşı test EDİLMEDİ (yalnız Storage emülatörü); ilk deploy'da bir test hesabıyla uçtan uca deneyin (`getStorage().bucket()` varsayılan bucket).
- Karar (çapraz denetim, 28.10.2026): tarihi ayrıştırılamayan (ne `Event.date` ne bilet `eventDate`) AKTİF bilet **"gelecek" sayılır** (güvenli taraf: geçerli bilet sessizce anonimleşmesin). İstek reddedilir (`details.nextEventDate` YOKTUR, yalnız `count`; istemci tarih alanını opsiyonel okumalı); 30. günde ise silme 30 gün ertelenir (`lastPostponeReason: 'unparseable_ticket_date'`). Çözüm: yönetici `adminSetTicketStatus` ile bileti iptal/gelmedi yapar ya da Event tarihini düzeltir.
- Risk (kuralla ENGELLENEMEZ): Firebase Auth `user.delete()` istemciden çağrılırsa hesap bilet kuralı atlanarak silinir ve `User`/`Ticket` kalıntıları anonimleşmez (rules Auth'u kontrol edemez). Web ve mobil kodda hiçbir yerde çağrılmıyor (grep ile doğrulandı); yalnız elle/hatalı yeni kod bunu yapabilir -> kod incelemesinde yasak.
- Risk: sunucu saatine göre 30 gün; kullanıcı saat dilimi etkisi yok.

## 10. Hata / yarım kalma senaryoları (testle kanıtlı: functions/test/account-deletion.test.js)

Durum makinesi: `pending` -> (atomik kilit, `claimedAt` = 15 dk kira) `deleting` -> `deleted`. Hata olursa kayıt `deleting` KALIR (`errorCount++`, `lastError` = yalnız hata KODU; hata mesajı yazılmaz; kilit bırakılır) ve ertesi çalışma / elle tetikleme kaldığı yerden devam eder. `deleting` kasıtlı olarak iptal edilemez: yarım silinmiş hesap yeniden canlandırılmaz.

| Senaryo | Sonuç |
|---|---|
| Storage silme hatası | Firestore/Auth'a dokunulmaz; sonraki çalışmada tamamlanır |
| Bilet anonimleştirme 2. sayfada kesilir | İlk sayfa anonim kalır, kalanlar sonraki çalışmada; çift işlem/kayıp yok; User hâlâ duruyor |
| Auth silme hatası | User belgesi silinmemiştir; yeniden denenir |
| Auth zaten silinmiş | Başarı sayılır |
| İşleyici çöker (kilit kalır) | 15 dk sonra başka çalışma devralır |
| İki işleyici eşzamanlı | Biri siler, diğeri atlar |
| Bir kullanıcıda hata | Diğerleri işlenmeye devam eder |
| Gelecek bilet / ödemesi süren sipariş çıkmış | Silme ertelenir + bildirim |

Kanıtlanmayanlar: gerçek Cloud Scheduler tetiklemesi, gerçek GCS (yalnız Storage emülatörü denendi), üretim verisi.
