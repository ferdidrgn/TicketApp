// Koşullu Dışa Aktarma: Derleyici, çalıştığı platforma göre
// bu üç dosyadan sadece birini dışa (export) aktaracaktır.

export '../../../../../features/home/presentation/pages/wrapper/app_home_page_stub.dart'
    if (dart.library.js) 'app_home_page_web.dart' // Web için derleniyorsa, bu dosyayı kullan.
    if (dart.library.io) 'app_home_page_mobil.dart'; // Mobil için derleniyorsa, bu dosyayı kullan.
