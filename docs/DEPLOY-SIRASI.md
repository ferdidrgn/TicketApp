# Canlıya alma sırası (tek sayfa) — sahibi için

Durum: 28.10.2026. Proje: `ticketappflutter`. Backend GitHub Actions ile deploy edilir (`Actions > Deploy Backend`). **Sıra bozulursa satın alma/giriş kırılır; sırayı değiştirmeyin.**

## 0. Önkoşullar (bir kez; hiçbiri kodla yapılamaz)

- [ ] Firebase **Blaze** planı (Functions + Scheduler + Secret Manager için şart).
- [ ] Authentication > Sign-in method: **Phone** AÇIK. (Test için: aynı sayfada "Phone numbers for testing" ile sahte numara/kod tanımlanabilir; gerçek SMS gitmez.)
- [ ] Authentication > Settings > **Authorized domains**: `tiyatrol.web.app`, `tiyatrol.firebaseapp.com` (+ varsa özel alan adı) ekli.
- [ ] Project settings > Android uygulaması > **SHA-1 ve SHA-256 parmak izleri** ekli (yayın anahtarı + Play App Signing anahtarı). Eksikse Android'de SMS/reCAPTCHA doğrulaması başarısız olur. iOS için APNs anahtarı yüklü.
- [ ] GitHub > Settings > Secrets > Actions: `FIREBASE_SERVICE_ACCOUNT` (servis hesabı JSON). Servis hesabı rolleri: Cloud Functions Admin, Service Account User, Cloud Build Editor, Artifact Registry Administrator, Cloud Scheduler Admin, Secret Manager Admin, Service Usage Admin, Firebase Rules Admin, Cloud Datastore Index Admin.
- [ ] Google Cloud > APIs: Cloud Functions, Cloud Build, Artifact Registry, Cloud Run, Eventarc, Pub/Sub, **Cloud Scheduler**, Secret Manager, Firebase Rules etkin. (Workflow bunları kendisi açmayı dener; servis hesabında "Service Usage Admin" yoksa uyarı verir ve elle açmanız gerekir.)

## 1. Sırları Secret Manager'a gir (bir kez; Git Bash / terminal)

```bash
firebase login
# Telefon limit tuzu: rastgele, >=16 karakter. SONRADAN DEĞİŞTİRMEYİN (tüm telefon sayaçları sıfırlanır) ve kimseyle paylaşmayın.
openssl rand -hex 32 | firebase functions:secrets:set PHONE_HASH_SALT --data-file - --project ticketappflutter
# iyzico (sandbox ya da canlı anahtarlar):
firebase functions:secrets:set IYZICO_API_KEY    --project ticketappflutter
firebase functions:secrets:set IYZICO_SECRET_KEY --project ticketappflutter
```

Doğrulama: `firebase functions:secrets:get PHONE_HASH_SALT --project ticketappflutter` (değeri göstermez, sürümü gösterir). Workflow, üç sır da yoksa deploy'a hiç başlamadan **kırmızı hata** verir.

## 2. Functions'ı deploy et — GitHub > Actions > **Deploy Backend** > Run workflow > `functions`

İlk deploy'da Cloud Scheduler işleri (`expireHolds`, `eventReminders`, `processAccountDeletions`) otomatik oluşur (3-8 dk sürebilir). `SITE_URL` varsayılanı `https://tiyatrol.web.app`'tir (iyzico dönüşü).
Bu adım rules'u DEĞİŞTİRMEZ: eski mobil/web çalışmaya devam eder.

## 3. Web + mobil yayını

- Web: `main`'e `site/**` değişikliği girince `Deploy Web` kendiliğinden yayınlar (ya da elle çalıştırın).
- Mobil: sürümü (hesap silme + telefon doğrulama içeren) mağazalara yayınlayın; **kullanıcıların çoğu güncelleyene kadar bekleyin** (eski sürüm hesabı doğrudan sildirmeye çalışır; rules bunu reddeder).

## 4. EN SON: Actions > **Deploy Backend** > `rules-and-indexes`

Bu, Firestore kurallarını ve dizinlerini yayınlar. Sonrasında: istemci `Event.seats`/`Ticket`/`Order` yazamaz, `User` belgesi istemciden silinemez, `User.deletion*`/telefon alanlarını yalnız sunucu yazar. Fonksiyonlardan ÖNCE yayınlanırsa satın alma ve hesap silme çalışmaz.

## 5. Canlı duman testi (gerçek cihazla, bir test hesabıyla)

1. [ ] **Telefonla giriş** (web ve mobil): SMS kodu gelir, giriş olur; Firestore `User/{uid}` belgesinde `isPhoneActive: true`, `phoneKey: ph_...` (düz numara yalnız `phoneNumber` alanında).
2. [ ] **Aynı numarayı ikinci hesaba bağlama reddi**: e-posta/Google ile ikinci hesap aç, aynı telefonu bağlamayı dene -> "bu numara başka hesapta" hatası.
3. [ ] **Ücretsiz bilet 3 sınırı**: ücretsiz etkinlikte 3 bilet al, 4.'yü dene -> "en fazla 3 bilet" mesajı. (Panel > Biletler & Kapı > Sistem sağlığı sayıları artar.)
4. [ ] **Rezervasyon**: ücretli etkinlikte koltuk tut -> rezervasyonu onayla -> bilet "Biletlerim"de; iptal süresi içinde iptal et, koltuk yeniden açılır.
5. [ ] **Hesap silme — gelecek biletle RED**: gelecek bileti olan hesapta Ayarlar > Hesabımı sil -> "Gelecek etkinlik biletiniz var..." (tarih/oyun adıyla); hesap silinmedi.
6. [ ] **Hesap silme — biletsiz hesap**: biletleri iptal et (ya da biletsiz test hesabı) -> Hesabımı sil -> "30 gün sonra silinecek", oturum kapanır. Tekrar giriş: üstte **"Silinmek üzere"** şeridi; bilet almayı dene -> "Hesabınız silinmek üzere..." ; **Silmeyi iptal et** -> şerit kaybolur, bilet alma yeniden açık.
7. [ ] **Hızlandırılmış GERÇEK silme** (yalnız bir TEST hesabıyla!): 6'daki gibi tekrar silme iste. Firebase Console > Firestore > `AccountDeletion/{uid}` > `scheduledAt` alanını **dünün tarihi** yap. Panel (`/yonetim` > Biletler & Kapı) > Sistem sağlığı > "Hesap silme" > **Silme işlerini şimdi çalıştır** (onayla). Beklenen: toast "Silinen 1"; Authentication'dan kullanıcı gitti; `User/{uid}` yok; Storage `ppics/{uid}.jpg` (profil fotoğrafı) yok; bu kullanıcının `Ticket`/`Order` belgeleri duruyor ama `customerId`/`userId` = `deleted-...`; `Notification`/`Review` yok; `UserLimits/ph_...` sayacı duruyor.
8. [ ] **Aynı telefonla yeniden kayıt**: silinen numarayla yeni hesap aç -> giriş olur; ücretsiz bilet sayacı kaldığı yerden devam eder (sıfırlanmaz).
9. [ ] **Bildirim**: panelden kendi hesabına test bildirimi gönder; uygulamada gelir. Seans hatırlatması (`eventReminders`) ve `expireHolds` için Sistem sağlığında "Son süre dolumu" birkaç dakikadan eski görünmemeli (kırmızı uyarı yok).
10. [ ] Sistem sağlığı kartında kırmızı uyarı yok; "Hesap silme" kutusunda `Hatalı = 0`, `Vadesi geçmiş = 0`.

## 6. Sorun çıkarsa

| Belirti | Neden / çözüm |
|---|---|
| Workflow "Secret Manager'da 'X' yok" | Adım 1'i (X için) çalıştırın; sonra workflow'u yeniden çalıştırın. |
| `Permission denied` / `API has not been used` | Servis hesabı rolü ya da API eksik (Adım 0). API'yi Cloud Console'dan etkinleştirin, birkaç dk bekleyip yeniden çalıştırın. Deploy tekrarlanabilir (idempotent). |
| Scheduler işi oluşmadı | Cloud Scheduler + Pub/Sub API'leri etkin mi, Blaze mi? Console > Cloud Scheduler'da `firebase-schedule-processAccountDeletions-europe-west1` görünmeli. Görünmüyorsa functions deploy'unu yeniden çalıştırın. Geçici çare: panelden "Silme işlerini şimdi çalıştır". |
| Satın alma "Bilet satışı şu anda kullanılamıyor" (`SALT_MISSING`) | `PHONE_HASH_SALT` yok/16 karakterden kısa ya da fonksiyona bağlanmamış. Adım 1 + functions deploy. |
| Kurallar sonrası uygulama hata veriyor | Eski mobil sürüm. Geri alma: Console > Firestore > Rules > **Geçmiş** > önceki sürüm > Yayınla (ya da önceki commit'ten `rules-and-indexes` çalıştırın). Fonksiyonlar geriye uyumludur, geri almak gerekmez. |
| Functions'ta hata | Önceki commit'i Actions'ta "Use workflow from" ile seçip `functions` yeniden deploy edin. |
| Yanlışlıkla silinen hesap | 30 gün dolmadıysa kullanıcı girip "Silmeyi iptal et" der. `deleting`/silinmiş hesap geri getirilemez (kasıtlı). |

**Asla yapmayın:** `PHONE_HASH_SALT`'ı değiştirmek/silmek; canlıda gerçek müşteri hesabıyla "hızlandırılmış silme" denemek; rules'u functions'tan önce yayınlamak.
