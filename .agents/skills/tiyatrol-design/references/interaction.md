# Etkileşim, eklentiler ve işlemler (Flutter)

Sahibinin isteği (04.10.2026): "interaktif UI'lar, eklentiler, işlemler de
ekleyerek yap". Statik bir ekran — sadece okunan kutular — bu projede
YETERSİZ sayılır. Her yeni ekran ve her yeniden tasarım, kullanıcının
dokunup bir şey YAPABİLDİĞİ, ekranın da ona CEVAP VERDİĞİ en az bir anlamlı
etkileşim içerir. Ama süs değil: her etkileşim gerçek veriye ve gerçek bir
işe bağlanır (bkz. SKILL.md §4 "Hareket azdır ve bilinçlidir").

## 1. Her ekran için kontrol listesi

Tasarım planına (SKILL.md §3) şu satırları ekle:

- **Birincil işlem:** Ekranın tek net aksiyonu ne? (Bilet al, koltuk seç,
  kaydet…) Basınca ne olur, nasıl onaylanır?
- **Doğrudan manipülasyon:** Kullanıcı neyi kaydırabilir, sürükleyebilir,
  büyütebilir, filtreleyebilir? (Afiş vitrini, takvim şeridi, koltuk planı,
  tür seçici.)
- **Anında geri bildirim:** Dokunuşa < 50 ms görsel cevap (InkWell, renk/
  ölçek değişimi) + gerektiğinde `HapticFeedback` (selectionClick /
  lightImpact / mediumImpact).
- **Durumlar:** yükleniyor (skeleton), boş (davet + aksiyon), hata (ne oldu +
  tekrar dene), başarılı (onay anı). Hiçbiri atlanmaz.
- **Kalıcılık:** Kullanıcının seçimi hatırlanıyor mu? (Tema, filtre, son
  aramalar, onboarding → `shared_preferences`.)
- **Geri alma:** Yıkıcı ya da yanlışlıkla yapılabilecek işlemde SnackBar
  "Geri al" ya da onay diyaloğu.

## 2. Etkileşim kalıpları — hangisi nerede

| Kalıp | Ne zaman | Projede örnek / araç |
|---|---|---|
| Otomatik kayan vitrin + ilerlemeli gösterge | Az sayıda öne çıkan içerik (kampanya, oyun) | `HomeSpotlightCarousel` (PageView + dolan nokta, dokununca durur) |
| Yatay şerit + "Tümünü gör" | Aynı türden çok içerik | `HomeRail`, `BrowseRail` |
| Seçici kartlar (chip / tile) → filtreleme | Kullanıcıyı kategoriye yönlendirme | `HomeMoodPicker`, `_GenreTiles`, `BrowseChoiceChips` |
| Canlı önizleme | Ayar seçimi (tema, renk) | onboarding III. perde, `ThemeStylePicker` |
| Kaydırmaya bağlı öğe | Uzun sayfa | `StageScrollTop` (global başa dön), küçülen başlık (`SliverAppBar`) |
| Sürükle / kaydır jesti | Sayfalar arası, kart reddetme | onboarding yatay kaydırma; `Dismissible` (bildirim sil + geri al) |
| Basılı tut | Gizli/ikincil işlem | Ayarlar → sürüm yazısı (admin) |
| Çek-yenile | Liste verisi | `RefreshIndicator` (BasePageWrapper `onRefresh`) |
| Alt sayfa (bottom sheet) | Bağlam kaybetmeden detay/işlem | koltuk bilgisi, paylaş, filtre paneli |
| Kutlama anı | Gerçek bir başarı (bilet alındı, rütbe atlandı) | `confetti`, `TicketInkStamp`, `tossRose` |
| Daktilo / dönen ipucu | Arama alanında ne aranabileceğini göstermek | `RotatingSearchHint` |
| Nabız / canlı nokta | Gerçek zamanlı bilgi ("bu akşam N seans") | `HomeWeekPulse` |

## 3. Projede HAZIR eklentiler (pubspec) — önce bunları kullan

Yeni paket eklemeden önce bunlara bak (ekleme gerekirse `flutter pub get`
sahibine hatırlatılır):

| Paket | Kullanım |
|---|---|
| `confetti` | Gerçek başarı anı (bilet satın alındı, karne rütbesi). Her ekranda değil. |
| `flutter_staggered_animations` | Liste/ızgara ilk girişte sıralı belirme — sayfa başına bir kez. |
| `skeletonizer` / `shimmer` | Yükleniyor durumu (spinner yerine iskelet). |
| `visibility_detector` | Görünür olunca oynat/durdur (vitrin, video, sayaç). |
| `flutter_staggered_grid_view` | Masonry/karışık ızgara (galeri, afiş duvarı). |
| `video_player` / `audioplayers` | Fragman, sahne sesi — kullanıcı başlatır, otomatik sesli oynatma YOK. |
| `qr_flutter` | Bilet QR'ı. |
| `share_plus` | Oyun/bilet/kampanya paylaşma. |
| `url_launcher` | Harici bilet, harita, iletişim. |
| `geolocator` + `google_maps_flutter` | Yakındakiler, sahneye yol tarifi. |
| `pinput` | SMS kodu girişi. |
| `image_picker` / `file_picker` | Profil fotoğrafı, admin görsel yükleme. |
| `shared_preferences` | Kullanıcı tercihi/geçmişi (son aramalar, onboarding). |
| `firebase_messaging` | Seans hatırlatma, yeni seans bildirimi. |
| `firebase_remote_config` | Özelliği uzaktan aç/kapat, metin/kampanya değiştirme. |
| `firebase_analytics` | Etkileşim ölçümü (hangi bölüm tıklanıyor). |
| `HapticFeedback` (Flutter) | Seçim, onay, uyarı dokunuşları. |

## 4. İşlem (aksiyon) akışı kuralları

1. **Basıldı → çalışıyor → sonuç:** Buton basılınca hemen yükleniyor hâline
   geçer (`TicketStampButton(loading:)` ya da buton içi gösterge), çift
   basma engellenir; sonuç SnackBar/diyalog/anlık değişimle bildirilir.
2. **İyimser güncelleme:** Favori, takip, alkış gibi geri alınabilir
   işlemlerde arayüz hemen değişir, hata olursa eski hâline döner ve
   kullanıcıya söylenir (bkz. `ShowFavoriteButton`).
3. **Diyaloglar kendini kapatır:** `CustomSuccessDialog` / `CustomActionDialog`
   kendi `pop`'unu yapar — çağıran yer ikinci kez `pop` ETMEZ (çift pop,
   admin panelini kapatıp ana sayfaya atıyordu).
4. **Gezinme sonrası yer:** Güncellemeden sonra kullanıcı aynı kayıtta
   kalır; oluşturmadan sonra listeye döner.
5. **Uzun işlem:** 1 sn'den uzun sürecekse ilerleme ya da açıklayıcı metin
   ("Biletin basılıyor…"); 10 sn'de zaman aşımı + tekrar dene.
6. **Riverpod family anahtarı:** Widget `build`'inde `fooProvider([id])`
   gibi YENİ liste ile family çağırma — her çizim yeni sorgu başlatır,
   sonsuz yükleme olur. Tek `String` anahtarlı provider kullan
   (örnek: `eventsForShowProvider`).

## 5. Erişilebilirlik ve sınırlar

- Her etkileşimli öğede `Semantics(button: true, label: …)`; ikon-only
  butonda `tooltip`.
- Dokunma alanı ≥ 48dp; jest varsa aynı işin bir buton karşılığı da olur.
- `MediaQuery.disableAnimations` açıksa otomatik kayma/nabız/daktilo durur,
  içerik son hâlinde gösterilir.
- Otomatik oynayan hareket sayfa başına en fazla bir-iki tane; hepsi
  dokununca durur.
- Etkileşim gerçek veriye bağlı değilse (sahte sayı, sahte "canlı" rozet,
  çalışmayan buton) EKLENMEZ.
