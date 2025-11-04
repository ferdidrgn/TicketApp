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
    //if (role == user && requiredRole == guest) return true;

    // Aynı rol
    return role == requiredRole;
  }

  // Özellik bazlı yetkiler
  static bool canEditProfile(String? role) {
    return hasPermission(role, user); // user ve üzeri
  }

  static bool canPurchaseTickets(String? role) {
    return hasPermission(role, user); // user ve üzeri
  }

  static bool canAccessAdminPanel(String? role) {
    return isAdmin(role);
  }

  static bool canAccessPremiumFeatures(String? role) {
    return hasPermission(role, premium); // premium ve admin
  }

  static bool canDeleteAccount(String? role) {
    return hasPermission(role, user); // user ve üzeri
  }

  static bool canChangePassword(String? role) {
    return hasPermission(role, user); // user ve üzeri
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

  // Rol düşürme
  static String downgradeRole(String currentRole) {
    switch (currentRole) {
      case admin:
        return premium;
      case premium:
        return user;
      case user:
        return guest;
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

  // Rol rengi (UI için)
  static String getRoleColor(String? role) {
    switch (role) {
      case admin:
        return '#EF4444'; // Kırmızı
      case premium:
        return '#F59E0B'; // Turuncu
      case user:
        return '#10B981'; // Yeşil
      case guest:
        return '#6B7280'; // Gri
      default:
        return '#9CA3AF'; // Açık gri
    }
  }

  // Rol ikonu (UI için)
  static String getRoleIcon(String? role) {
    switch (role) {
      case admin:
        return '👑';
      case premium:
        return '⭐';
      case user:
        return '👤';
      case guest:
        return '🚶';
      default:
        return '❓';
    }
  }
}

// Extension metodlar - Kullanımı kolaylaştırır
extension RoleExtension on String? {
  bool get isAdmin => RoleManager.isAdmin(this);
  bool get isUser => RoleManager.isUser(this);
  bool get isGuest => RoleManager.isGuest(this);
  bool get isPremium => RoleManager.isPremium(this);

  bool get canEditProfile => RoleManager.canEditProfile(this);
  bool get canPurchaseTickets => RoleManager.canPurchaseTickets(this);
  bool get canAccessAdminPanel => RoleManager.canAccessAdminPanel(this);
  bool get canAccessPremiumFeatures => RoleManager.canAccessPremiumFeatures(this);
  bool get canDeleteAccount => RoleManager.canDeleteAccount(this);
  bool get canChangePassword => RoleManager.canChangePassword(this);

  String get displayName => RoleManager.getRoleDisplayName(this);
  String get roleColor => RoleManager.getRoleColor(this);
  String get roleIcon => RoleManager.getRoleIcon(this);

  String get upgraded => RoleManager.upgradeRole(this ?? RoleManager.guest);
  String get downgraded => RoleManager.downgradeRole(this ?? RoleManager.guest);
}