# Seats mimarisi

`Seats` sahnenin statik oturma planıdır. Satış anındaki koltuk durumu burada
tutulmaz; bu durum `Event.seats` içinde tutulur ve yalnızca Cloud Functions
tarafından değiştirilir.

## Canonical belge

`Seats/{stageId}`:

```text
schemaVersion: 2
_id: stageId
stageId: string                 // immutable, Stage/{stageId} ile aynı
stageName: string               // Stage snapshot'ı
address: string                 // Stage snapshot'ı
seatIds: string[]               // canonical
closedSeatIds: string[]         // seatIds alt kümesi
seatCount: number
createdAt: Timestamp
updatedAt: Timestamp
createdBy: string               // server/admin
updatedBy: string               // server/admin
```

Bir sürüm boyunca eski istemciler için `seatsId`, `closedSeatsId`,
`_createdAt` ve `_updatedAt` alanları dual-write edilir. Okuyucular önce yeni
alanları, sonra eski alanları okur. Eski random-ID'li bir belge `stageId`
alanından bulunabilir; ilk admin kaydında transaction ile `Seats/{stageId}`
belgesine taşınır ve eski kopya kaldırılır.

## Yazma akışı

Web yönetim paneli doğrudan Firestore yazmaz. `adminUpsertSeatPlan` callable'ı:

- admin rolünü sunucuda doğrular;
- Stage'in varlığını kontrol eder;
- koltuk ID'lerini tip, uzunluk, tekrar ve boyut açısından doğrular;
- `stageName` ve `address` bilgisini Stage'den alır;
- server Timestamp ve audit alanlarını yazar;
- gerekirse Stage kapasitesini aynı transaction içinde günceller.

Firestore Rules'ta Seats yazımı kapalıdır; callable Admin SDK ile yazdığı için
Rules'ı atlar. Bu, istemci saatiyle sahte audit tarihi ve schema pollution
riskini azaltır.

## Bilinçli sınırlar

- Stage adresi Seats içinde snapshot'tır; canonical adres her zaman Stage'dedir.
- Sahne planı değişince daha önce oluşturulmuş Event.seats otomatik değiştirilmez.
  Satılmış veya rezerve koltukların bozulmaması için yeni plan yalnızca yeni
  seanslara uygulanır.
- `Seats` doğrudan document ID veya `stageId` fallback sorgusuyla okunur;
  listeleme/composite index gerektiren bir kullanım yoktur.
