enum AppLanguage { tr, en }

enum AdUnitType {
  banner, // Mobil Banner
  native, // Mobil Native
  display, // Web Görüntülü
  inArticle, // Web Yazı İçi
  multiplex, // Web Benzer Ürünler Altı
}

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

enum AppThemeStyle {
  appLight, // Sabit TiyatRol Kırmızı/Beyaz (Gündüz)
  appDark, // Sabit TiyatRol Gri/Siyah (Gece)
  system, // Telefon ayarına göre sabit renkler (Oto)
  materialLight, // Duvar kağıdı rengi (Gündüz)
  materialDark, // Duvar kağıdı rengi + ATMOSFERİK MOD (Gece)
}
