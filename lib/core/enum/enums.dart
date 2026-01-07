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

enum WebSection {
  home,
  shows,
  artistic,
  about,
  team,
  contact,
}
