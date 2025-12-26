import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 Merkezi Local Storage Servisi
class LocalStorageService {
  static SharedPreferences? _prefs;

  // Storage Keys
  static const String _keyUserId = 'user_id';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyEmail = 'user_email';
  static const String _keyPhotoUrl = 'user_photo_url';
  static const String _keyRole = 'user_role';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsGuest = 'is_guest';

  /// Initialize SharedPreferences
  static Future<void> init() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Ensure initialization
  static Future<void> _ensureInitialized() async {
    if (_prefs == null) await init();
  }

  // ========================================
  // SAVE OPERATIONS
  // ========================================

  /// 💾 Save complete user data
  static Future<bool> saveUserData({
    required final String userId,
    required final String displayName,
    required final String email,
    required final String photoUrl,
    required final String role,
    required final bool isGuest,
  }) async {
    await _ensureInitialized();
    try {
      await Future.wait([
        _prefs!.setString(_keyUserId, userId),
        _prefs!.setString(_keyDisplayName, displayName),
        _prefs!.setString(_keyEmail, email),
        _prefs!.setString(_keyPhotoUrl, photoUrl),
        _prefs!.setString(_keyRole, role),
        _prefs!.setBool(_keyIsLoggedIn, true),
        _prefs!.setBool(_keyIsGuest, isGuest),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 💾 En temel kullanıcı verilerini yerel hafızaya kaydeder
  static Future<bool> saveEssentialUserData({
    required final String uid,
    final String? displayName,
    final String? role,
    final String? photoUrl,
  }) async {
    await _ensureInitialized();
    try {
      await Future.wait([
        _prefs!.setString(_keyUserId, uid),
        if (displayName != null)
          _prefs!.setString(_keyDisplayName, displayName),
        if (role != null) _prefs!.setString(_keyRole, role),
        if (photoUrl != null)
          _prefs!.setString(_keyPhotoUrl, photoUrl),
        _prefs!.setBool(_keyIsLoggedIn, true),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // GET OPERATIONS
  // ========================================

  /// 📖 Get user ID
  static String? get userId => _prefs?.getString(_keyUserId);

  /// 📖 Get display name
  static String? get displayName => _prefs?.getString(_keyDisplayName);

  /// 📖 Get email
  static String? get email => _prefs?.getString(_keyEmail);

  /// 📖 Get photo URL
  static String? get photoUrl => _prefs?.getString(_keyPhotoUrl);

  /// 📖 Get user role
  static String? get userRole => _prefs?.getString(_keyRole);

  /// 📖 Check if logged in
  static bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  /// 📖 Check if guest
  static bool get isGuest => _prefs?.getBool(_keyIsGuest) ?? false;

  /// 📖 Get all user data as Map
  static Map<String, dynamic> getUserData() => {
        'userId': userId,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'role': userRole,
        'isLoggedIn': isLoggedIn,
        'isGuest': isGuest,
      };

  /// 📖 Get essential user data
  static Map<String, dynamic>? getEssentialUserData() {
    final uid = userId;
    if (uid == null) return null;

    return {
      'userId': uid,
      'displayName': displayName ?? 'User',
      'email': email ?? '',
      'photoURL': photoUrl ?? '',
      'role': userRole ?? 'user',
    };
  }

  // ========================================
  // DELETE OPERATIONS
  // ========================================

  /// 🗑️ Clear all user data
  static Future<bool> clearAllUserData() async {
    await _ensureInitialized();
    try {
      await Future.wait([
        _prefs!.remove(_keyUserId),
        _prefs!.remove(_keyDisplayName),
        _prefs!.remove(_keyEmail),
        _prefs!.remove(_keyPhotoUrl),
        _prefs!.remove(_keyRole),
        _prefs!.remove(_keyIsLoggedIn),
        _prefs!.remove(_keyIsGuest),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🗑️ Clear specific key
  static Future<bool> clearKey(final String key) async {
    await _ensureInitialized();
    try {
      await _prefs!.remove(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🗑️ Clear all storage
  static Future<bool> clearAll() async {
    await _ensureInitialized();
    try {
      await _prefs!.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // UTILITY
  // ========================================

  /// Check if user data exists
  static bool get hasUserData => userId != null && isLoggedIn;

  /// Get login method from providers    // This should be saved during login
  static String getLoginMethod() =>
      _prefs?.getString('login_method') ?? 'unknown';

  /// Save login method
  static Future<void> saveLoginMethod(final String method) async {
    await _ensureInitialized();
    await _prefs!.setString('login_method', method);
  }
}
