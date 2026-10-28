# Güvenlik denetimi ve saldırı simülasyonu (İŞ S-1, 28.10.2026)

Soru: "Biri Firebase'imize siber saldırı yapıp kendini admin yaparsa engelliyor muyuz, açık var mı?"

**Kısa cevap:** İstemciden (web/mobil/SDK/REST) kendini admin yapmanın bilinen bir yolu kalmadı; bunu `functions/test/redteam.test.js`
(23 test, gerçek `firestore.rules` + `storage.rules` + gerçek `functions/index.js`, emülatörde) kanıtlıyor. Yönetici = Firestore
`User/{uid}.role == 'admin'`; bu alan istemciden ne oluştururken ne güncellerken ne silerken yazılabilir (yalnız Admin SDK / Console).
Kalan gerçek risk **teknik değil hesap güvenliği**: yönetici Google/e-posta hesabı ele geçirilirse saldırgan yönetici olur → 2FA zorunlu.

Çalıştırma: `npm --prefix functions run test:emulator` (firestore, auth, functions, storage emülatörleri).

## Saldırı denemeleri ve sonuç (hepsi REDDEDİLİR — testte kanıt)

| Deneme | Sonuç | Test |
|---|---|---|
| Yeni User belgesini `role: admin/curator/Admin/dizi/map` ile oluşturma | Reddedildi | (a) create |
| Kendi belgesinde role'ü update / `set merge` / tam üzerine yazma / alanı silme / dizi-map yapma / nested `profile.role` | Reddedildi (nested alan zararsız: `isAdmin()` yalnız `role`'ü okur) | (a) update |
| `isPhoneActive:true`, `phoneVerifiedAt`, `phoneKey`, `deletion*`, sahte `phoneNumber`, bozuk `notifPrefs` | Reddedildi | (a) sunucu alanları |
| Başkasının User belgesini okuma/yazma/silme, `User` listeleme, `where role==admin` sorgusu (admin dahil istemciden liste yok) | Reddedildi | (b) |
| Ticket/Order/Event/Show/Team/Stage/Player/Campaign/Seats/AppTools/Config/Stats/System/NotificationLog/AccountDeletion/UserLimits yazma (set, merge, delete; giriş yapmış ve anonim) | Reddedildi | (c) |
| Başkasının bilet/sipariş/limit/yönetim verisini okuma, korumalı koleksiyonları listeleme (`limit(1)` dahil) | Reddedildi | (c), (j) |
| Admin bile bilet/sipariş uyduramaz, bilet sahibini değiştiremez | Reddedildi | (c) |
| Team'i ele geçirme (`managers/ownerId`), `TeamManager` yazma, User'a `managedTeams/isAdmin` alanı ekleme | Reddedildi / yetki vermez | (d) |
| `isAdmin()` hileleri: User belgesi yok / silinmiş / `role` eksik, null, `Admin`, dizi, map; sahte custom claim (`admin:true`); e-posta ile admin olma | Reddedildi. Admin belgesi silinince ya da role düşünce yetki ANINDA biter | (e) |
| Review/ReviewReport/Notification sahte, taklit, sınırsız, tür/boyut saldırıları | Reddedildi (aşağıda düzeltilen açıklar) | (f) |
| Tüm `admin*` callable'ları (taramayla `index.js`'ten bulunur): anonim → UNAUTHENTICATED; belgesiz/`user`/`Admin`/`curator` → PERMISSION_DENIED | Reddedildi. Yeni bir `admin*` export'u eklenip korunmazsa test OTOMATİK kırılır | (g) |
| Tüm callable'lara anonim çağrı; bozuk girdi (null, dizi, `$ne` nesnesi); hata gövdesinde stack/yol sızıntısı | UNAUTHENTICATED / 4xx, sızıntı yok | (g) |
| `trackView`: GET/PUT, bozuk JSON, dev id, `__proto__`/`User` türü, sahte origin, bot UA, uydurma Show, `X-Forwarded-For` döndürerek sayaç şişirme | Reddedildi / sessizce yok sayıldı / tavana takıldı | (h) |
| Storage: başkasının `ppics/` dosyası, anonim yazma, yanlış içerik türü (html, svg), >5 MB / >10 MB, tanımsız dizin, listeleme | Reddedildi (yalnız sahibi/admin) | (storage) |
| Kural dosyası taraması: yazma izninde `if true` yok; `if true` OKUMA yalnız 10 bilinen herkese açık yolda; son `/{document=**}` tümüyle kapalı; tek özyinelemeli allow `Stats` (okuma admin) | Geçti | (i) |

## Bulgu tablosu

| # | Bulgu | Şiddet | Durum | Kanıt |
|---|---|---|---|---|
| 1 | `Review` create/update: telefon doğrulaması/anonim sağlayıcı denetimi yok; alan beyaz listesi yok (istemci fazladan alan, ör. `verified`, `likes`, yazabilirdi); `userName/userImage` boyut/tür sınırı yok; zaman damgası istemciden; olmayan oyuna yorum | Orta | **Düzeltildi** (`phoneVerified()`, `keys().hasOnly`, tür/boyut, `createdAt/updatedAt == request.time`, `exists(Show)`, `hidden` yalnız `false`) | redteam (f) |
| 2 | `Notification` create: kullanıcı kendine sınırsız/sahte bildirim ("Ödeme alındı") yazabilirdi (depolama şişirme, kimlik taklidi). Mobil `createNotification` hiçbir yerden çağrılmıyor; sunucu Admin SDK ile yazar | Orta | **Düzeltildi** (create kapalı; `isRead` bool şartı) | redteam (f) |
| 3 | `ReviewReport`: belge kimliği/alan/boyut sınırı yok (spam, tek kullanıcı çok belge, keyfi alan) | Düşük | **Düzeltildi** (kimlik `${reviewId}_${uid}` = mobil biçim, alan listesi, `reason` ≤200, var olan yoruma, sunucu zamanı) | redteam (f) |
| 4 | `trackView` bellek içi hız sınırı: `getStats()` her istekte yeni `createStats()` yapıyordu (sınır durumu istek arası kayboluyordu); ayrıca `req.ip` (`X-Forwarded-For`) istemciden döndürülebilir → sayaç ve Firestore yazma maliyeti şişirilebilir | Orta (bütünlük + maliyet) | **Düzeltildi** (tek örnek; IP'den bağımsız hedef başına 120/dk ve instance başına 600/dk tavan) | redteam (h) |
| 5 | Repoda `storage.rules` yoktu, `firebase.json`'da storage yoktu → Console'daki kuralların ne olduğu belgesiz (açıksa herkes dosya yükleyip silebilir) | Yüksek (bilinmeyen) | **Dosya hazır, DEPLOY SAHİBİNDE** (aşağıda not) | redteam (storage) |
| 6 | App Check zorlanmıyor; web anahtarı yok | Orta | **Plan + kod hazır** (anahtar sahibinden; boşken devre dışı) | aşağıda |
| 7 | `User` belgesinde alan beyaz listesi ve boyut sınırı yok (kullanıcı kendi belgesini şişirebilir / rastgele alan ekleyebilir; yetki vermez) | Düşük | Kabul (mobil `UserModel` yükünü kırmamak için; yalnız kendi verisi) | redteam (d) |
| 8 | Herkese açık koleksiyonlar (`Show/Stage/Team/Player/Campaign/Event/Review`) sorgu `limit` zorunluluğu olmadan tamamen listelenebilir (okuma maliyeti taraması) | Düşük–Orta | **Kabul / kırıcı**: web `site/js/store.js` tüm koleksiyonları okur, mobil `isLimit=false` kullanır; `request.query.limit` şartı ikisini kırar. Azaltma: App Check zorlama, Console'dan bütçe uyarısı | redteam (j) kayıt testi |
| 9 | `Review.userName/userImage` istemci yazar; başka birinin adıyla yorum yazılabilir (taklit). Kural User belgesine bakamaz (başkası okunamaz, ucuz değil) | Düşük | Kabul; admin gizleyebilir. Geçiş önerisi: ad sunucuda (Cloud Function) yazılsın | — |
| 10 | `trackView` Origin/UA denetimi tarayıcı dışı istemcilerle taklit edilebilir | Düşük | Kabul; etkisi yalnız yönetim sayacı, tavanlarla sınırlı | redteam (h) |
| 11 | Hız sınırları instance başına (en çok `maxInstances` kat) | Düşük | Kabul | — |
| 12 | Yönetici hesabı ele geçirilirse tüm içerik/bilet işlemleri açılır (asıl kalan risk) | Yüksek | Sahibin yapacakları (2FA) | — |
| 13 | Callable'larda `maxInstances: 20`, `trackView` 5; tüm kullanıcı callable'ları `guarded` (giriş zorunlu, iç hata sızdırılmaz); tüm `admin*` `assertAdmin`; loglarda sır/PII yok (yalnız ad/kod) | — | Gözden geçirildi, değişiklik gerekmedi | redteam (g) |

Not (kural eşleşmesi): mobil `ReviewRepository.upsert/report` yükleri ve web/mobil gerçek yazım biçimleri testte birebir kullanıldı
(`serverTimestamp()` alanları dahil) — mevcut mobil yazım kırılmadı. Tek davranış değişikliği: **telefonu doğrulanmamış hesap yorum
yazamaz/güncelleyemez** (bilet alma zaten telefon ister; yorum "izleyen yazar" kuralıyla zaten bilet gerektirir).

## Storage (`storage.rules`)

İstemci yolları (kodda doğrulandı): `ppics/{uid}.jpg` (mobil profil), `PlayerImages|ShowImages|StageImages|TeamImages/{id}.jpg`
(mobil yönetim), `images/{koleksiyon}/{dosya}` (web yönetim paneli).
Kural: varsayılan KAPALI; `ppics/{uid}.*` yalnız sahibi yazar/siler (≤5 MB, raster `image/*`), `get` yalnız oturumlu; yönetim dizinleri yalnız
admin yazar (Firestore `User/{uid}.role == 'admin'`, çapraz servis), ≤10 MB, herkese `get`; listeleme hiçbir yerde yok; SVG/HTML yüklenemez.
Görseller token'lı indirme URL'siyle gösterildiği için (kurallardan bağımsız) mevcut gösterim etkilenmez.

**DEPLOY YAPILMADI.** Yayınlamadan önce (`firebase deploy --only storage`):
1. Console > Storage > Rules'taki MEVCUT kuralı kontrol edin (herkese açık yazma mı?). Karşılaştırın.
2. Dikkat: mobil `putFile` içerik türünü dosya uzantısından çıkarır (`image/jpeg`); gerçek cihazda bir profil fotoğrafı yükleyip doğrulayın.
3. Web yönetim paneli `images/…` yüklemesi admin hesabıyla deneyin. Eski görsel URL'leri (token'lı) çalışmaya devam eder.
4. `firebase.json`'a `storage.rules` eklendi: `firebase deploy` (tümü) artık Storage'ı da yayınlar — kasıtlı değilse `--only` kullanın.

## App Check — kademeli plan

* Mobil: `lib/core/services/app_check_service.dart` etkin (Play Integrity / DeviceCheck; debug derlemede debug sağlayıcı). iOS'ta App Attest'e geçiş önerilir.
* Web: `site/js/firebase.js` içinde `APPCHECK_SITE_KEY = ''`. Boşken hiçbir şey yüklenmez (hata yok). Sahibi reCAPTCHA v3 site anahtarını
  üretip buraya yazınca web App Check devreye girer. (Eski Flutter web anahtarı `app_check_service.dart` içinde var; yeni site için ayrı
  anahtar/alan adları önerilir: `tiyatrol.web.app`, `tiyatrol-web.web.app`.)
* Fonksiyonlar: `ENFORCE_APP_CHECK` parametresi (`functions/index.js`, varsayılan `false`); `true` iken `request.app` olmayan callable reddedilir.
  1. **İzleme (1–2 hafta):** Console > App Check > APIs > Cloud Firestore / Storage / Functions: metriklere bakın (doğrulanmış vs. doğrulanmamış istek oranı). ZORLAMA YOK.
  2. Mobil sürüm yaygınlaşınca (eski sürümler doğrulanmış istek göndermez) ve **web anahtarı eklenip yayınlandıktan SONRA** Firestore + Storage'ı zorlayın.
  3. En son `ENFORCE_APP_CHECK=true` (`firebase functions:params` / `.env`) ile callable'ları zorlayın. Web anahtarı yokken zorlamak siteyi bozar.
  4. Geri alma: Console'da zorlamayı kapatmak anında etkilidir.
* Geliştirme: Android/iOS debug derlemesi logcat/Xcode'da "debug token" yazar → Console > App Check > Apps > Manage debug tokens. Web: `localhost`'ta token konsola yazılır (kod otomatik açar). Debug token'ı repoya KOYMAYIN.
* Not: App Check `trackView` ve `iyzicoCallback` (HTTP, tarayıcı/iyzico) için uygulanmaz; onlar tavanlarla ve sunucu doğrulamasıyla korunur.

## Sahibin yapacakları

1. **Google hesabı 2FA** (Firebase projesinin sahibi/yöneticileri): güvenlik anahtarı/passkey öneri. Tüm Owner/Editor üyeleri gözden geçirin, gereksizleri kaldırın (IAM).
2. **GitHub:** 2FA, depoyu gizli (private) yapın, Settings > Secrets içindeki anahtarları (service account, token) döndürün; geçmişte sızmış olabilecek anahtarları iptal edin; branch koruması.
3. **API anahtarı kısıtlaması** (Google Cloud Console > APIs & Services > Credentials): Web anahtarı (`AIzaSyDTsz…`) için HTTP referrer (`tiyatrol.web.app/*`, `tiyatrol-web.web.app/*`, `*.firebaseapp.com/*`, yerel geliştirme için `localhost/*`); Android anahtarı için paket adı + SHA-1; iOS için bundle id. Kullanılmayan API'leri kısıtlayın.
4. **Firebase Auth ayarları:** e-posta numaralandırma koruması (Authentication > Settings > User actions) AÇIK; şifre politikası (min 8, büyük/küçük/rakam); SMS bölge politikası: yalnız **+90 (Türkiye)** izinli (SMS pumping/maliyet saldırısı); yetkili alan adları listesini yalnız gerçek alan adlarıyla sınırlayın; kullanılmayan oturum açma sağlayıcılarını kapatın; Identity Platform'da SMS/Auth kotası ve faturalama bütçe uyarısı.
5. **Console Storage kuralı kontrolü** + `storage.rules` yayını (yukarıdaki not).
6. **App Check:** reCAPTCHA v3 anahtarı üretip `APPCHECK_SITE_KEY`'e yazdırın; izleme → zorlama (yukarıdaki sıra).
7. Cloud Billing bütçe uyarısı (ör. aylık eşik) ve Firestore okuma/yazma kullanım alarmı (public liste taramasına karşı).
8. Admin hesaplarını asgari tutun; `role` değişikliği yalnız Console/Admin SDK ile yapılır. Yönetici hesabı şifresi paylaşılmasın.

## Kalan riskler (dürüst özet)
* Yönetici hesabı ele geçirilirse (phishing/şifre) her şey açılır — teknik engel yok, 2FA tek savunma.
* Public okuma koleksiyonları tamamen taranabilir (ürün gereği); maliyet saldırısı için bütçe alarmı + App Check.
* Storage kuralı **yayınlanana kadar** Console'daki mevcut kural geçerli (bilinmiyor).
* `Review.userName` taklit edilebilir; `User` belgesi alan sınırsız.
* Telefon doğrulama SMS maliyeti: bölge kısıtı sahibin yapacakları 4. madde.
