class RoleManager {
  // Role sabitleri
  static const String admin = 'admin';
  static const String user = 'users';
  static const String guest = 'guest';
  static const String premium = 'premium';

  // Login method'a göre varsayılan rol döndür
  static String getDefaultRoleForLoginMethod(final String loginMethod) {
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
  static bool isAdmin(final String? role) => role == admin;

  static bool isUser(final String? role) => role == user;

  static bool isGuest(final String? role) => role == guest;

  static bool isPremium(final String? role) => role == premium;

  // Kullanıcı yetkili mi?
  static bool hasPermission(final String? role, final String requiredRole) {
    if (role == null) return false;

    // Admin her şeyi yapabilir
    if (role == admin) return true;

    // Premium users, users haklarına sahip
    if (role == premium && (requiredRole == user || requiredRole == guest))
      return true;

    // User, guest haklarına sahip
    //if (role == users && requiredRole == guest) return true;

    // Aynı rol
    return role == requiredRole;
  }

  // Özellik bazlı yetkiler
  static bool canEditProfile(final String? role) =>
      hasPermission(role, user); // users ve üzeri

  static bool canPurchaseTickets(final String? role) =>
      hasPermission(role, user); // users ve üzeri

  static bool canAccessAdminPanel(final String? role) => isAdmin(role);

  static bool canAccessPremiumFeatures(final String? role) =>
      hasPermission(role, premium); // premium ve admin

  static bool canDeleteAccount(final String? role) =>
      hasPermission(role, user); // users ve üzeri

  static bool canChangePassword(final String? role) =>
      hasPermission(role, user); // users ve üzeri

  // Rol yükseltme
  static String upgradeRole(final String currentRole) {
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
  static String downgradeRole(final String currentRole) {
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
  static String getRoleDisplayName(final String? role) {
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
  static String getRoleColor(final String? role) {
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
  static String getRoleIcon(final String? role) {
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

  bool get canAccessPremiumFeatures =>
      RoleManager.canAccessPremiumFeatures(this);

  bool get canDeleteAccount => RoleManager.canDeleteAccount(this);

  bool get canChangePassword => RoleManager.canChangePassword(this);

  String get displayName => RoleManager.getRoleDisplayName(this);

  String get roleColor => RoleManager.getRoleColor(this);

  String get roleIcon => RoleManager.getRoleIcon(this);

  String get upgraded => RoleManager.upgradeRole(this ?? RoleManager.guest);

  String get downgraded => RoleManager.downgradeRole(this ?? RoleManager.guest);
}
