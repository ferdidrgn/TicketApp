import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` artık flutter_riverpod'un ana barrel dosyasından değil,
// `legacy.dart`'tan geliyor (flutter_riverpod 3.0.3) — bu projede henüz
// kullanılmıyordu, bu yüzden bu import eksiksiz gerekli.
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/admin_stats_repository_impl.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/repositories/admin_stats_repository.dart';

// Bu dosya KASITLI olarak `@riverpod` kod üretimi KULLANMIYOR — bu sandbox'ta
// `build_runner` çalışmıyor ve bu yeni bir dosya olduğu için bir `.g.dart`
// parçası hiç oluşmayacaktı. Klasik `Provider`/`FutureProvider.family`/
// `StateProvider` (bkz. `show_provider.dart`'taki `eventsByShowIdsProvider`)
// ek kod üretimi gerektirmeden derlenir.

final adminStatsRepositoryProvider =
    Provider<AdminStatsRepository>((final ref) => AdminStatsRepositoryImpl());

/// İstanbul saatine göre (sabit UTC+3 — Türkiye'de yaz saati uygulaması
/// 2016'dan beri yok; `functions/src/config.js`'teki `TZ_OFFSET_MIN` ile
/// aynı kabul) şu anki ay, 'yyyy-MM' biçiminde.
String currentIstanbulMonthKey() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 3));
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
}

/// Ay seçicide gösterilecek son 12 ay (bu ay dahil, en yeniden en eskiye).
List<String> lastTwelveMonthKeys() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 3));
  return List.generate(12, (final i) {
    final d = DateTime.utc(now.year, now.month - i, 1);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}';
  });
}

/// Seçili ay — kullanıcı ay seçiciden değiştirdikçe güncellenir.
final adminDashboardSelectedMonthProvider =
    StateProvider<String>((final ref) => currentIstanbulMonthKey());

/// Aylık trend grafiğinde "Tüm içerik" (null) ya da tek bir oyunla
/// filtreleme seçimi.
final adminDashboardSelectedShowProvider =
    StateProvider<String?>((final ref) => null);

/// Seçili aya ait tüm dashboard verisi — `adminStats` callable'ının tek
/// girişi. Web paneliyle aynı 2 dakikalık önbellek davranışını Riverpod'un
/// kendi `FutureProvider` önbelleğine bırakıyoruz (aynı ay tekrar
/// izlendiğinde yeniden sorgu atmaz; `ref.invalidate` ile zorla yenilenir).
final adminDashboardStatsProvider =
    FutureProvider.family<AdminDashboardStats, String>(
        (final ref, final month) =>
            ref.watch(adminStatsRepositoryProvider).fetchStats(month));
