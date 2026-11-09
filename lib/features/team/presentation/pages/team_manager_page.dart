import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../data/datasources/team_remote_data_source.dart';
import '../providers/team_providers.dart';
import '../widgets/team_manager_widgets.dart';
import '../widgets/team_notify_tab.dart';
import '../widgets/team_stats_tab.dart';

/// Ekip yöneticisi (TeamManager) mobil ekranı — admin'den AYRI bir rol
/// (`TeamManager/{teamId}_{uid}` belgesi; `User.role` değişmez, bkz.
/// `docs/EKIP-YONETICISI.md`). Bir kullanıcı aynı zamanda app-admin VE/VEYA
/// bir/birden çok ekibin yöneticisi olabilir — bu ekran yalnız SUNUCUNUN
/// (`functions/src/team.js`) kendi yetki/kapsam denetimine güvenir, hiçbir
/// admin-only istemci kapısı (`AdminGuard` vb.) KULLANMAZ: düz ekip
/// yöneticisi (admin yetkisi olmayan) bir hesapta da doğru çalışır.
///
/// Web karşılığı: `/ekip` (`site/js/pages/ekip.js`) — "Bildirim" (sahne
/// kumandası + kısa mesaj) ve "Özet" (satış/doluluk/giriş) sekmeleri bu
/// ekranda aynı callable'larla (`getMyManagedTeams`, `teamNotifyPreview`,
/// `teamSendNotification`, `teamStats`) yeniden üretilir.
///
/// Gerçek navigasyon giriş noktası (bu ekrana nereden gelinecek) AYRICA
/// bağlanacak — bu widget tamamen kendi başına çalışır:
/// `Navigator.push(context, MaterialPageRoute(builder: (_) => const
/// TeamManagerPage()))`.
class TeamManagerPage extends ConsumerWidget {
  const TeamManagerPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final teamsAsync = ref.watch(myManagedTeamsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ekip paneli'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.campaign_rounded), text: 'Bildirim'),
              Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Özet'),
            ],
          ),
        ),
        backgroundColor: context.colors.surface,
        body: teamsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: TeamLoadingSkeleton(rows: 3, rowHeight: 72),
          ),
          error: (final e, final st) => Padding(
            padding: const EdgeInsets.all(24),
            child: TeamInlineBanner(
              message: e is TeamException
                  ? e.message
                  : 'Ekip bilgileri yüklenemedi. Bağlantını kontrol edip '
                      'tekrar dene.',
            ),
          ),
          data: (final teams) {
            if (teams.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: TeamEmptyState(
                  message: 'Bu hesap herhangi bir topluluğun ekip '
                      'yöneticisi olarak atanmamış. Yetki, TiyatRol '
                      'yönetimi tarafından verilir.',
                  icon: Icons.groups_outlined,
                ),
              );
            }
            return TabBarView(
              children: [
                TeamNotifyTab(teams: teams),
                TeamStatsTab(teams: teams),
              ],
            );
          },
        ),
      ),
    );
  }
}
