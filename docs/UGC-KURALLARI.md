# Kullanıcı içeriği (yorum) — kurallar ve moderasyon (TASLAK)

> Hukuki tavsiye değildir; yayından önce hukukçu kontrolü gerekir. Web metni: `site/topluluk-kurallari.html`.

## Kural özeti
- Yorum yazabilen: telefonu doğrulanmış + o oyunun GEÇMİŞ seansı için geçerli (iptal/gelmedi olmayan) bileti olan kullanıcı. Oyun başına tek yorum.
- Yasak: hakaret/küfür/nefret/tehdit, spam-reklam, bağlantı-telefon-e-posta, başkasının kişisel bilgisi, sahte içerik.
- Her yorumda **şikâyet et** ve **kullanıcıyı engelle** vardır (Google Play / Apple UGC şartı).

## Sistem
- Yazma yalnız callable: `submitReview`, `deleteMyReview`, `canReview` (ön kontrol), `reportContent`, `blockUser`/`unblockUser`. `Review` istemci yazımına kapalıdır.
- Sunucu metin süzgeci: URL/telefon/e-posta REDDEDİLİR; küfür/nefret şüphesi (`functions/src/moderation-words.js`) yorumu `status:'pending'`, `hidden:true` ile admin kuyruğuna düşürür.
- Şikâyet eşiği: 3 FARKLI telefon-doğrulamalı kullanıcı -> `hidden:true, hiddenReason:'reports'`. Moderatör geri açınca sayaç o noktadan yeniden başlar (`reportBaseline`).
- Moderasyon: admin `adminModerate` (gizle/geri aç/sil), ekip yöneticisi `teamModerate` (yalnız kendi oyunları; silme YOK), liste `teamReviews`. Sebep zorunlu; her işlem `ModerationLog`a yazılır (yalnız admin okur).
- Hız sınırı: yorum saatte 5 / günde 20; şikâyet saatte 10 / günde 40. `Show.ratingAvg/ratingCount` yalnız görünür yorumlardan sunucuda hesaplanır.
- Okuma: gizli yorumu yalnız yazarı ve admin görür; herkes için sorgu `where('hidden','==',false)` olmalıdır (eski istemciler kısıtsız sorguda izin hatası alır).
- Henüz yok: soru/cevap türü (`reportContent` yalnız `type:'review'`).

## Hesap silme ile ilişki (docs/HESAP-SILME.md)
Yorum metni/adı silinir ve puan yeniden hesaplanır. İSTİSNA: şikâyete/moderasyona konu olmuş GİZLİ yorum delil olarak, uid içermeyen kimlikle ve ad/foto boş, metin ≤120 karakter anonim saklanır (gizli kalır). Kullanıcının şikâyetleri, engel listesi (`User/{uid}/blocks`), `ReviewLimits` silinir; `ModerationLog`daki uid alanları takma adlanır, metin özeti temizlenir. Başkalarının engel listesindeki bu uid kalıntısı (kişisel veri içermeyen opak kimlik) bilinen sınırdır.
