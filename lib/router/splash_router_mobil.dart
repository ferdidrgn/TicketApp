class SplashRouter {
  const SplashRouter._();

  // ✅ GETTER TANIMLI
  static bool get shouldSkipAuthCheck => false; // Mobil: Auth kontrolünü yap
  static String get initialRoute =>
      '/login'; // Mobil: Kontrol sonrası gideceği rota
}
