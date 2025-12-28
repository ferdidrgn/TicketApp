enum UserRole {
  user,
  admin,
  curator,
  guest;

  // String'den Enum'a dönüşüm (Firestore'dan okurken)
  static UserRole fromString(final String role) =>
      UserRole.values.firstWhere((final e) => e.name == role.toLowerCase(),
          orElse: () => UserRole.user);
}
