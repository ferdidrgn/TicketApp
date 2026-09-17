// Koşullu Dışa Aktarma: Derleyici, çalıştığı platforma göre
// bu üç dosyadan sadece birini dışa (export) aktaracaktır.
//
// `show_detail_page.dart` ile aynı kalıp: web derlemesinde masaüstüne özel
// `home_page_web.dart`, mobil derlemede ise mevcut (değiştirilmemiş)
// `home_page_mobile.dart` kullanılır.
export 'home_page_stub.dart'
    if (dart.library.js) 'home_page_web.dart' // Web için derleniyorsa, bu dosyayı kullan.
    if (dart.library.io) 'home_page_mobile.dart'; // Mobil için derleniyorsa, bu dosyayı kullan.
