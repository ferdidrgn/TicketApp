# Anket (F-5) ve "Birlikte gidelim" planı (F-6)

Kod: `functions/src/polls.js`, `functions/src/plans.js`, `functions/index.js` (callable'lar), `firestore.rules`,
web `site/js/anket.js` + `site/js/admin/anket.js` + `site/plan.html` + `site/js/pages/plan.js` + `site/js/plan-olustur.js`,
mobil `lib/features/polls/**`. Testler: `functions/test/polls.test.js`, `functions/test/plans.test.js`, `test/polls/poll_test.dart`.

## Anket (F-5)
- `Poll/{id}`: `question, options[{id:o1..o6,label,showId?}], counts{optId:n}, totalVotes, status(active|closed), startsAt, endsAt, createdAt`.
  Herkese okunur; **istemci hiçbir şey yazamaz** (rules). Oluşturma/kapatma: admin callable `adminCreatePoll` / `adminClosePoll`
  (soru + 2-6 seçenek, metin süzgeci: URL/e-posta/telefon/küfür reddedilir; en fazla 120 gün). Admin kimliği belgeye yazılmaz.
- Oy: callable `votePoll({pollId, optionId})` — giriş + **doğrulanmış telefon** + hesap silme beklemede değil + hız sınırı (20/saat, 60/gün)
  + anket aktif (durum + tarih penceresi) + geçerli seçenek. Transaction: ilk oy `+1` (ve `totalVotes+1`), değiştirme eski `-1` yeni `+1`, aynı seçenek no-op.
- Tekillik: `Poll/{id}/votes/{uid}` (hesap başına, yalnız sahibi okur) **ve** `Poll/{id}/phoneVotes/{phoneKey}` (telefon özeti; uid içermez, istemciye kapalı).
  Sayılan oy telefon özetindedir: aynı kişi yeni hesapla ikinci oy veremez, yalnız mevcut oyu değiştirir. Düz telefon hiçbir yere yazılmaz.
- Hesap silme (`accountDeletion.purge`): `votes/{uid}` ve `PollLimits/{uid}` silinir; `counts`/`totalVotes` ve `phoneVotes` KALIR (toplam bozulmaz, uid kalmaz).
- Sonuç görünürlüğü: arayüz yüzdeleri oy verdikten sonra ya da anket bitince gösterir. **Sınırlama:** `Poll.counts` belgesi herkese okunur olduğundan
  teknik olarak oy vermeden de okunabilir (arayüz kuralı, gizli sandık değil).
- Sunucu tuzu: `votePoll` `PHONE_HASH_SALT` sırrına bağlıdır (`salted`).

## Plan (F-6)
- `createPlan({showId, eventId?})` (girişli, anonim hesap hariç): 12 karakter rastgele kimlik; seans oyuna ait olmalı (Event.showId önce, yoksa Show.eventsId) ve geçmiş olmamalı.
  Hız sınırı 5/saat, 10/gün; günlük küresel tavan 1000 plan.
- `Plan/{id}` herkese **tek belge** okunur (liste yok): `showId, eventId, showName, eventDate, counts{gelirim,belki,gelemem}, responseCount, createdAt, expireAt`.
  Oluşturan kimliği/adı/telefonu belgede YOK; sahip kaydı `PlanOwner/{id}` (istemciye kapalı). Sayfada "Bir arkadaşın seni davet etti".
- `respondPlan({planId, name, choice, clientKey})` **girişsiz**: takma ad ≤30 karakter (URL/e-posta/telefon/uzun rakam/küfür reddedilir), cihaz anahtarı
  sunucuda `sha256(planId:anahtar)` ile `responses/{responderKey}` kimliğine çevrilir; aynı cihaz yanıtını değiştirir (en çok 10 kez).
  Korumalar (IP/uid yok, App Check yok): plan başına ≤50 yanıt, günlük küresel ≤5000 yanıt. **Kalan risk:** bağlantıyı bilen biri çok sayıda sahte cihaz
  anahtarıyla bir planın 50 yerini doldurabilir (yalnız o planı etkiler); App Check açılınca (`ENFORCE_APP_CHECK`) azalır.
- Plan sahibi (girişli) yanıtları `getPlanResponses` ile görür; yanıtlar istemciye kapalı.
- Grup rezervasyonu/ödeme yok. Sayfa: `/plan/<id>` (noindex, prerender dışı, `firebase.site.json` rewrite, robots Disallow).
- Paylaşım: web oyun sayfasında "Birlikte gidelim" (seçili seans) + mevcut Paylaş menüsü (WhatsApp/kopyala/Web Share); mobil oyun sayfası paylaş düğmesi → sayfa:
  "Oyunu paylaş" / "Birlikte gidelim" (`share_plus`).

## Sahibinin yapacakları (Console)
1. **Firestore TTL politikaları** (deploy sonrası): `Plan` koleksiyonu `expireAt`; koleksiyon grubu `responses` `expireAt`; `PlanOwner` `expireAt`;
   `PlanLimits` `expireAt` (günlük sayaçlar). TTL silmesi alt koleksiyonları silmez; bu yüzden `responses` için ayrı politika şart.
2. Deploy sırası: önce functions, sonra `firestore.rules` (docs/DEPLOY-SIRASI.md).
