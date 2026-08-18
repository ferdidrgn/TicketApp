import 'local_storage_service.dart';

/// İlk açılışta gösterilen onboarding akışının bir daha gösterilip
/// gösterilmeyeceğini takip eder. `loadState()` main()'de, runApp'tan
/// ÖNCE await edilir; bu sayede router senkron olarak `hasSeenOnboarding`
/// değerine bakıp ilk ekranı buna göre seçebilir.
abstract final class OnboardingService {
  static const _key = 'has_seen_onboarding_v1';

  /// Güvenli taraf: yükleme tamamlanmadan (teorik olarak) okunursa bile
  /// mevcut kullanıcıyı onboarding'e hapsetmemek için varsayılan true.
  static bool hasSeenOnboarding = true;

  static Future<void> loadState() async {
    final value = await LocalStorageService.readSecureData(_key);
    // Değer hiç yazılmamışsa (ilk kurulum) null döner -> onboarding gösterilir.
    hasSeenOnboarding = value == 'true';
  }

  static Future<void> markSeen() async {
    hasSeenOnboarding = true;
    await LocalStorageService.writeSecureData(_key, 'true');
  }
}
