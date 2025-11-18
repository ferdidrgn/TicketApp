class SplashRouter {
  const SplashRouter._();

  // ✅ HATA MESAJINDA İSTEDİĞİNİZ GETTER
  static bool get shouldSkipAuthCheck => true; // Web: Auth kontrolünü atla
  static String get initialRoute => '/home';
}
