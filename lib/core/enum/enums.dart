enum UserRole {
  admin,
  curator,
  user,
  guest,
  unknown;

  static UserRole fromString(final String? role) =>
      UserRole.values.firstWhere((final e) => e.name == role?.toLowerCase(),
          orElse: () => UserRole.unknown);
}

enum AppThemePreference {
  light, // Gündüz (Sabit Renk)
  dark, // Gece (Sabit Renk)
  system, // Sistem (Sabit Renk - Cihaza uyar)
  monet, // Ahenk / Senin Teman (Dinamik Renk - Cihaza uyar)
}
