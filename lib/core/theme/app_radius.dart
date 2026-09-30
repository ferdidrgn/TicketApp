/// Uygulama genelinde kullanılan tek köşe yuvarlaklığı (radius) ölçeği.
///
/// Eskiden burada "imza" asimetrik köşeler (`asymSm`/`asymLg`: iki köşe
/// keskin, iki köşe çok yuvarlak) vardı; sahibi bu "D harfi" şeklini
/// reddetti ve bilet diline geçişte tüm kullanımları kaldırıldı. Yeniden
/// eklenmez (bkz. `.claude/skills/tiyatrol-design/references/history.md`).
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Sohbet balonu / rozet gibi tam yuvarlak (pill) şekiller için.
  static const double pill = 100;
}
