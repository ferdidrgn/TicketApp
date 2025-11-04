class RoleManager {
  // Role sabitleri
  static const String admin = 'admin';
  static const String user = 'user';
  static const String guest = 'guest';
  static const String premium = 'premium';

  // Login method'a göre varsayılan rol döndür
  static String getDefaultRoleForLoginMethod(String loginMethod) {
    switch (loginMethod.toLowerCase()) {
      case 'google':
      case 'phone':
      case 'email':
        return user;
      case 'anonymous':
        return guest;
      default:
        return guest;
    }
  }

  // Rol kontrolü
  static bool isAdmin(String? role) => role == admin;
  static bool isUser(String? role) => role == user;
  static bool isGuest(String? role) => role == guest;
  static bool isPremium(String? role) => role == premium;

  // Kullanıcı yetkili mi?
  static bool hasPermission(String? role, String requiredRole) {
    if (role == null) return false;

    // Admin her şeyi yapabilir
    if (role == admin) return true;

    // Premium user, user haklarına sahip
    if (role == premium && (requiredRole == user || requiredRole == guest)) {
      return true;
    }

    // User, guest haklarına sahip
    if (role == user && requiredRole == guest) return true;

    // Aynı rol
    return role == requiredRole;
  }

  // Rol yükseltme
  static String upgradeRole(String currentRole) {
    switch (currentRole) {
      case guest:
        return user;
      case user:
        return premium;
      case premium:
        return admin;
      default:
        return currentRole;
    }
  }

  // Kullanıcı dostu rol ismi
  static String getRoleDisplayName(String? role) {
    switch (role) {
      case admin:
        return 'Yönetici';
      case user:
        return 'Kullanıcı';
      case guest:
        return 'Misafir';
      case premium:
        return 'Premium Kullanıcı';
      default:
        return 'Bilinmeyen';
    }
  }
}