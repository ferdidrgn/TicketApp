# Sahibin yapacakları — tek sayfa kontrol listesi

Güncelleme: 28.10.2026. Sıra önemlidir. Kod tarafı hazır (dal `tiyatrol-web-perde`, `main` = 1.0.8+27). Aşağıdakiler yalnız SENİN yetkinle yapılabilir.
PowerShell komutlarını repo klasöründe çalıştır: `cd "C:\Users\ferdi\OneDrive\Belgeler\GitHub\TicketApp"`

## 0. Neden bu liste kritik
Canlıda (production) **Cloud Functions henüz yok** (kontrol: `holdSeats`, `confirmReservation` adresleri 404 veriyor). Bilet alma, rezervasyon, bildirim, hesap silme, ekip yöneticisi, telefon doğrulama kapısı bu fonksiyonlara bağlı. Web'de bu özelliklerin arayüzü artık yayında; fonksiyonlar çıkana kadar bu düğmeler hata verir (etkinlikler kapalıyken kullanıcı etkisi düşük).

## 1. Firebase Console (5 dakika)
1. **Billing → Blaze planı** ve **Budgets**: tutarı TL karşılığıyla ~5 USD yap, e-posta uyarıları açık, "spend cap/enforced" işaretleme.
2. **Authentication → Sign-in method:** Google ve Phone **Enabled**. Anonymous kapalı kalsın (kodda kullanılmıyor).
3. **Authentication → Settings → Authorized domains:** `tiyatrol.web.app` ve `tiyatroekip.web.app` ekle (yoksa web'de Google/telefon girişi çalışmaz).
4. **Authentication → Settings → SMS region policy:** yalnız Türkiye. **Phone numbers for testing** listesi boş.
5. **Project settings → Your apps → Android:** SHA-1 ve SHA-256 parmak izleri: Play Console → Setup → App signing'deki "App signing key certificate" + "Upload key certificate" (telefon doğrulaması buna bağlı).
6. **Project settings → General → Public-facing name:** `TiyatRol`.
7. **Storage → Rules:** mevcut kuralı kontrol et (test modunda ise herkes yazabilir). Depodaki güvenli `storage.rules` bölüm 5'te yayınlanır.
8. **Google hesabında 2 adımlı doğrulama** (en önemli savunma), GitHub'da 2FA ve depoyu gizli yap.

## 2. Gizli değerler (secret) — tek seferlik
Sırasıyla (her komutta değeri istendiğinde yapıştır):
```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```
```powershell
firebase functions:secrets:set PHONE_HASH_SALT --project ticketappflutter
```
Üretilen 32 karakteri yapıştır. **Bu değeri bir yere yedekle ve sonradan DEĞİŞTİRME** (değişirse ücretsiz bilet sayaçları sıfırlanır).
```powershell
firebase functions:secrets:set IYZICO_API_KEY --project ticketappflutter
```
```powershell
firebase functions:secrets:set IYZICO_SECRET_KEY --project ticketappflutter
```
İkisine de değer olarak `yok` yaz (ödeme şu an kapalı, rezervasyon modu).

## 3. Fonksiyonları deploy et
```powershell
gh workflow run "Deploy Backend" --ref main -f target=functions
```
GitHub → Actions → "Deploy Backend" çalışmasını izle. Hata verirse log'u bana ilet (servis hesabı rolü eksik olabilir: docs/DEPLOY-SIRASI.md §rol listesi).
Doğrulama: `holdSeats` adresi 404 yerine başka bir cevap vermeli (benden kontrol etmemi iste).

## 4. Android paketini Play'e yükle (SON TARİH: 1 Kasım 2026)
1. GitHub → Actions → **Deploy Android** (en son başarılı çalışma, sürüm 1.0.8+27) → **Artifacts → `app-release-bundle`** indir.
2. Play Console → Üretim (veya önce iç test) → yeni sürüm → `.aab` yükle. Hedef SDK 36 olmalı.
3. Otomatik yükleme için: Google Cloud'da **Google Play Android Developer API**'yi etkinleştir:
   `https://console.developers.google.com/apis/api/androidpublisher.googleapis.com/overview?project=823869540671`
4. **Önemli:** mobil sürümü fonksiyonlar (bölüm 3) çıktıktan SONRA yayına al; yoksa yeni sürüm bilet alamaz.

## 5. Kurallar (EN SON)
Mobil sürüm yayında ve çalışıyorsa:
```powershell
gh workflow run "Deploy Backend" --ref main -f target=rules-and-indexes
```
Kuralları fonksiyonlardan/mobilden ÖNCE yayınlarsan eski mobil sürüm bozulur. Bu adım Storage kurallarını da yayınlar: sonrasında profil fotoğrafı ve yönetim görseli yüklemeyi dene.


## 5b. Kurallar öncesi ek koşullar (önemli)
Kurallar (bölüm 5) yayınlandığında aşağıdakiler HAZIR olmalı, yoksa ilgili kullanıcılar bozulur:
- **Güncel web** yayında olmalı (yorum okuyan sorgular `hidden == false` şartıyla çalışır; eski web kodu yorum okuyamaz). Yani `main`'e son birleştirme yapılmış ve Deploy Web başarılı olmalı.
- **Yeni mobil sürüm** Play'de yayında olmalı: eski sürümler yorum okuyamaz/yazamaz, doğrudan kullanıcı belgesi silemez, bildirim tercihi ve token yazımı eski biçimde reddedilir.
- Fonksiyonlar (bölüm 3) deploy edilmiş olmalı.

## 5c. Verilecek karar: toplam bilet limitleri
Şu an etkinlik başına 3 bilet limiti (telefon bazlı) var. Ayrıca iki TOPLAM limit açık: ücretsiz etkinliklerde toplam 3 ve toplam 3 rezervasyon. "Etkinlik boyunca 3" istiyorsan toplamları kapat: `Config/satis` belgesine `ucretsizToplamLimit: 0` ve `rezervasyonLimit: 0` yaz (deploy gerekmez, kurallar yayınlandıktan sonra, yönetim paneli ya da Console'dan).

## 6. Canlı duman testi (30 dakika, kendin yap)
1. Telefonla giriş (gerçek SMS) → web ve mobil.
2. Aynı numarayı ikinci hesaba bağlamayı dene → reddedilmeli.
3. Ücretsiz etkinlikte 3 bilet al, 4.'yü dene → limit uyarısı.
4. Biletlerim'de alış tarihi/saati görünüyor mu.
5. Hesap silme: gelecek biletliyken → reddedilmeli; biletsizken → "30 gün sonra" + vazgeçme.
6. `/ekip`: yönetici ata (admin panelinde Ekip yöneticileri), mesaj gönder.
7. Admin panelinde Sahne kumandası'ndan bir test bildirimi (kendi cihazına).
8. Ayarlarda bildirim tercihleri ve "Sessizdeyken de sesli hatırlat".

## 7. İçerik / veri
- **Koltuk planı:** gerçek salon düzenini öğren (kapasite resmi sayfada 313, diğer kaynaklarda 331); sonra `https://tiyatrol.web.app/yonetim/koltuk-plani` sayfasından yaz.
- **Ekip (Topluluk) alanı:** her oyunun "Topluluk" alanı dolu olmalı (ekip yöneticisi bunu kullanır).
- **Yer tutucular:** yasal sayfalardaki `[Ad Soyad / Şirket Unvanı]`, adres, WhatsApp numarası (`905XXXXXXXXX`).
- **Gürkan Candan alıntıları:** yönetim → Oyuncular → Gürkan Candan → "Sözü" (çok satırlı).
- **Bağış/gönüllü linkleri:** yönetim → Topluluklar → ilgili ekip.
- **Test hesabı:** Firebase Auth'tan `bora@example.com` kullanıcısını sil.

## 8. Hukuk / mağaza (avukat)
- Gizlilik metnine: telefon doğrulama, hesap silme (30 gün + anonimleşen mali kayıt), bildirim tercihi, öneri (profilleme), yorum/moderasyon. Taslaklar: docs/TELEFON-DOGRULAMA.md §10, docs/HESAP-SILME.md §7, docs/ONERI.md, docs/UGC-KURALLARI.md.
- Play: Data Safety + kullanıcı içeriği (şikâyet/engelleme) beyanı; Apple: App Privacy ve inceleme notu.
- 5651 yer sağlayıcı yükümlülükleri ve KVKK (avukat).

## 9. İsteğe bağlı
- **App Check:** reCAPTCHA v3 anahtarı üret → `site/js/firebase.js` içindeki `APPCHECK_SITE_KEY`'e yazdır (bana söyle), sonra kademeli zorla (docs/GUVENLIK-DENETIMI.md).
- **Telegram uyarıları:** BotFather ile bot aç, repo secret'ları `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (docs/OTOMASYON.md). Servis hesabına **Cloud Datastore Viewer** rolü.
- **Eski mobil sürümler** için zorunlu güncelleme kararı.
