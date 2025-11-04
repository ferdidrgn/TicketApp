import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketapp/core/util/role_manager.dart';

class LocalStorageService {
  // Keys
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isGuestKey = 'is_guest';
  static const String _userRoleKey = 'user_role';
  static const String _preferencesKey = 'user_preferences';
  static const String _sessionKey = 'session_data';

  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ✅ GET_USER_DATA METHODU - ROL EKLENDİ
  static Map<String, dynamic>? getUserData() {
    final isLoggedIn = _prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) return null;

    return {
      // Temel bilgiler
      'uid': _prefs.getString('user_uid'),
      'email': _prefs.getString('user_email'),
      'displayName': _prefs.getString('user_display_name'),
      'phoneNumber': _prefs.getString('user_phone'),
      'photoURL': _prefs.getString('user_photo_url'),

      // Rol ve durum bilgileri
      'role': _prefs.getString(_userRoleKey) ?? RoleManager.guest,
      'isGuest': _prefs.getBool(_isGuestKey) ?? true,

      // Zaman bilgileri
      'lastLogin': _prefs.getString('last_login'),

      // Tercihler
      'preferences': getUserPreferences(),
    };
  }

  // ✅ TÜM KULLANICI VERİLERİNİ KAYDET - ROL DESTEKLİ
  static Future<void> saveCompleteUserData({
    required final String uid,
    required final String? email,
    required final String? displayName,
    required final String? phoneNumber,
    required final String? photoURL,
    required final String? userRole,
    required final bool isGuest,
    final Map<String, dynamic>? userPreferences,
  }) async {
    // Temel kullanıcı bilgileri
    await _prefs.setString('user_uid', uid);
    if (email != null) await _prefs.setString('user_email', email);
    if (displayName != null) await _prefs.setString('user_display_name', displayName);
    if (phoneNumber != null) await _prefs.setString('user_phone', phoneNumber);
    if (photoURL != null) await _prefs.setString('user_photo_url', photoURL);

    // Rol ve durum bilgileri
    await _prefs.setString(_userRoleKey, userRole ?? RoleManager.getDefaultRoleForLoginMethod(isGuest ? 'anonymous' : 'user'));
    await _prefs.setBool(_isGuestKey, isGuest);
    await _prefs.setBool(_isLoggedInKey, true);

    // Son giriş tarihi
    await _prefs.setString('last_login', DateTime.now().toIso8601String());

    // Kullanıcı tercihleri
    if (userPreferences != null) {
      await saveUserPreferences(userPreferences);
    }
  }

  // ✅ ROL GÜNCELLE
  static Future<void> updateUserRole(String newRole) async {
    await _prefs.setString(_userRoleKey, newRole);
  }

  // ✅ KULLANICI TERCIHLERINI KAYDET
  static Future<void> saveUserPreferences(final Map<String, dynamic> preferences) async {
    await _prefs.setString(_preferencesKey, jsonEncode(preferences));
  }

  // ✅ KULLANICI TERCIHLERINI GETIR
  static Map<String, dynamic> getUserPreferences() {
    final prefsJson = _prefs.getString(_preferencesKey);
    if (prefsJson == null) return _getDefaultPreferences();

    try {
      return jsonDecode(prefsJson) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultPreferences();
    }
  }

  static Map<String, dynamic> _getDefaultPreferences() {
    return {
      'theme': 'system', // light, dark, system
      'language': 'tr',
      'notifications': true,
      'biometricAuth': false,
      'autoLogin': true,
    };
  }

  // ✅ ÇIKIŞ YAP - TÜM VERİLERİ TEMİZLE
  static Future<void> clearAllUserData() async {
    // Kullanıcı bilgilerini temizle
    await _prefs.remove('user_uid');
    await _prefs.remove('user_email');
    await _prefs.remove('user_display_name');
    await _prefs.remove('user_phone');
    await _prefs.remove('user_photo_url');

    // Rol ve durum bilgilerini temizle
    await _prefs.remove(_userRoleKey);
    await _prefs.setBool(_isLoggedInKey, false);
    await _prefs.setBool(_isGuestKey, false);

    // Session bilgilerini temizle
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('token_expiry');
    await _prefs.remove('last_login');

    // Tercihleri sıfırlama (opsiyonel - isterseniz tercihleri koruyabilirsiniz)
    // await _prefs.remove(_preferencesKey);
  }

  // ✅ GETTER'lar
  static bool get isLoggedIn => _prefs.getBool(_isLoggedInKey) ?? false;
  static String? get userRole => _prefs.getString(_userRoleKey);
  static bool get isGuest => _prefs.getBool(_isGuestKey) ?? true;
  static String? get userUid => _prefs.getString('user_uid');
  static String? get userEmail => _prefs.getString('user_email');
  static String? get displayName => _prefs.getString('user_display_name');
  static String? get phoneNumber => _prefs.getString('user_phone');
  static String? get photoURL => _prefs.getString('user_photo_url');

  // ✅ Rol bazlı getter'lar
  static bool get isAdmin => RoleManager.isAdmin(userRole);
  static bool get isPremium => RoleManager.isPremium(userRole);
  static bool get isRegularUser => RoleManager.isUser(userRole);
  static bool get isGuestUser => RoleManager.isGuest(userRole);
}