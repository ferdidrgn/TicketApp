# Telefon doğrulamalı kimlik — istemci API özeti (mobil + web)

Kısa ve kesin sözleşme. Ayrıntı/gerekçe/güvenlik analizi: `docs/ODEME-GUVENLIK.md` "Telefon doğrulamalı kimlik".
Backend: `functions/` (Cloud Functions, europe-west1). Dağıtılana kadar canlıda YOKTUR.

## Kural (tek cümle)
Bilet / rezervasyon / koltuk tutma, ID token'ında **`phone_number` (E.164, Firebase SMS doğrulaması)** olmadan yapılamaz.
Ücretsiz bilet (kişi başı toplam 3) ve rezervasyon hakları **e-posta/uid'e değil telefona** bağlıdır; yeni hesap açmak hak yenilemez.

## 1. Etkilenen callable'lar
| Callable | Telefon gerekir mi |
|---|---|
| `holdSeats`, `confirmFree`, `confirmReservation`, `startPayment` | **EVET** |
| `releaseHold`, `cancelTicket`, tüm `admin*` | hayır |
| `syncPhoneVerification` (YENİ) | hayır (giriş yeterli) |

Giriş yok -> `unauthenticated` (eskisi gibi). Giriş var ama token'da `phone_number` yok (anonim, e-posta, Google; telefon bağlanmamış
ya da token eski) ->

```
code:    "failed-precondition"           // Flutter: FirebaseFunctionsException.code == 'failed-precondition'
message: "PHONE_REQUIRED"
details: { "code": "PHONE_REQUIRED" }    // Flutter: e.details['code']; web: err.details.code
```
İstemci bu hatada kullanıcıyı telefon doğrulama (SMS) ekranına götürür. Metni kullanıcıya OLDUĞU GİBİ göstermeyin ("PHONE_REQUIRED" bir kod).
Diğer hatalar değişmedi (`resource-exhausted` limit aşımı vb.; mesajlar Türkçe).

## 2. Doğrulama sonrası ZORUNLU iki adım
Telefonu bağladıktan (`signInWithPhoneNumber` / `linkWithCredential` / `updatePhoneNumber`) ya da giriş yaptıktan sonra:

1. **Token'ı tazele:** `await user.getIdToken(true)` (Flutter: `FirebaseAuth.instance.currentUser!.getIdToken(true)`).
   Sunucu yalnızca token'daki claim'e güvenir; tazelemezseniz hâlâ `PHONE_REQUIRED` alırsınız.
2. **`syncPhoneVerification` çağır** (veri göndermeyin):
   - web: `httpsCallable(functions, 'syncPhoneVerification')({})` · Flutter: `FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('syncPhoneVerification').call()`
   - Yanıt: `{ isPhoneActive: true, phoneNumber: "+905551234567" }` ya da `{ isPhoneActive: false }` (hata atmaz).
   - Sunucu `User/{uid}` belgesine `phoneNumber`, `isPhoneActive:true`, `phoneVerifiedAt`, `phoneKey` yazar (belge yoksa en az bu alanlarla oluşturur; `role`'e dokunmaz).
   - Her girişte (oturum açılışında) çağırın; telefon sonradan kaldırılmışsa `isPhoneActive:false` olur.

## 3. User belgesi — istemci ne yazabilir (firestore.rules)
- `isPhoneActive`: yalnızca `false`/`null`/yok yazılabilir (create ve update). **`true` yalnızca sunucu yazar.**
  Belgede zaten `true` ise aynı değerle tam-belge güncellemesi (değişmeyen alan) sorun değildir.
- `phoneVerifiedAt`, `phoneKey`, `role`: istemci OLUŞTURURKEN/DEĞİŞTİRİRKEN değiştiremez (yok sayın; tam-belge yazarken eski değeri aynen geri yazın ya da hiç yazmayın -> `update` ile yalnızca değişen alanları gönderin).
- `phoneNumber`: yalnızca boş (`''`/null/yok), değişmeden, ya da **token'daki `phone_number` ile birebir aynıysa** yazılabilir. Doğrulanmamış numara User'a YAZILMAZ; kullanıcıdan alınan ham numara yalnızca `verifyPhoneNumber`/`signInWithPhoneNumber`'a gider.
- Önerilen: kayıtta `isPhoneActive: false` (web zaten böyle) veya hiç yazmayın; geri kalan alanlar (ad, fcmToken, favoriler...) serbest.

## 4. Limit anahtarı (bilgi)
`UserLimits/ph_<sha256(e164 + sunucu tuzu)>`. İstemci okuyamaz (kural: yalnız eski `UserLimits/{uid}` belgesini sahibi okur). Kalan hak göstermek gerekirse
bunu sunucudan yeni bir callable ile isteyin (şu an yok); `resource-exhausted` hatası mesajı yeterlidir.

## 5. Emülatörde test
Auth emülatörü: `accounts:sendVerificationCode` -> `GET /emulator/v1/projects/<p>/verificationCodes` -> `accounts:signInWithPhoneNumber`
ile `phone_number` claim'li token alınır (bkz. `functions/test/helpers.js: signInPhone`).

## 6. Özet kontrol listesi (istemci)
- [ ] Satış callable'ı `PHONE_REQUIRED` verirse SMS doğrulama akışı -> `getIdToken(true)` -> `syncPhoneVerification` -> işlemi tekrarla.
- [ ] Girişte `syncPhoneVerification`.
- [ ] User'a `isPhoneActive:true` / doğrulanmamış `phoneNumber` YAZMA.
- [ ] Hesap silip yeniden açma sayaç sıfırlamaz — "yeni hesapla 3 hak" vaadi verme.

## 7. Çapraz denetim sonuçları (27.10.2026) — istemcilerin uyması gereken ek kurallar
- **Sunucu taslağı:** `syncPhoneVerification` User belgesi yoksa TAM varsayılan belge yazar (`_id`, `role:'user'`, boş listeler, ISO `_createdAt`). İstemci
  kayıt kodu `getDoc` ile "var mı" bakıp varsa oluşturmayı atlar (mobil `saveUser(isUpdate:false)` ve web `kullaniciBelgesi` böyle). Web, sunucu eşitlemesinden ÖNCE kendi belgesini oluşturur (ad kaybolmasın).
- **Web `phoneNumber` yazmaz:** web kayıt yükü `phoneNumber:''`, `isPhoneActive:false` yazar; numarayı yalnız sunucu yazar (token henüz taze değilken rules reddetmesin).
- **Tuz fail-closed:** üretimde `PHONE_HASH_SALT` (>=16 karakter) yoksa satış/sync `unavailable` (`details.code=SALT_MISSING`) döner. İstemci bunu genel "satış şu an kullanılamıyor" olarak gösterir.
- **Misafir (anonim) hesap:** satış callable'ları anonim token'ı `PHONE_REQUIRED` ile reddeder. Mobilde misafir zaten koltuk seçemez (girişe yönlendirilir); girişte telefon seçilirse
  `linkWithCredential` ile misafir hesabı telefona bağlanır (uid aynı kalır) — emülatör testiyle kanıtlı (`phone-gate.test.js: E2E anonim`). Ek bir "misafir sheet'i" gerekmedi; yönlendirme sahibin hedefi için yeterli.

## 8. Yayın (deploy) sırası ve eski sürümler
1. **Firebase Console > Authentication > Telefon** sağlayıcısını aç; SMS bölge politikası yalnız Türkiye (+90); kota/fatura uyarısı; **"Test için telefon numaraları" ÜRETİMDE BOŞ olmalı** (sabit kodla doğrulama = limit atlatma).
2. `PHONE_HASH_SALT` ayarla (>=16 rastgele karakter; yayından sonra DEĞİŞTİRME). Ayarlamazsanız satış kapalı kalır (bilinçli güvenlik).
3. `firebase deploy --only functions` (telefon kapısı + `syncPhoneVerification`). **Bu andan itibaren telefon desteği olmayan eski mobil sürümler satış yapamaz** (`PHONE_REQUIRED`
   ya da genel hata). Bu yüzden 4'ü aynı gün yapın.
4. Mobil uygulamayı (telefon akışlı sürüm) mağazalara yayınla; web sitesini (`site/`) deploy et. Eski mobil sürümler için **zorunlu güncelleme (force-update)** önerilir:
   Remote Config / `Config` belgesinde `minSupportedBuild` tutup açılışta eski sürümde "Biletleme için uygulamayı güncelle" ekranı gösterin (henüz uygulanmadı — sahibin kararı).
5. **En son** `firebase deploy --only firestore:rules` (functions'tan ÖNCE değil). Rules'u önce yayımlarsanız `isPhoneActive:true`/numara yazan eski istemciler kayıt/profil güncellemesinde reddedilir.
6. Canlı duman testi (SMS'li, gerçek numara): e-posta/Google hesabı -> koltuk seç -> telefon doğrula -> hold -> onay; ikinci hesapla aynı numarayı bağlamayı dene (reddedilmeli);
   hesabı sil, yeni hesapla aynı numara -> sayaç sürmeli. **Not:** `phone_number` claim'inin, SONRADAN bağlanan (linked) telefon için de tazelenen token'da bulunması emülatörde kanıtlıdır; canlı Firebase'de ilk dağıtımda
   bir kez doğrulayın (bulunmazsa `PHONE_REQUIRED` döngüsü görürsünüz; çözüm: sunucuda `getAuth().getUser(uid).phoneNumber` yedeği).

## 9. Bilinen açık / kabul edilen riskler (denetim)
- **Yeni SIM = yeni kişi.** Başka bir numaraya erişen yeni 3 hak alır (SMS doğrulamanın doğası). Önlem: SMS bölge kısıtı, App Check (`ENFORCE_APP_CHECK=true`, web reCAPTCHA Enterprise), izleme.
- **İptal iadesi:** ücretsiz/rezervasyon bileti iptal edilince sayaç iade edilir (kasıtlı: toplam = ELDEKİ bilet). Döngü (al-iptal-al) hak üretmez ama koltuk tutup bırakarak envanteri oynatabilir.
  Öneri (uygulanmadı): `ph_*` belgesinde ömür boyu `cancelCount`; örn. 10'dan sonra yeni ücretsiz/rezervasyon hakkı için yönetici onayı. İptal süresi (`iptalSaat`) zaten son anı engelliyor.
- **Etkinlik başına koltuk üst sınırı (`SEAT_LIMIT_PER_EVENT`)** hâlâ uid anahtarlıdır (Ticket/Order sorguları `uid`). Ücretsiz/rezervasyon toplamı telefona bağlı olduğundan bunlar delinmez;
  yalnızca ÜCRETLİ online satış açıkken hesabı silip aynı numarayla yeniden açan biri etkinlik başına 5 koltuk sınırını yenileyebilir (anti-stokçuluk; ödeme zaten gerekir). Gerekirse `Order.phoneKey` sorgusuyla telefona bağlanır.
- **Test numaraları / SMS pompalama:** Console "test numaraları" listesi üretimde boş olmalı; SMS maliyet saldırısı için bölge kısıtı + App Check.
- **Eski token (<=1 saat):** telefonu kaldırılan hesabın token'ı süresince satış mümkün, ama sayaç yine o numaraya yazılır.

## 10. Gizlilik metni taslağı (hukuki tavsiye değildir; avukat/VERBİS yükümlüsü gözden geçirmeli)
> **Telefon numarası ve bilet hakları.** Bilet, rezervasyon ve koltuk tutma işlemleri için SMS ile doğrulanmış telefon numaranızı hesabınıza bağlamanızı isteriz.
> Bu doğrulama (i) hesabınızın gerçek bir kişiye ait olduğunu teyit etmek, (ii) ücretsiz bilet ve rezervasyon sınırlarının (kişi başı toplam üç ücretsiz bilet vb.)
> farklı hesaplar açılarak aşılmasını önlemek ve (iii) ödeme sağlayıcısının zorunlu tuttuğu iletişim bilgisini sağlamak amacıyla yapılır. Telefon numaranız hesabınızda ve kimlik doğrulama
> hizmetimizde (Google Firebase Authentication) saklanır; SMS gönderimi bu hizmet tarafından yapılır. Hak sınırlarını uygulayabilmek için numaranızın geri döndürülemeyen (tuzlu özet / hash) bir türevi ayrıca saklanır;
> bu özet hesabınızı sildiğinizde de suistimali önleme meşru menfaatimiz kapsamında sınırlı süre korunabilir. Numaranız reklam amacıyla kullanılmaz ve üçüncü kişilerle (ödeme işleme dışında) paylaşılmaz.
> Haklarınız (erişim, düzeltme, silme, itiraz) için: [iletişim e-postası]. Saklama süresi: [belirlenecek].
