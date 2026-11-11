# Güvenlik ve Bilet Yaşam Döngüsü İlerlemesi

Son güncelleme: 2026-11-11

Bu dosya; bilet silinmezliği, iptal/koltuk serbest bırakma, uygulama kredisi, koltuk başına QR ve Firebase kurtarma planının tek takip noktasıdır.

## Ürün kararları

- Bilet dokümanı silinmez; iptal, check-in ve no-show yalnızca durum geçişidir.
- Her koltuk bağımsız giriş hakkıdır. Üç koltuklu satın alımda üç QR gösterilir; iki QR okutulursa üçüncü koltuk kullanılmamış kalır.
- İptal para iadesi üretmez. Ödenmiş tutarın koltuk payı, tekrar kullanılmak üzere `UserCredit` bakiyesine ve değişmez `UserCreditEvent` hareketine yazılır.
- QR içinde bilet kimliği tek başına kullanılmaz. Yeni QR payload'ı `ticketId:seatId:opaqueToken` biçimindedir.
- Eski biletler geriye dönük uyumluluk için eski tek QR davranışıyla okunur; yeni biletler koltuk bazlı şemayı kullanır.

## İlerleme

- [x] Canlı Firestore yapılandırması incelendi: Standard / `nam5`, PITR kapalı, scheduled backup görünür değil, delete protection kapalı.
- [x] Web, mobil ve backend için kırmızı takım güvenlik bulguları ve yayın öncesi planı yazıldı: `docs/SECURITY-AUDIT-2026-11.md`.
- [x] TicketAudit append-only koleksiyonu için server-only kuralı eklendi.
- [x] Bilet oluşturma, iptal, admin durum değişikliği ve check-in olayları için bağımsız audit olayları eklendi.
- [x] İptalde koltuk serbest bırakma korunarak para iadesi kaldırıldı; ücretli bilet için uygulama kredisi hareketi eklendi.
- [x] Yeni biletlerde koltuk başına QR token ve check-in sayacı eklendi.
- [x] Admin check-in, `ticketId:seatId:token` QR payload'ını koltuk düzeyinde doğrulayacak şekilde genişletildi.
- [x] Mobil bilet ekranı koltuk başına QR gösterecek şekilde güncellendi.
- [x] Mobil iptal metni kredi politikasını açıklar; ücretli kart biletlerinde de iptal görünür.
- [x] Firestore kuralları `TicketAudit`, `UserCredit`, `UserCreditEvent` yazımlarını istemciye kapattı.
- [x] Functions bağımlılıkları lockfile’a göre yeniden kuruldu; emulator testlerinde eksik `protobufjs` dosyası giderildi.
- [x] Rezervasyon/iptal/QR testleri: 23/23 geçti.
- [x] Ödeme E2E testleri: 9/9 geçti; yerel sahte iyzico secret’ları yalnız emulator için kullanılıyor.
- [x] Uygulama kredisi ödeme ekranına bağlandı: bakiye transaction içinde ayrılıyor, başarısız/expired ödemede geri bırakılıyor; ödeme hareketi `UserCreditEvent` ile kaydediliyor. Emulator doğrulaması port çakışması nedeniyle bekliyor.
- [ ] Admin QR tarayıcısı yeni payload'ı ayrıştırıp `seatId` ve `qrToken` alanlarını ayrı gönderecek.
- [x] Admin bilet ekranında server-only audit timeline görüntülendi; CSV dışa aktarma hâlâ yapılacak.
- [x] Functions testleri: 3 koltuk / yalnızca 2 check-in, ikinci taramada idempotency ve iptal kredisi idempotency doğrulandı.
- [ ] Eski bilet uyumluluğu için üretimden örnek veriyle migration/read-only doğrulaması yapılacak.
- [ ] App Check enforcement canlıda kademeli açılacak.
- [ ] PITR ve delete protection canlı veritabanında yetkili onayıyla açılacak.
- [ ] Scheduled backup günlük oluşturulacak ve geri yükleme tatbikatı yapılacak.

## PITR ve scheduled backup ne demek?

**PITR (Point-in-Time Recovery)**, yanlışlıkla silinen/değiştirilen Firestore verisini geçmiş bir dakikaya kadar geri alabilme katmanıdır. Şu an kapalı olduğu için yalnızca mevcut veriye veya alınmış harici yedeğe güvenilebilir; geçmişteki bir anlık görüntüye doğrudan dönülemez. Firestore PITR geçmişteki son 7 güne kadar korunmuş sürümleri hedefler ve geri yükleme işlemi ayrı bir veritabanı/iş akışı gerektirebilir.

**Scheduled backup**, veritabanının günlük/haftalık otomatik yedeğidir. Listede görünmemesi, bu projede zamanlanmış Firestore backup schedule tanımlı olmadığını gösterir. PITR ile aynı şey değildir: PITR kısa zaman aralığında hassas geri dönüş, scheduled backup ise daha uzun saklama ve olağanüstü durum arşividir.

Önerilen üretim ayarı: PITR açık + delete protection açık + günlük scheduled backup, en az 14 hafta saklama + ayda bir geri yükleme tatbikatı. Backup ve restore ücretleri/limitleri canlı projeye bağlı olduğundan, bu iki ayar kod deploy’undan ayrı ve proje sahibi onayıyla uygulanmalıdır.

## Sonraki güvenlik sırası

1. Uygulama kredisi harcama transaction’ı ve admin audit ekranı.
2. Admin QR tarayıcı payload geçişi ve emülatör testleri.
3. App Check enforcement için önce gözlem, sonra callable bazında enforcement.
4. Web güvenlik başlıkları, CSP ve ödeme WebView allowlist’i.
5. PITR/delete protection/scheduled backup canlı ayarı ve restore tatbikatı.
