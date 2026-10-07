import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../widgets/favorite_collections.dart';
import '../widgets/web/favorites_desktop_view.dart';

/// FAVORİLER — kullanıcının kenara ayırdığı oyunlar, sahneler, sanatçılar.
///
/// - Masaüstü (≥1024): `FavoritesDesktopPage` — solda tür seçici kenar
///   çubuğu, sağda seçili türün içeriği.
/// - Tablet (768–1023): üç sekme; oyunlar bilet koçanlı kart ızgarası,
///   sahne/sanatçılar iki sütunlu satırlar.
/// - Mobil (<768): üç sekme; oyunlar kompakt bilet satırları
///   (`ShowTicketRow`), sahne/sanatçılar sade liste.
///
/// Sabit görüntü alanlı bir sayfa: her sekme kendi içinde kayar, Footer yok.
/// Veri: `userProfileProvider` → `User.favorite*` ID listeleri (bkz.
/// `favorite_collections.dart`).
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: FavoriteKind.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (context.isDesktop) return const FavoritesDesktopPage();

    final bool tablet = context.isTablet;
    final FavoriteLayout layout =
        tablet ? FavoriteLayout.tablet : FavoriteLayout.mobile;
    final double gutter = tablet ? AppSpacing.xxxl : AppSpacing.lg;
    final EdgeInsets listPadding =
        EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 120);

    return BasePageWrapper(
      title: 'Favorilerim',
      showBackButton: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: tablet ? 960 : double.infinity),
          child: Consumer(
            builder: (final context, final ref, final _) {
              final userAsync = ref.watch(userProfileProvider);
              final user = userAsync.value;

              final Widget body;
              if (userAsync.isLoading && !userAsync.hasValue) {
                // Profil gelene kadar oyun sekmesinin şeklinde iskelet.
                body = FavoriteSkeletonView(
                    layout: layout, padding: listPadding);
              } else if (userAsync.hasError && !userAsync.hasValue) {
                body = _Centered(
                  child: FavoriteErrorNotice(
                    onRetry: () => ref.invalidate(userProfileProvider),
                  ),
                );
              } else if (user == null) {
                body = const _Centered(child: FavoriteSignInNotice());
              } else {
                final Map<FavoriteKind, List<String>> ids = {
                  FavoriteKind.shows: user.favoriteShows,
                  FavoriteKind.stages: user.favoriteStages,
                  FavoriteKind.players: user.favoritePlayers,
                };
                body = TabBarView(
                  controller: _tabController,
                  children: [
                    for (final kind in FavoriteKind.values)
                      FavoriteKindView(
                        kind: kind,
                        ids: ids[kind]!,
                        layout: layout,
                        padding: listPadding,
                      ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: _FavoriteTabs(
                      controller: _tabController,
                      counts: user == null
                          ? null
                          : [
                              user.favoriteShows.length,
                              user.favoriteStages.length,
                              user.favoritePlayers.length,
                            ],
                      enabled: user != null,
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Giriş/hata bildirimi — sekmeler yerine tek parça.
class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxxl,
            AppSpacing.lg, AppSpacing.xxxl),
        child: Center(child: child),
      );
}

/// Biletlerim'deki sekme diliyle aynı: altı çizili, sade; yanında gerçek
/// sayı.
class _FavoriteTabs extends StatelessWidget {
  final TabController controller;
  final List<int>? counts;
  final bool enabled;

  const _FavoriteTabs({
    required this.controller,
    required this.counts,
    required this.enabled,
  });

  String _label(final int i) {
    final String name = FavoriteKind.values[i].label;
    final int? n = counts?[i];
    return n == null || n == 0 ? name : '$name  $n';
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return IgnorePointer(
      ignoring: !enabled,
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 2.5),
        ),
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        dividerColor: cs.outlineVariant,
        overlayColor: WidgetStateProperty.resolveWith((final states) =>
            states.contains(WidgetState.focused)
                ? cs.primary.withOpacity(0.14)
                : null),
        tabs: [
          for (int i = 0; i < FavoriteKind.values.length; i++)
            Tab(height: 48, text: _label(i)),
        ],
      ),
    );
  }
}
