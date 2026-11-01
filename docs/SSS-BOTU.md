# Ekibe soru sor (Q-2) + kural tabanlı SSS botu

## Akış
1. Kullanıcı oyun sayfasında (web `site/js/sorular.js`, mobil `show_questions_section.dart`) yazarken **SSS botu** oyunun gerçek verisinden bir cevap önerir ("Cevap burada olabilir"). Yetmezse **Ekibe sor** ile gönderir.
2. `askQuestion({showId, text})`: giriş + **doğrulanmış telefon** + hesap silme beklemede değil. Metin 5-300 karakter; URL/telefon/e-posta (`freeTextProblem`) ve küfür (`moderation-words.js`) **reddedilir**. Hız sınırı: saatte 3 / günde 10 (`QuestionLimits/{uid}`).
3. Soru `status:'pending'` doğar, **kimseye görünmez**. O oyunun **ekip yöneticisi** (`/ekip` > Sorular) ya da **admin** (`/yonetim` > Moderasyon > Sorular) `answerQuestion({id, answer})` ile yanıtlar: cevap ≤600, bağlantı yasak, küfür yasak. Yanıtlanan soru `status:'answered', hidden:false` olur ve herkese görünür. (Cevapsız soru yayınlanmaz; "onayla" = "yanıtla".)
4. `rejectQuestion` / `hideQuestion` (sebep zorunlu, 3-200; `restore:true` geri açar) — hepsi `ModerationLog`'a `question_*` eylemiyle yazılır. Kapsam sunucuda `assertCanManageShow`: başka ekibin sorusu / yetkisiz kullanıcı `permission-denied`.
5. Şikâyet: `reportContent({type:'question', id, reason})`; yalnız **yayındaki** soru; **3 farklı telefonlu** kullanıcı → otomatik `hidden` (`hiddenReason:'reports'`). Engelle: `blockUser({questionId})` — uid sunucuda çözülür, `User/{me}/blocks/{uid}` belgesine `askerKey` yazılır; istemci o özetle soruları gizler.

## Veri ve gizlilik
- `Question/{id}`: `showId, askerName ("Ayşe K."), askerKey (uid'in tek yönlü özeti), text, status, hidden, answer, answeredBy (ekip adı), answeredAt, reportCount, createdAt`. **uid belgede yok.**
- `QuestionOwner/{id}` `{uid, showId}`, `QuestionReport/{qid_uid}`, `QuestionLimits/{uid}`: yalnız sunucu (rules: kapalı; `QuestionReport` yalnız admin okur).
- Rules: istemci hiçbir koşulda yazamaz. Okuma: `status=='answered' && hidden==false` (sorgu bu iki eşitliği içermeli) ya da admin. Sahibi bekleyen sorusunu `myQuestions` callable'ıyla görür (belgede uid olmadığı için doğrudan okuma yok).
- Hesap silme (`accountDeletion.js`): `QuestionOwner` silinir; soru silinir; **şikâyete/moderasyona konu olmuş** soru anonimleşir (ad/özet boş, metin ≤120, gizli); `QuestionReport`, `QuestionLimits` silinir; `ModerationLog.textSnapshot` boşaltılır.

## Bot kural tablosu (web `site/js/ssb.js` = mobil `lib/features/shows/domain/faq_bot.dart`)
Normalizasyon: küçük harf, `ı/İ/I→i, ğ→g, ş→s, ü→u, ö→o, ç→c`, harf/rakam dışı → boşluk. Anahtar sözcük **sözcük başında** eşleşir (ek-siz kök; `dakika` → `dakikadır`); sonu `$` ise tam sözcük. Her niyetin eşleşen sözcük sayısı puandır; en yüksek puan kazanır, eşitlikte tablo sırası. Hiçbiri eşleşmezse niyet `''`.

| Niyet | Anahtar sözcükler (normalize) | Cevap kaynağı | Alan yoksa |
|---|---|---|---|
| sure | sure, suruyor, surer, kac dakika, kac saat, kac dk, uzun, ne zaman biter, kacta biter, dakika | `duration` (+ `interval`) | bilgi yok |
| cocuk | cocu, bebek, minik, ilkokul, ortaokul, anaokul | `ageLimit` + `contentNotes` + sabit uyarı cümlesi | bilgi yok |
| yas | yas$, yasi$, yasinda, yas sinir, kac yas, yas kisit, yetiskin | `ageLimit` (+ `contentNotes`) | bilgi yok |
| ara | ara$, araya, ara var, antrakt, intermission, kac ara | `interval` | bilgi yok |
| gec | gec kal, gec gel, gec gir, gec kald, geciktim, gecik, salona al, sonradan gir, basladiktan sonra | sabit politika cümlesi | — |
| iade | iade, iptal, geri ver, para iade, bileti degis, vazgec, bileti ver | sabit politika (harici / rezervasyon / genel) | — |
| bilet | nasil bilet, bilet al, biletini nereden, bilet nereden/nerden, nereden/nerden al, satin al, rezervasyon, bilet nasil, nasil alirim/alabilir/satin | sabit cümle (harici / uygulama içi) | bitmiş oyunda bilgi yok |
| erisim | engelli, erisil, tekerlek, rampa, asansor, sesli betimleme, isaret dili, altyazi, isitme, gorme, kolay erisim | `access` kodları (AD, CAP, BSL, R, TS) + `Stage.accessNotes` | bilgi yok |
| ulasim | park, otopark, ulasim, metro, otobus, nasil gid/gel, yol tarif, adres, nerede$, nerde$, konum, mekan | mekân adı/adresi + `Stage.transit` | bilgi yok |
| uyari | icerik uyari, uyari, siddet, kufur, argo, korku, cinsel, strobo, isik efekt, yuksek ses, silah, kan$ | `contentNotes` | bilgi yok |

Cevap boşsa arayüz öneri göstermez; kullanıcı doğrudan "Ekibe sor" gönderir. Bot hiçbir zaman alan dışı bilgi üretmez. Mobilde `Stage.transit/accessNotes` henüz entity'de yok (yalnız mekân adı/adres kullanılır).

## Test vektörleri
`docs/ssb-vectors.json` (30 vaka) iki tarafı da sınar: `node site/tools/ssb-test.mjs` ve `flutter test test/faq_bot_test.dart`. Kuralı değiştirirsen iki dosyayı, bu tabloyu ve vektörleri birlikte güncelle.

## Sunucu testleri
`functions/test/questions.test.js` (doğrulanmamış reddi, filtre, hız sınırı, ön onay, ekip kapsamı, şikâyet eşiği, engelle, hesap silme + uid sızıntı taraması) ve `questions-rules.test.js` (rules).

## Deploy notu
`firestore.rules` ve functions (askQuestion, myQuestions, answerQuestion, rejectQuestion, hideQuestion, teamQuestions; `reportContent`/`blockUser` genişledi) birlikte yayınlanmalı (docs/DEPLOY-SIRASI.md). Yeni Firestore indeksi gerekmez (yalnız eşitlik sorguları).
