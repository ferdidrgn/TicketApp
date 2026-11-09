import 'package:cloud_functions/cloud_functions.dart';
import '../../../purchase/data/datasources/purchase_remote_data_source_and_impl.dart'
    show kPurchaseFunctionsRegion;
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/repositories/admin_stats_repository.dart';

/// `AdminStatsRepository`'nin gerçek uygulaması — var olan diğer admin/satın
/// alma callable'larıyla AYNI bölge ve çağrı biçimini kullanır (bkz.
/// `EventRemoteDataSourceImpl.grantFreeSeat`,
/// `PurchaseRemoteDataSourceImpl`): `FirebaseFunctions.instanceFor(region:
/// kPurchaseFunctionsRegion).httpsCallable(...)`. Admin denetimi sunucuda
/// (`assertAdmin`) yapılır; burada ekstra bir yetki kontrolüne gerek yoktur.
class AdminStatsRepositoryImpl implements AdminStatsRepository {
  @override
  Future<AdminDashboardStats> fetchStats(final String month) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
              region: kPurchaseFunctionsRegion)
          .httpsCallable('adminStats');
      // Jenerik tip verilmiyor: dönen gerçek değer çalışma zamanında
      // `Map<Object?, Object?>` olabiliyor (platform kanalından/JS
      // interop'tan geldiği için) — `Map<String, dynamic>` ile sabitlemek
      // derleme zamanında hep "true" sayılan anlamsız bir `is` kontrolüne
      // yol açıyordu. Gerçek dönüşüm `AdminDashboardStats.fromJson`
      // içindeki yardımcılarda (herhangi bir `Map` alt tipini kabul eder).
      final res = await callable.call({'month': month});
      final data = res.data;
      if (data is! Map) {
        throw Exception('Sunucudan geçersiz yanıt alındı.');
      }
      return AdminDashboardStats.fromJson(
          data.map((final k, final v) => MapEntry(k.toString(), v)));
    } on FirebaseFunctionsException catch (e) {
      final msg = (e.message ?? '').trim();
      throw Exception(msg.isNotEmpty && msg.length <= 240
          ? msg
          : switch (e.code) {
              'permission-denied' => 'Bu işlem için yetkin yok.',
              'invalid-argument' => 'Geçersiz ay bilgisi.',
              _ => 'İstatistikler şu anda alınamadı. Lütfen tekrar dene.',
            });
    }
  }
}
