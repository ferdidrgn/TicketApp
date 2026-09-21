import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../widgets/web/favorites_desktop_view.dart';

// =============================================================================
// MOBİL "KOLEKSİYONUM" (FAVORİLER) SAYFASI — GERÇEK VERİ
// =============================================================================
//
// Önceden burada `itemCount: 8` sabit, üçüncü parti stok görselli, uydurma
// isimli ("Favori Oyun $index" vb.) kartlar vardı ve dokunulduğunda HER
// zaman aynı sahte id ('0') ile detay sayfasına gidilirdi. Artık masaüstü
// karşılığı `favorites_desktop_view.dart`'taki gibi `userProfileProvider`'
// dan gelen gerçek `User.favoriteShows` / `favoriteStages` / `favoritePlayers`
// ID listeleri `showsByIdsProvider` / `stagesByIdsProvider` /
// `playersByIdsProvider` ile gerçek Firestore kayıtlarına çevriliyor. Bir ID
// artık Firestore'da yoksa (silinmiş kayıt) o kart sessizce listeden düşer
// — sahte bir yer tutucuyla doldurulmaz. Mobil arayüz kabuğu (BasePageWrapper,
// 3 sekmeli TabController/_FavoriteTabSelector, GridView.builder,
// ShowCard/CustomStageCard) AYNEN korunuyor; sadece veri katmanı gerçek.
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Masaüstünde (>=1024px) gerçek Firestore verisiyle çalışan, ayrı bir
    // "premium" web deneyimi kullanılır (bkz. FavoritesDesktopPage). Mobil/
    // tablet gövdesi aşağıda AYNEN kalır — bu görevin kapsamı sadece
    // masaüstü deneyimini eklemek, mobili yeniden yazmak değil.
    if (context.isDesktop) return const FavoritesDesktopPage();

    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return DefaultTabController(
      length: 3,
      child: BasePageWrapper(
        title: 'KOLEKSİYONUM',
        subtitle: 'Kalbinde yer eden tüm sahneler...',
        showBackButton: true,
        rightIcon: Icons.favorite_rounded,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1200 : double.infinity),
            child: Column(
              children: [
                // 1. MODERNIZE EDILMIŞ TAB SEÇİCİ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _FavoriteTabSelector(controller: _tabController),
                ),

                // 2. RESPONSIVE GRID ALANI — GERÇEK VERİ
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _FavoriteShowsTab(),
                      _FavoriteStagesTab(),
                      _FavoritePlayersTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ORTAK RESPONSIVE GRID SARMALAYICI ---
class _FavoriteGrid extends StatelessWidget {
  final int itemCount;
  final double aspectRatio;
  final Widget Function(BuildContext, int) itemBuilder;

  const _FavoriteGrid({
    required this.itemCount,
    required this.aspectRatio,
    required this.itemBuilder,
  });

  @override
  Widget build(final BuildContext context) {
    // 💡 Ekran genişliğine göre sütun sayısı: Mobil 2, Tablet 3, Web 4-5
    final int crossAxisCount =
        context.responsive(mobile: 2, tablet: 3, desktop: 4);

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

// --- SEKME 1: FAVORİ OYUNLAR ---
class _FavoriteShowsTab extends ConsumerWidget {
  const _FavoriteShowsTab();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () => const _FavoriteLoadingIndicator(),
      error: (final _, final __) =>
          const _FavoriteErrorNotice(message: 'Koleksiyonun yüklenemedi.'),
      data: (final user) {
        if (user == null) return const _FavoriteSignInNotice();

        final ids = user.favoriteShows;
        if (ids.isEmpty) {
          return const _FavoriteEmptyState(
            icon: Icons.theater_comedy_rounded,
            message: 'Henüz favori oyununuz yok.',
          );
        }

        final showsAsync = ref.watch(showsByIdsProvider(ids));
        return showsAsync.when(
          loading: () => const _FavoriteLoadingIndicator(),
          error: (final _, final __) => const _FavoriteErrorNotice(
              message: 'Favori oyunların yüklenemedi.'),
          data: (final shows) {
            if (shows.isEmpty) {
              return const _FavoriteEmptyState(
                icon: Icons.theater_comedy_rounded,
                message: 'Favori oyunların artık bulunamıyor.',
              );
            }

            return _FavoriteGrid(
              itemCount: shows.length,
              aspectRatio: 0.75,
              itemBuilder: (final context, final index) {
                final show = shows[index];
                return ShowCard(
                  key: ValueKey('fav-show-${show.id}'),
                  imageUrl: show.imageUrl,
                  gameName: show.name,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NavigationHandler.goToShow(context, show.id, show.name);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- SEKME 2: FAVORİ SAHNELER ---
class _FavoriteStagesTab extends ConsumerWidget {
  const _FavoriteStagesTab();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () => const _FavoriteLoadingIndicator(),
      error: (final _, final __) =>
          const _FavoriteErrorNotice(message: 'Koleksiyonun yüklenemedi.'),
      data: (final user) {
        if (user == null) return const _FavoriteSignInNotice();

        final ids = user.favoriteStages;
        if (ids.isEmpty) {
          return const _FavoriteEmptyState(
            icon: Icons.location_on_rounded,
            message: 'Henüz favori sahneniz yok.',
          );
        }

        final stagesAsync = ref.watch(stagesByIdsProvider(ids));
        return stagesAsync.when(
          loading: () => const _FavoriteLoadingIndicator(),
          error: (final _, final __) => const _FavoriteErrorNotice(
              message: 'Favori sahnelerin yüklenemedi.'),
          data: (final stages) {
            if (stages.isEmpty) {
              return const _FavoriteEmptyState(
                icon: Icons.location_on_rounded,
                message: 'Favori sahnelerin artık bulunamıyor.',
              );
            }

            return _FavoriteGrid(
              itemCount: stages.length,
              aspectRatio: 1.1,
              itemBuilder: (final context, final index) {
                final stage = stages[index];
                return CustomStageCard(
                  key: ValueKey('fav-stage-${stage.id}'),
                  text: stage.name,
                  imageUrl: stage.imageUrl,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    NavigationHandler.goToStage(context, stage.id, stage.name);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- SEKME 3: FAVORİ SANATÇILAR ---
class _FavoritePlayersTab extends ConsumerWidget {
  const _FavoritePlayersTab();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () => const _FavoriteLoadingIndicator(),
      error: (final _, final __) =>
          const _FavoriteErrorNotice(message: 'Koleksiyonun yüklenemedi.'),
      data: (final user) {
        if (user == null) return const _FavoriteSignInNotice();

        final ids = user.favoritePlayers;
        if (ids.isEmpty) {
          return const _FavoriteEmptyState(
            icon: Icons.person_rounded,
            message: 'Henüz favori sanatçınız yok.',
          );
        }

        final playersAsync = ref.watch(playersByIdsProvider(ids));
        return playersAsync.when(
          loading: () => const _FavoriteLoadingIndicator(),
          error: (final _, final __) => const _FavoriteErrorNotice(
              message: 'Favori sanatçıların yüklenemedi.'),
          data: (final players) {
            if (players.isEmpty) {
              return const _FavoriteEmptyState(
                icon: Icons.person_rounded,
                message: 'Favori sanatçıların artık bulunamıyor.',
              );
            }

            return _FavoriteGrid(
              itemCount: players.length,
              aspectRatio: 1.1,
              itemBuilder: (final context, final index) {
                final player = players[index];
                final fullName =
                    '${player.firstName} ${player.lastName}'.trim();
                return CustomStageCard(
                  key: ValueKey('fav-player-${player.id}'),
                  text: fullName.isEmpty ? 'Sanatçı' : fullName,
                  imageUrl: player.imageUrl,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    NavigationHandler.goToPlayer(
                      context,
                      player.id,
                      fullName.isEmpty ? player.id : fullName,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- ORTAK DURUMLAR (Yükleniyor / Hata / Boş / Giriş Gerekli) ---
class _FavoriteLoadingIndicator extends StatelessWidget {
  const _FavoriteLoadingIndicator();

  @override
  Widget build(final BuildContext context) => Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      );
}

class _FavoriteErrorNotice extends StatelessWidget {
  final String message;

  const _FavoriteErrorNotice({required this.message});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
}

class _FavoriteEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _FavoriteEmptyState({required this.icon, required this.message});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: context.colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Beğendiğin oyun, sahne ve sanatçıları kalp ikonuna dokunarak buraya ekleyebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.colors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

class _FavoriteSignInNotice extends StatelessWidget {
  const _FavoriteSignInNotice();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 56, color: context.colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Koleksiyonunu görmek için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
}

// --- TAB SEÇİCİ BİLEŞENİ ---
class _FavoriteTabSelector extends StatelessWidget {
  final TabController controller;

  const _FavoriteTabSelector({required this.controller});

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              context.colors.primary,
              context.colors.primary.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: context.colors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        labelColor: context.colors.onPrimary,
        unselectedLabelColor: context.colors.onSurfaceVariant,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: "Oyunlar"),
          Tab(text: "Sahneler"),
          Tab(text: "Sanatçılar"),
        ],
      ),
    );
  }
}
