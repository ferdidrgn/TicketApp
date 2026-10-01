// Koşullu Dışa Aktarma: `home_page.dart`/`show_detail_page.dart` ile AYNI
// kalıp — derleyici çalıştığı platforma göre bu üç dosyadan sadece birini
// dışa aktarır. `app_router.dart` hâlâ SADECE bu dosyayı import eder ve
// `const LoginScreen()` kurar; üç dosya da AYNI public API'yi (const
// constructor, `LoginScreen` sınıf adı) koruduğu için router HİÇ
// değişmedi.
//
// KÖK NEDEN (bu bölünmenin sebebi): `login_screen.dart` daha önce tek bir
// mobil-şekilli layout'tu, web derlemesinde de aynen (büyütülmüş) servis
// ediliyordu — CLAUDE.md'nin açıkça yasakladığı "mobile'ı büyütüp web diye
// sunma" anti-deseni. Artık `home_page_mobile.dart`/`home_page_web.dart`
// ile birebir aynı gerçek platform ayrımı var.
export 'login_screen_stub.dart'
    if (dart.library.js) 'login_screen_web.dart'
    if (dart.library.io) 'login_screen_mobile.dart';
