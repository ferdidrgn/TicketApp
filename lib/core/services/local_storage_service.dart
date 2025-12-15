import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _userUidKey = 'user_uid';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';

  // ⚠️ DÜZELTME 1: 'late' kaldırıldı, nullable yapıldı.
  // Böylece başlatılıp başlatılmadığını kontrol edebiliriz.
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    // ⚠️ DÜZELTME 2: Eğer zaten yüklendiyse tekrar yükleme, direkt çık.
    // Bu satır 'LateInitializationError' hatasını engeller.
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    print("✅ LocalStorageService initialized");
  }

  // ✅ SADECE GEREKLİ BİLGİLERİ KAYDET
  static Future<void> saveEssentialUserData({
    required final String uid,
    required final String? displayName,
    required final String? role,
  }) async {
    // _prefs? kullanarak null güvenliği sağlıyoruz
    await _prefs?.setString(_userUidKey, uid);

    if (displayName != null)
      await _prefs?.setString(_userDisplayNameKey, displayName);

    if (role != null)
      await _prefs?.setString(_userRoleKey, role);

    await _prefs?.setBool(_isLoggedInKey, true);
  }

  // ✅ SADECE GEREKLİ BİLGİLERİ GETİR
  static Map<String, dynamic>? getEssentialUserData() {
    final isLoggedIn = _prefs?.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) return null;

    return {
      'uid': _prefs?.getString(_userUidKey),
      'displayName': _prefs?.getString(_userDisplayNameKey),
      'role': _prefs?.getString(_userRoleKey),
    };
  }

  // ✅ TÜM VERİLERİ TEMİZLE
  static Future<void> clearAllUserData() async {
    await _prefs?.remove(_userUidKey);
    await _prefs?.remove(_userDisplayNameKey);
    await _prefs?.remove(_userRoleKey);
    await _prefs?.setBool(_isLoggedInKey, false);
  }

  // ✅ GETTER'lar
  // Eğer _prefs null ise (init çalışmadıysa) varsayılan değerler döner, çökmez.
  static bool get isLoggedIn => _prefs?.getBool(_isLoggedInKey) ?? false;

  static String? get userUid => _prefs?.getString(_userUidKey);

  static String? get userDisplayName => _prefs?.getString(_userDisplayNameKey);

  static String? get userRole => _prefs?.getString(_userRoleKey);
}
