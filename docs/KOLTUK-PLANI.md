# Koltuk planı uyumluluğu — 19.11.2026

## Amaç ve kapsam

Web yönetim paneli, bilet seçimi, ekip paneli ve mobil uygulama aynı sahne
planını okumalıdır. Mobil tema seçicisinin mevcut geliştirmesi de korunmuştur;
geçersiz/eksik HEX koduyla kayıt engellenir ve iptal edilen renk kaydedilmez.

## Veri sözleşmesi

| Veri | Güncel alan | Eski alan / yedek |
|---|---|---|
| Plan belgesi | `Seats/{stageId}` | Belge yoksa `Seats.where(stageId == id).limit(1)` |
| Koltuklar | `seatIds` | `seatsId`, ardından sıra adı → dizi |
| Kapalı koltuklar | `closedSeatIds` | `closedSeatsId` |
| Oluşturma | `createdAt` | `_createdAt` |
| Güncelleme | `updatedAt` | `_updatedAt` |

Güncel belge ve alanlar önceliklidir; boş kapalı-koltuk dizisi de geçerli bir
seçimdir. Meta alanlar sıra sayılmaz, yinelenen/boş kimlikler okuyucularda
elenir. Sunucu, yeni bir seansın `Event.seats` alanını bu plandan üretirken
kapalı koltukları `blocked` yapar.

## Kaydetme

`/yonetim/koltuk-plani`, `adminUpsertSeatPlan` callable'ını çağırır. Yetki
sunucuda `User/{uid}.role == admin` ile kontrol edilir. Plan 1–5000 benzersiz,
geçerli koltuk kimliği içermelidir. Sahne mevcut olmalıdır.

Tek transaction içinde eski belge okunur, oluşturma bilgisi ve kapalı
koltuklar korunur; plan `Seats/{stageId}` belgesine yazılır. Eski rastgele
kimlikli belge varsa aynı transaction içinde kaldırılır. Plandan çıkarılan
koltuklar kapalı listeden de çıkarılır. Eski istemciler için `seatsId`,
`closedSeatsId`, `_createdAt`, `_updatedAt` alanları da yazılır. Kapasite
yalnızca paneldeki seçenek işaretliyse güncellenir.

Mevcut `Event`, `Ticket` ve `Order` kayıtları bu işlemle değiştirilmez.
Panelin istekte kapalı-koltuk listesini tekrar göndermesi gerekmez; güncel
liste transaction içinde sunucuda korunur.

## Doğrulama

- Geçti: `node --test functions/test/seat-plan-unit.test.js` — 10 test.
  Web/sunucu alan önceliği, eski düzen, metadata, yönetici yetkisi,
  girdi doğrulama, plan taşıma, kapalı koltuk ve kapasite korunması.
- Geçti: Flutter profile web kontrol derlemesi; `tmp/verify-mobile` çıktısı.
  Bu çıktı mobil Flutter kodunun derleme kontrolüdür; yayın web sitesi `site/`
  olarak kalır. Derlemede mevcut CupertinoIcons font uyarısı bulunur.
- Dart analizinde değiştirilen dosyalarda derleme hatası yoktur; mevcut
  bilgi seviyesindeki stil/deprecation bildirimleri sürmektedir.
- Bekliyor: `functions/test/seat-plans.test.js` ve callable testleri,
  gerçek Firestore/Auth/Functions emülatörleriyle çalıştırılmalıdır.
- Bekliyor: `flutter test test/purchase/seat_plan_data_test.dart` — 6 senaryo.
  Bu oturumda test süreci yüklenmeden yerel soket bağlantısı engellendi.
  Firebase CLI da emülatör hub bağlantısını kuramadı; `127.0.0.1` için
  `EACCES` / Windows soket hatası alındı. Bunlar geçmiş test olarak sayılmaz.

## Yayın sırası

Önce `adminUpsertSeatPlan` ve güncel bilet backend'i deploy edilmelidir;
sonra `site/` ve mobil istemci yayınlanır. Bu oturumda canlı deploy yapılmadı.
Firestore kuralları değiştirilmedi. Genel sıra: functions → istemciler →
gerekirse kurallar; `docs/DEPLOY-SIRASI.md` geçerlidir.
