# TiyatRol güvenlik denetimi ve açılış planı

Tarih: 10.11.2026  
Kapsam: Firebase backend, Firestore/Storage Rules, Cloud Functions, web, web
yönetim paneli, Flutter mobil, ödeme ve bilet/check-in akışları.

Bu çalışma salt-okunur bir kod ve canlı Firebase yapılandırma denetimidir.
Canlı sisteme saldırı yapılmadı; testler yalnızca yerel/emülatör ve güvenli
kod incelemesi sınırında tutuldu.

## Sonuç

Genel seviye: **orta-yüksek risk; genel kullanıma açılış için henüz hazır değil.**

Güçlü taraflar:

- Firestore son kuralı deny-by-default.
- Kullanıcı istemcisi Ticket/Order/Event.seats/UserLimits yazamıyor.
- Kullanıcı kendi `role` alanını `admin` yapamıyor.
- Bilet silme kuralı kapalı.
- Satın alma koltuk, fiyat, limit ve ödeme doğrulamalarını sunucuda transaction ile yapıyor.
- Telefon limiti Secret Manager tuzuyla hashleniyor; tuz yoksa satış fail-closed.
- Storage’da listeleme kapalı ve genel fallback deny var.

## Release blocker’lar

### SEC-001 — App Check üretimde zorunlu değil

Kanıt: `functions/index.js`, `site/js/firebase.js`.

`ENFORCE_APP_CHECK` varsayılanı `false`; yeni web sitesinde App Check site key’i
boş. Saldırgan geçerli bir hesap veya otomasyonla callable uçlarını doğrudan
tüketebilir. Etki: SMS, koltuk tutma, yorum/soru, plan yanıtı ve maliyet/DoS.

Plan:

1. Web reCAPTCHA App Check key’i ekle.
2. Android Play Integrity, iOS DeviceCheck/App Attest production ayarlarını doğrula.
3. 1–2 hafta metrik izle.
4. Functions, Firestore ve Storage enforcement’ı aç.
5. `respondPlan`, `trackView` ve ödeme callback’i için ayrıca IP/edge rate limit uygula.

### SEC-002 — QR raw Ticket ID taşıyor

Kanıt: `lib/features/tickets/presentation/pages/ticket_details_modal.dart`,
`lib/core/services/deeplink/deeplink_service.dart`, `functions/src/orders.js`.

QR veya paylaşılmış URL sızarsa başka biri check-in denemesi yapabilir.

Plan:

- QR içine kısa ömürlü imzalı nonce koy.
- Backend nonce + ticket + event + check-in penceresini doğrulasın.
- Nonce transaction içinde tek kullanımlı tüketilsin.
- Check-in cihazı App Check ve admin/team rolü ile sınırlandırılsın.
- Raw ticket ID QR payload’ından çıkarılsın.

### SEC-003 — Bilet geçmişi append-only değil

Bilet silinemiyor; ancak iptal, no-show, check-in ve bazı arşiv alanları
değişebiliyor. Eski değer, aktör, gerekçe ve request ID bağımsız değişmez bir
kayıtta tutulmuyor.

Önerilen model:

```text
Ticket/{ticketId}                  güncel görünüm
TicketEvent/{eventId}              append-only durum geçmişi
AdminAuditLog/{auditId}            admin/operasyon işlemi
```

Her event: `ticketId`, `orderId`, `eventId`, `action`, `before`, `after`,
`actorUid`, `actorRole`, `reason`, `requestId`, `createdAt`, `prevHash`.

TicketEvent/AdminAuditLog istemciye tamamen kapalı olmalı; yalnızca güvenlik ve
admin callable’ları okuyabilmeli. Ticket silme kapalı kalmalı.

## Yüksek öncelikli bulgular

### SEC-004 — Admin içerik yazımları doğrudan Firestore’a gidiyor

Web admin `Show`, `Stage`, `Event`, `Team`, `Player`, `Campaign` ve bazı `Config`
yazımlarını doğrudan yapıyor. Rules bunu yalnız admin rolüne açıyor; ancak
şema, alan boyutu, ilişki bütünlüğü ve audit merkezi değil.

Plan: tüm kritik admin yazımlarını callable + allow-list + tip/boyut doğrulaması
ve transaction’a taşımak. Admin MFA ve hassas işlem öncesi yeniden doğrulama
eklemek.

### SEC-005 — Payment WebView fazla geniş

`payment_web_view_page.dart` JavaScript’i açık tutuyor, `http/about/data`
şemalarını kabul ediyor ve sunucudan gelen HTML’yi çalıştırıyor.

Plan: yalnızca iyzico host allow-list’i, yalnızca HTTPS, dönüş URL’sini backend
Order durumuyla doğrulama, güçlü CSP; mümkünse hosted checkout’i dış tarayıcıda
açma.

### SEC-006 — Hosting security header’ları eksik

`firebase.site.json` içinde CSP, HSTS, nosniff, frame-ancestors/X-Frame-Options,
Referrer-Policy ve Permissions-Policy yok.

Plan: önce `Content-Security-Policy-Report-Only`, sonra raporlar temizlenince
public/admin için ayrı enforce CSP. Admin için clickjacking koruması zorunlu.

### SEC-007 — Public projection ayrımı yok

Show/Stage/Event/Seats gibi public okunan belgeler yanlışlıkla iç alan eklenirse
herkese açılır. `Event.seats` içinde orderId/hold bilgisi gibi operasyonel alanlar
public dokümanda tutuluyor.

Plan: public katalog/seat-status projection’ı ile private operasyon dokümanını
ayırmak; orderId, holdExpiresAt, iç not ve maliyet alanlarını public belgeye
koymamak.

### SEC-008 — Storage yalnız metadata ile dosya tipi kontrol ediyor

`contentType` istemci tarafından gönderilebilir. Kötü içerik metadata’sı ile
yüklenebilir.

Plan: quarantine upload → Cloud Function magic-byte/decode doğrulaması →
re-encode edilmiş raster public path. EXIF/GPS temizliği, orphan cleanup ve
güvenli `Content-Disposition` eklenmeli.

### SEC-009 — Profil görselleri tahmin edilebilir

`ppics/{uid}.jpg` yolu giriş yapmış kullanıcılarca UID ve uzantı denenerek
okunabiliyor.

Plan: bilinçli public profil resmi değilse random object ID + erişim kontrolü;
listeleme kapalı kalmalı.

### SEC-010 — Mobil offline cache sınırsız

`CACHE_SIZE_UNLIMITED` bilet/sipariş verisini cihazda süresiz tutabiliyor.

Plan: makul cache sınırı, logout cache temizliği, hassas bilet ekranında offline
veriye güvenmeme.

### SEC-011 — Deep link ve ham auth hata logları

Deep link path’leri ve bazı Firebase exception mesajları production loglarına
sızabilir.

Plan: route tipi + hash logla; ham path, e-posta, telefon, token ve Firebase
exception metnini kullanıcıya/log’a verme.

### SEC-012 — iOS push entitlement production değil

`ios/Runner/Runner.entitlements` içinde `aps-environment=development` görülüyor.
Release için `production` olmalı; aksi halde bildirim teslimi bozulabilir.

## Yedekleme ve bilet arşivi

Canlı kontrol:

- Firestore Standard, bölge `nam5`, pessimistic concurrency.
- `pointInTimeRecoveryEnablement`: **DISABLED**.
- Scheduled backup listesinde kayıt görünmedi.
- `deleteProtectionState`: **DISABLED**.

Her iki saatte bir PDF/Excel üretmek ana yedekleme çözümü olmamalı. Önerilen
katmanlar:

1. Firestore PITR’yi aç.
2. Günlük scheduled backup oluştur; kritik dönemde 2–6 saatlik export düşünülebilir.
3. Ayrı GCS backup bucket, retention policy ve mümkünse retention lock/versioning kullan.
4. TicketEvent/AdminAuditLog ile değişmez operasyon geçmişi tut.
5. Ayda/çeyrekte düzenli restore tatbikatı yap; yalnız backup varlığı yeterli değildir.
6. Backup ve audit verilerini KVKK/erişim politikasıyla ayrıca sınırla.
7. Cloud Audit Logs Data Access kayıtlarını ve maliyet alarmını değerlendir.

## Uygulama sırası

### Dalga 0 — Açılış kapısı

- App Check web/mobil/backend enforcement.
- QR signed nonce ve tek kullanımlı check-in.
- Admin hesaplarında MFA/passkey.
- PITR + scheduled backup + delete protection.
- Kritik callable/rules red-team testlerinin CI’da yeşil olması.

### Dalga 1 — Veri bütünlüğü

- TicketEvent/AdminAuditLog.
- Ticket durum geçiş tablosu ve zorunlu reason.
- Show/Stage/Event admin yazımlarını callable’a taşıma.
- Soft-delete: `archivedAt`, `archivedBy`, `archiveReason`.
- Event public/private projection ayrımı.

### Dalga 2 — Web/mobil hardening

- CSP/HSTS/security headers.
- Payment WebView daraltması.
- Storage quarantine/re-encode.
- Offline cache ve deep-link log temizliği.
- iOS production push entitlement.
- Dependency lock/scanning ve CDN sürüm kontrolü.

### Dalga 3 — Operasyon ve izleme

- Cloud Audit Logs → uzun süreli log bucket/BigQuery sink.
- App Check başarısızlık, permission denied, admin değişikliği, ödeme anomalisi
  ve backup başarısızlığı için alarm.
- Restore tatbikatı ve olay müdahale runbook’u.
- Aylık admin/IAM erişim gözden geçirmesi.

## Araştırma kaynakları

- [Firebase App Check enforcement](https://firebase.google.com/docs/app-check/enable-enforcement)
- [Firestore disaster recovery](https://firebase.google.com/docs/firestore/disaster-recovery)
- [Firestore scheduled backups](https://firebase.google.com/docs/firestore/backups)
- [Cloud Audit Logs](https://docs.cloud.google.com/logging/docs/audit)
- [Data Access audit logs](https://docs.cloud.google.com/logging/docs/audit/configure-data-access)
- [Firestore offline data](https://firebase.google.com/docs/firestore/manage-data/enable-offline-data)

Bu doküman güvenlik garantisi değildir; açılış öncesi son doğrulama canlı App
Check metrikleri, gerçek cihaz build’leri, ödeme sandbox testi, emülatör red-team
testleri ve restore provasıyla yapılmalıdır.
