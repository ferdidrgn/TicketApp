# Reklam politikası ve geçersiz trafik önlemleri

Yayıncı kodu: `pub-5779807348211992`. Kasım 2026'da Google "geçersiz trafik" gerekçesiyle hesabı **29 gün** askıya aldı (itiraz yok, süre bitince reklamlar otomatik yeniden açılır). Google, kaynağı (hangi uygulama/sayfa/kullanıcı) paylaşmıyor. Aşağıdaki "olası kaynaklar" **tahmindir**, kanıtlı değildir.

## 1. Kodda bulduklarımız (kanıtlı)
| Bulgu | Durum |
|---|---|
| Yeni web sitesi (`site/`) hiçbir reklam betiği içermiyor; canlıdaki 9 sayfa kontrol edildi | Temiz |
| Mobil uygulamada reklam bileşenleri (`AdBannerWidget`, `AdNativeWidget`) hiçbir ekranda kullanılmıyor, yalnız AdMob başlatılıyordu | Şu an reklam gösterilmiyor |
| Reklam açma/kapama anahtarı yalnız **görüntüyü gizliyordu**, bileşenler `initState`'te yine **reklam isteği** atıyordu | Düzeltildi |
| Yalnız `kDebugMode` test birimi kullanıyordu: kendi telefonuna kurduğun **release/profile** derlemeler **gerçek** reklamları gösteriyordu (kendi reklamını görme/tıklama riski) | Düzeltildi |
| iOS birim kimlikleri yer tutucuydu (`IOS_BANNER_ID`), geçersiz istek atıyordu | Düzeltildi |
| Eski Flutter web (`web/index.html`) AdSense betiği içeriyordu; eski site yayındayken her ziyaret reklam yüklüyordu | Betik kapatıldı; Flutter web zaten yayında değil |

## 2. Olası kaynaklar (tahmin, önem sırasıyla)
1. **Kendi ve test cihazlarının gerçek reklamlarla kullanılması** (Play'deki sürümü ya da kendi derlemelerini çok sayıda açma/yenileme, kazara tıklama).
2. **Eski web sitesi** (Flutter web + AdSense) üzerindeki çok sayıda test ziyareti, yenileme, otomatik test/tarayıcı trafiği.
3. Eski mobil sürümlerin (`1.0.0` / "verison 1.2") reklam yerleşimleri, kazara tıklamaya yol açan konumlar.
4. Bot/otomatik trafik (tarama, hız testi).
**Kesin neden için AdMob/AdSense konsolundaki "Politika merkezi" ve "Geçersiz trafik" raporlarına bak (bölüm 5).**

## 3. Uygulanan önlemler (kod)
- **Varsayılan KAPALI:** `adsEnabled` Remote Config varsayılanı `false`. Konsoldan açılana ya da Remote Config okunamazsa **hiç reklam gösterilmez**.
- **İstek atmadan önce kontrol:** `AdManager.canServe(tür)`: kapalıysa ya da birim kimliği geçersizse **hiç reklam isteği atılmaz**.
- **Gerçek birimler yalnız mağaza derlemesinde:** CI release işi `--dart-define=ADS_PROD=true` verir. Debug/profile/yerel release derlemeler Google **test** reklamlarını kullanır.
- **Test cihazı kaydı:** `--dart-define=ADMOB_TEST_DEVICES=KIMLIK1,KIMLIK2` ile test cihazları AdMob'a bildirilir (gerçek birimle bile test reklamı görünür).
- **Hassas ekranlarda reklam yasak:** bilet/koltuk/ödeme (`purchase`, `seat`), giriş (`auth`), ayarlar, biletlerim. Otomatik test (`test/ads/ad_policy_test.dart`) bu dizinlerde reklam bileşeni görürse **kırılır**.
- **Web:** yeni sitede reklam yok; eski Flutter web'in AdSense betiği kapatıldı (testle de korunuyor).

## 4. Reklam yeniden açılırken uyulacak kurallar (Google program politikaları özeti)
1. **Kendi reklamına tıklama, yenileme, "tıklayın" gibi yönlendirme YOK.** Sahibi ve ekip kendi cihazında yalnız test reklamlarıyla çalışır.
2. Reklamı **düğmelerin, bilet/ödeme/giriş akışlarının yakınına** koyma; kazara tıklama oluşturan yerleşim yok. Reklamla içerik/düğme arasında net boşluk bırak.
3. **Otomatik yenileme** kullanma ya da en az 60 sn; açılışta ve sayfa geçişlerinde tam ekran reklam gösterme.
4. Reklamı **ödül/teşvikle** tıklatma yok ("destek olmak için reklama tıkla" gibi mesaj yok).
5. **İç trafik ve botlar:** yönetici/ekip yöneticisi hesaplarında, yönetim/ekip sayfalarında, yerel/geliştirme ortamında, otomasyon tarayıcılarında reklam yok.
6. Yeni reklam yerleşimi eklemeden önce **Reklam Denetçisi (Ad Inspector)** ile doğrula.
7. Web'e AdSense eklenirse: yalnız halka açık içerik sayfalarında (oyun, keşfet, rehber), `localhost`/`navigator.webdriver`/yönetim/koltuk/ödeme sayfalarında YOK; çerez/izin yönetimi (CMP) ve `ads.txt` doğru olmalı.

## 5. Sahibin yapacakları (bende yetki yok)
1. **Firebase Console → Remote Config:** `adsEnabled` parametresini `false` yap ve yayınla (askıya alma süresince ve inceleme bitene kadar kapalı kalsın). (Kodun varsayılanı zaten kapalı; bu, eski sürümler için de kapatır.)
2. **AdMob konsolu → Politika merkezi / Geçersiz trafik:** hangi uygulamanın/birimin etkilendiğine bak. **AdMob → Uygulamalar:** hangi uygulama ve hangi birim son 30 günde en çok istek/tıklama almış, kendi cihazlarından gelmiş olabilir mi kontrol et.
3. **AdSense konsolu (varsa):** Siteler listesinde eski Flutter web siteleri (`tiyatrol.web.app`, `ticketappflutter.web.app`, `tiyatroekip.web.app`) var mı bak; kullanılmayan siteleri kaldır, yalnız gerçekten reklam göstereceklerini bırak.
4. **Test cihazlarını kaydet:** kendi Android telefonunda uygulamayı debug/release açıp `adb logcat | findstr "Use RequestConfiguration"` (ya da Android Studio Logcat) çıktısındaki cihaz kimliğini al, `--dart-define=ADMOB_TEST_DEVICES=...` ile derle. Ayrıca AdMob → Ayarlar → Test cihazları bölümüne ekle.
5. **Play'e yüklenecek paket** (1.0.10+29 ve sonrası) mağaza derlemesi olarak CI'dan gelmeli (`ADS_PROD=true` oraya gömülü); kendi bilgisayarında `flutter build --release` ile aldığın paketi mağazaya yükleme.
6. 29 gün sonra reklamları açmadan önce: bölüm 4'ü kontrol et, **önce Remote Config'te yalnız kendi test cihazında** aç, Reklam Denetçisi ile bak, sonra herkese aç.
7. Eski `ca-app-pub-...` iOS birimleri için gerçek kimlikleri (AdMob'da iOS uygulaması açılınca) `ads_manager.dart`'a yaz; o zamana kadar iOS'ta reklam isteği atılmaz.

## 6. Test
`flutter test test/ads/ad_policy_test.dart` (11 test): test birimleri, geçersiz kimlik reddi, varsayılan kapalı, kapalıyken istek yok, hassas dizinlerde reklam bileşeni yok, `web/index.html`'de AdSense betiği yok.
Web: canlı sitede 9 sayfa ve kaynak kod `adsbygoogle`/`googlesyndication`/`pagead`/`doubleclick` için tarandı, bulgu yok.
