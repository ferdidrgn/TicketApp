import '../entities/admin_dashboard_stats.dart';

/// Yönetim paneli "Genel bakış" sekmesinin veri sınırı — tek bir gerçek
/// kaynak: sunucudaki `adminStats` callable'ı (bkz. `functions/src/stats.js`).
/// İstemci Firestore'u DOĞRUDAN okumaz; admin denetimi ve maliyet
/// sınırlaması sunucu tarafında yapılır.
abstract class AdminStatsRepository {
  /// [month]: 'yyyy-MM' biçiminde İstanbul ayı. Sunucu geçersiz bir ay
  /// alırsa `invalid-argument` ile hata fırlatır.
  Future<AdminDashboardStats> fetchStats(final String month);
}
