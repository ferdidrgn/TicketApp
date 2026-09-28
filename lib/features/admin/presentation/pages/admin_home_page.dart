import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/admin_guard.dart';
import '../widgets/admin_players_tab.dart';
import '../widgets/admin_shows_tab.dart';
import '../widgets/admin_stages_tab.dart';
import '../widgets/admin_teams_tab.dart';

/// Admin panelinin tek giriş noktası ("Sahne Arkası" konseptinin ötesinde,
/// bilinçli olarak sade/işlevsel bir iç araç — bkz. CLAUDE.md: internal bir
/// panel için "Perde açıldı" görsel dili gerekmiyor, ama renk/token
/// kuralları tam uygulanıyor).
///
/// `AdminGuard` ile sarmalanır — gerçek güvenlik sınırı zaten
/// Firestore `isAdmin()` kuralları + bu widget'tır (bkz. `admin_guard.dart`,
/// `isUserPrivilegedProvider`). Basit iç navigasyon: her sekme kendi gerçek
/// veri kaynağına bağlı bağımsız bir widget.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(final BuildContext context) => AdminGuard(
        child: DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sahne Arkası — Yönetim'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.theater_comedy_rounded), text: 'Oyunlar'),
                  Tab(icon: Icon(Icons.location_city_rounded), text: 'Sahneler'),
                  Tab(icon: Icon(Icons.groups_rounded), text: 'Topluluklar'),
                  Tab(icon: Icon(Icons.person_rounded), text: 'Oyuncular'),
                ],
              ),
            ),
            backgroundColor: context.colors.surface,
            body: const TabBarView(
              children: [
                AdminShowsTab(),
                AdminStagesTab(),
                AdminTeamsTab(),
                AdminPlayersTab(),
              ],
            ),
          ),
        ),
      );
}
