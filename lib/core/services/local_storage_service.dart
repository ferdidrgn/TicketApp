import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../enum/enums.dart';

class LocalStorageService {
  // 🔐 Secure Storage instance'ı oluşturulur
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Storage Keys
  static const String _keyUserId = 'user_id';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyEmail = 'user_email';
  static const String _keyPhotoUrl = 'user_photo_url';
  static const String _keyRole = 'user_role';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsGuest = 'is_guest';

  // ========================================
  // SAVE OPERATIONS (Şifreli Kayıt)
  // ========================================

  static Future<bool> saveUserData({
    required final String userId,
    required final String displayName,
    required final String email,
    required final String photoUrl,
    required final UserRole role,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyUserId, value: userId),
        _storage.write(key: _keyDisplayName, value: displayName),
        _storage.write(key: _keyEmail, value: email),
        _storage.write(key: _keyPhotoUrl, value: photoUrl),
        _storage.write(key: _keyRole, value: role.name),
        _storage.write(key: _keyIsLoggedIn, value: 'true'),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> saveEssentialUserData({
    required final String uid,
    final String? displayName,
    final UserRole? role,
    final String? photoUrl,
  }) async {
    try {
      await _storage.write(key: _keyUserId, value: uid);
      if (displayName != null)
        await _storage.write(key: _keyDisplayName, value: displayName);
      if (role != null) await _storage.write(key: _keyRole, value: role.name);
      if (photoUrl != null)
        await _storage.write(key: _keyPhotoUrl, value: photoUrl);
      await _storage.write(key: _keyIsLoggedIn, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // GET OPERATIONS (Secure Storage Asenkrondur)
  // ========================================

  /// Genel okuma metodu (Theme vb. için)
  static Future<String?> readSecureData(final String key) async =>
      await _storage.read(key: key);

  /// Genel yazma metodu
  static Future<void> writeSecureData(
          final String key, final String value) async =>
      await _storage.write(key: key, value: value);

  static Future<String?> get userId async =>
      await _storage.read(key: _keyUserId);

  static Future<String?> get displayName async =>
      await _storage.read(key: _keyDisplayName);

  static Future<String?> get email async => await _storage.read(key: _keyEmail);

  static Future<String?> get photoUrl async =>
      await _storage.read(key: _keyPhotoUrl);

  /// 📖 Rolü Enum olarak güvenli bir şekilde döner
  static Future<UserRole> get userRole async {
    final roleStr = await _storage.read(key: _keyRole);
    return UserRole.fromString(roleStr);
  }

  static Future<bool> get isLoggedIn async {
    final val = await _storage.read(key: _keyIsLoggedIn);
    return val == 'true';
  }

  static Future<bool> get isGuest async {
    final val = await _storage.read(key: _keyIsGuest);
    return val == 'true';
  }

  static Future<Map<String, dynamic>> getUserData() async => {
        'userId': await userId,
        'displayName': await displayName,
        'email': await email,
        'photoUrl': await photoUrl,
        'role': (await userRole).name,
        'isLoggedIn': await isLoggedIn,
        'isGuest': await isGuest,
      };

  // ========================================
  // DELETE OPERATIONS
  // ========================================

  static Future<void> clearAllUserData() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyDisplayName);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPhotoUrl);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyIsLoggedIn);
    await _storage.delete(key: _keyIsGuest);
  }

  static Future<void> clearKey(final String key) async =>
      await _storage.delete(key: key);

  static Future<void> clearAll() async => await _storage.deleteAll();

  // ========================================
  // UTILITY
  // ========================================

  static Future<bool> get hasUserData async {
    final uid = await userId;
    final loggedIn = await isLoggedIn;
    return uid != null && loggedIn;
  }

  static Future<void> saveLoginMethod(final String method) async {
    await _storage.write(key: 'login_method', value: method);
  }

  static Future<String> getLoginMethod() async =>
      await _storage.read(key: 'login_method') ?? 'unknown';
}
