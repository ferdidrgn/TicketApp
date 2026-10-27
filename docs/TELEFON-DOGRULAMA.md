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
