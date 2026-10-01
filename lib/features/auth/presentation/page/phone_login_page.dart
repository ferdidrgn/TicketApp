// Koşullu Dışa Aktarma — `login_screen.dart` ile AYNI kalıp/gerekçe.
// `app_router.dart` hâlâ SADECE bu dosyayı import eder ve
// `const PhoneLogInPage()` kurar.
export 'phone_login_page_stub.dart'
    if (dart.library.js) 'phone_login_page_web.dart'
    if (dart.library.io) 'phone_login_page_mobile.dart';
