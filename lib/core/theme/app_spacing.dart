/// Uygulama genelinde kullanılan tek boşluk (spacing) ölçeği.
///
/// Kod tabanında `EdgeInsets`/`SizedBox` için 300'den fazla ham sayı
/// literal'i vardı (24, 20, 16, 12, 8... hepsi elle, tekrar tekrar
/// yazılmış). Buradaki değerler o mevcut kullanımdan (en sık geçen
/// rakamlardan) türetildi — yeni bir ölçek icat edilmedi, zaten var olan
/// düzen isimlendirildi. Yeni kod bu sabitleri kullanmalı; eski kod
/// dokunulmadıkça bozulmaz, sabitler sadece EKLENDİ.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double section = 64;
}
