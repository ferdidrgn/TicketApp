# Ekip yöneticisi rolü (İş T-1)

Amaç: bir oyunun sahibi/ekibi, **admin olmadan**, yalnızca kendi oyununun seanslarına gelen bilet sahiplerine bildirim (push + uygulama içi) atabilsin, kapı kontrolü yapabilsin ve doluluğu görebilsin. Hem hazır şablonla (otomatik metin) hem kısa elle yazılan mesajla.

## Model
- Yetki belgesi `TeamManager/{teamId}_{uid}`: `{teamId, uid, status:'active'|'revoked', addedBy, addedAt, revokedAt?, revokedBy?, displayName, emailHint (maskeli), phoneActive}`.
- `User.role` **değişmez** (yönetici `user` kalır). Yetki yalnız bu belgeden gelir.
- Yardımcı koleksiyonlar: `TeamManagerLog` (atama/geri alma günlüğü, yalnız admin okur), `TeamLimits/{uid}` (gönderim sayaçları, istemci erişemez).
- Kapsam her çağrıda SUNUCUDA hesaplanır: seans → `Event.showId` (doluysa tek doğruluk kaynağı; yoksa `Show.eventsId` yedeği, **tam 1** eşleşme şart) → `Show.teamId`. Çözülemezse (boş/belirsiz) **fail-closed**. İstemciden gelen `teamId` kabul edilmez.

## Yetki matrisi
| İşlem | Kim | Not |
|---|---|---|
| Yönetici ata / geri al (`adminSetTeamManager`) | yalnız admin | e-posta ya da uid; geri alma silmez |
| `getMyManagedTeams` | giriş yapmış herkes | yetkisize boş liste döner |
| `teamNotifyPreview`, `teamSendNotification` | aktif yönetici (kendi seans/oyunu) veya admin | hedef yalnız `event` / `show` |
| `teamCheckIn` | aktif yönetici (kendi seansının bileti) veya admin | seansa ±24 saat |
| `teamStats` | aktif yönetici (kendi oyunları) | kişisel veri yok |
| Ticket/Event/Show/Team/Order yazma, başkasının bileti okuma | KİMSE (istemciden) | rules değişmedi; yalnız `TeamManager*`/`TeamLimits` blokları eklendi |

`target: all | user`, başka ekibin seansı, serbest alarm → reddedilir (`permission-denied`).

## API (Cloud Functions, europe-west1)
- `getMyManagedTeams()` → `{teams:[{teamId,name,shows:[{showId,name,events:[{eventId,ms,dateText,stage,sold,held,total,inWindow}]}]}], templates, limits, now}`. Seans penceresi: son 24 saat – 90 gün.
- `teamNotifyPreview({target:{type,id}, template?, params?, title?, body?})` → alıcı sayısı (yalnız sayı), push alabilen sayısı, üretilmiş metin önizlemesi, kalan haklar (`quota`).
- `teamSendNotification({target, template, params?, title?, body?, confirm:true, requestId})` — `confirm` ve `requestId` (8–64 karakter) **zorunlu**; aynı `requestId` ikinci kez gönderilmez (`duplicate:true`).
- `teamCheckIn({ticketId, eventId?})` → `{ok, already?, wrongEvent?, ticket:{code,showName,eventDate,stageName,buySeats,seatCount,paymentStatus,payAtVenue,usedAt}}`. Müşteri adı/telefon/e-posta/uid **dönmez**. Başka ekibin bileti ile olmayan bilet aynı `not-found` ile yanıtlanır.
- `teamStats({teamId?})` → oyun/seans başına satılan, tutulan, toplam, doluluk %, aktif bilet, giriş yapılan.
- `adminSetTeamManager({teamId, email|uid, action:'add'|'revoke'})`.

## Mesaj kuralları
- Yalnız hazır şablonlar (`baslamak_uzere`, `basladi`, `ara`, `ara_bitiyor`, `bitti` metni sunucuda üretilir; `ertelendi`, `iptal`, `genel` kısa metinli). Şablonsuz serbest gönderim yok.
- **Alarm** (`kind:'alarm'`) yalnız sabit şablonlarda (başlıyor, ara bitiyor). Serbest metin alarm olamaz.
- Serbest metinde yasak: URL/alan adı (`http`, `www`, `.com`, `wa.me`, `t.me`, `bit.ly`…), e-posta/`@kullanıcı`, 10+ rakamlık telefon (boşluk/tire/parantez araya girse de; sıfır genişlikli karakterler temizlenir). Başlık 60, mesaj 240 karakter.
- Zamanlı şablonlar yalnız bir **seansa** ve seanstan ±24 saat içinde gönderilir (mevcut kural). Oyun hedefi = oyunun yaklaşan (son 24 saat dahil) seanslarının aktif bilet sahipleri; iptal/gelmedi biletler alıcı sayılmaz.
- Sessizde sesli hatırlatma, mevcut `notifPrefs.loudAlarm` izin mantığıyla aynıdır (yeni davranış yok).
- `NotificationLog`: `sentByRole:'teamManager'`, `teamId`, `showId`, `eventId` yazılır. Admin kayıtları değişmedi (rol alanı yok); panel `sentByName`'i göstermeye devam eder.

## Limitler (`TeamLimits/{uid}`, admin `UserLimits` sayacından ayrı)
Yönetici başına **10 gönderim/saat**, **30/gün**, **aynı seansa 24 saatte ≤ 5**. Sabitler: `functions/src/config.js → TEAM`.

## Hesap silme
Yönetici hesabında `pending`/`deleting` iken tüm yönetici callable'ları `ACCOUNT_DELETION_PENDING` döner. Hesap silinirken (`purge`): `TeamManager` belgeleri `revoked` yapılır, `uid` takma ada çevrilir, `displayName/emailHint/phoneActive` silinir; `addedBy/revokedBy`, `TeamManagerLog`, `NotificationLog.sentBy(Name)` takma adlanır; `TeamLimits/{uid}` silinir. (Belge **kimliği** eski uid'i içerir; Auth'ta karşılığı olmadığından anlamsızdır.)

## Atama / geri alma
Yönetim paneli → "Ekip yöneticileri": topluluk seç, kişinin e-postasını yaz (kişi daha önce siteye/uygulamaya giriş yapmış olmalı), ekle. Doğrulanmış telefonu yoksa uyarı gösterilir (atama yine geçerli). "Yetkiyi geri al" belgeyi silmez (`revoked`). Kişi `https://<site>/ekip` adresine girer (giriş zorunlu). Sayfa `noindex`, `no-store`, robots'ta `Disallow`, sitemap'te yok, prerender'a girmez.

## Dosyalar
`functions/src/team.js`, `functions/index.js` (6 yeni callable), `functions/src/notify.js` (yalnız `internals` dışa açıldı), `functions/src/accountDeletion.js`, `firestore.rules` (yalnız `TeamManager`, `TeamManagerLog`, `TeamLimits` blokları), `site/ekip.html`, `site/js/pages/ekip.js`, `site/css/ekip.css`, `site/js/admin/ekipyonetici.js` (+ admin.js'te 3 satır), `firebase.site.json` (rewrite + header).
Testler: `functions/test/team.test.js` (31 birim/akış), `team-rules.test.js`, `team-callable.test.js` (HTTP uçtan uca).

## Riskler / bilinen sınırlar
- Yönetici, hesabı ele geçirilirse kendi seanslarının bilet sahiplerine (≤5/seans/24 sa) kısa, bağlantısız metin gönderebilir; kişisel veri göremez. Telefon doğrulamalı hesap atamak önerilir.
- Serbest metin filtresi sezgiseldir (yazıyla yazılmış numara, boşluklu alan adı vb. kaçabilir); alıcılara yalnızca o oyunun biletlileri ulaşır ve her gönderim `NotificationLog`'da izlenir.
- Seans/oyun `Show.teamId` boşsa yönetici hiçbir şey yapamaz (kasıtlı); admin Show kaydında topluluğu seçmelidir.
- Oyun hedefi çok seanslı oyunda tüm yaklaşan seansların biletlilerini kapsar.
- Yeni zamanlanmış iş açılmadı; yeni koleksiyonlar hesap silme kapsamındadır.

## Sahibin yapacakları
1. Deploy sırası bozulmaz: **functions → istemciler → rules** (yeni callable'lar `functions` ile gider; rules en son).
2. Admin panelinde her oyunun **Topluluk** alanının dolu olduğunu kontrol et (yoksa ekip yöneticisi o oyunu göremez).
3. Panelden ilk yöneticiyi ata; kişiden `/ekip` adresine girip denemesini iste. Kapı için bilet QR'ı okutan okuyucu kodu `Bilet kodu` alanına yazar.
4. Hosting: `firebase deploy --only hosting:web --config firebase.site.json` (`/ekip` rewrite'ı içerir).
