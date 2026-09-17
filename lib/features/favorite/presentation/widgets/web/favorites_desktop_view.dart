import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/section_header.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/providers/show_provider.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../stages/presentation/providers/stage_provider.dart';
import '../../../../users/presentation/providers/user_provider.dart';

// =============================================================================
// MASAÜSTÜ (WEB) "KOLEKSİYONUM" (FAVORİLER) SAYFASI — GERÇEK VERİ
// =============================================================================
//
// Mobil gövdedeki `_buildResponsiveGrid` tamamen kurgusal (sabit 8 öğe,
// üçüncü parti stok görseller, "Favori Oyun $index" gibi uydurma isimler)
// — burada KULLANILMIYOR. Bu sayfa yalnızca `userProfileProvider`'dan gelen
// gerçek `User.favoriteShows` / `favoriteStages` / `favoritePlayers` ID
// listelerini `showsByIdsProvider` / `stagesByIdsProvider` /
// `playersByIdsProvider` ile gerçek Firestore kayıtlarına çevirir. Bir ID
// artık Firestore'da yoksa (silinmiş kayıt) o kart sessizce listeden düşer
// — sahte bir yer tutucuyla doldurulmaz.
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — mobil uygulama çatısıdır.
// Bkz. `nearby_events_page.dart`'taki `_NearbyEventsDesktopPage` — aynı
// gerekçe.
class FavoritesDesktopPage extends StatelessWidget {
  const FavoritesDesktopPage({super.key});

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: Gövde kendi `ListView`'ı ile zaten kaydırılabilir — burada
        // ikinci bir SingleChildScrollView SARMAK "unbounded height"
        // hatasına yol açar, bilerek eklenmedi.
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: const _FavoritesDesktopBody(),
          ),
        ),
      );
}

class _FavoritesDesktopBody extends ConsumerWidget {
  const _FavoritesDesktopBody();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
        ),
      ),
      error: (final err, final stack) => Center(
        child: Text(
          'Koleksiyonun yüklenemedi: $err',
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      ),
      data: (final user) {
        if (user == null) return const _FavoritesSignInNotice();

        final hasAnyFavorite = user.favoriteShows.isNotEmpty ||
            user.favoriteStages.isNotEmpty ||
            user.favoritePlayers.isNotEmpty;
        if (!hasAnyFavorite) return const _FavoritesEmptyState();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 36),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _FavoritesDesktopBanner(
                showCount: user.favoriteShows.length,
                stageCount: user.favoriteStages.length,
                playerCount: user.favoritePlayers.length,
              ),
            ),
            const SizedBox(height: 48),
            if (user.favoriteShows.isNotEmpty)
              _FavoriteShowsSection(ids: user.favoriteShows),
            if (user.favoriteStages.isNotEmpty) ...[
              const SizedBox(height: 56),
              _FavoriteStagesSection(ids: user.favoriteStages),
            ],
            if (user.favoritePlayers.isNotEmpty) ...[
              const SizedBox(height: 56),
              _FavoritePlayersSection(ids: user.favoritePlayers),
            ],
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

class _FavoritesDesktopBanner extends StatelessWidget {
  final int showCount;
  final int stageCount;
  final int playerCount;

  const _FavoritesDesktopBanner({
    required this.showCount,
    required this.stageCount,
    required this.playerCount,
  });

  @override
  Widget build(final BuildContext context) {
    final total = showCount + stageCount + playerCount;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: WebColors.cardGradient,
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koleksiyonum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.h3Size,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$total favori: $showCount oyun, $stageCount sahne, $playerCount sanatçı.',
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// OYUNLAR
// -----------------------------------------------------------------------------
class _FavoriteShowsSection extends ConsumerWidget {
  final List<String> ids;

  const _FavoriteShowsSection({required this.ids});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showsAsync = ref.watch(showsByIdsProvider(ids));
    // Bir oyunun takviminde gelecek bir etkinliği kalmadıysa bunu dürüstçe
    // belirtmek için — limitsiz sürüm, çünkü favori bir oyun "son eklenen
    // 20" içinde olmayabilir.
    final activeShowsAsync = ref.watch(activeShowsProvider(false));
    final activeIds = activeShowsAsync.value?.map((final s) => s.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Favori Oyunlar',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        showsAsync.when(
          loading: () => const _SectionGridSkeleton(),
          error: (final err, final stack) => const _SectionErrorNotice(
              message: 'Favori oyunların yüklenemedi.'),
          data: (final shows) {
            if (shows.isEmpty)
              return const _SectionErrorNotice(
                  message: 'Favori oyunların artık bulunamıyor.');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemCount: shows.length,
                itemBuilder: (final context, final index) {
                  final show = shows[index];
                  final bool? seasonClosed =
                      activeIds == null ? null : !activeIds.contains(show.id);
                  return _FavoriteShowCard(
                      key: ValueKey('fav-show-${show.id}'),
                      show: show,
                      seasonClosed: seasonClosed ?? false);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FavoriteShowCard extends StatelessWidget {
  final Show show;
  final bool seasonClosed;

  const _FavoriteShowCard({
    super.key,
    required this.show,
    required this.seasonClosed,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
        child: Container(
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(28),
            ),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OptimizedCachedImage(
                          imageUrl: show.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              WebColors.darkBlueSurface.withOpacity(0.95),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Icon(Icons.favorite_rounded,
                            color: WebColors.primaryGoldLight, size: 20),
                      ),
                      if (seasonClosed)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'SEZON KAPANDI',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        show.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seasonClosed
                            ? 'Bu oyunun sezonu kapandı'
                            : show.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: seasonClosed
                              ? Colors.white38
                              : WebColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              seasonClosed ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// SAHNELER
// -----------------------------------------------------------------------------
class _FavoriteStagesSection extends ConsumerWidget {
  final List<String> ids;

  const _FavoriteStagesSection({required this.ids});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final stagesAsync = ref.watch(stagesByIdsProvider(ids));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Favori Sahneler',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        stagesAsync.when(
          loading: () => const _SectionGridSkeleton(),
          error: (final err, final stack) => const _SectionErrorNotice(
              message: 'Favori sahnelerin yüklenemedi.'),
          data: (final stages) {
            if (stages.isEmpty)
              return const _SectionErrorNotice(
                  message: 'Favori sahnelerin artık bulunamıyor.');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.35,
                ),
                itemCount: stages.length,
                itemBuilder: (final context, final index) => _FavoriteStageCard(
                    key: ValueKey('fav-stage-${stages[index].id}'),
                    stage: stages[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FavoriteStageCard extends StatelessWidget {
  final Stage stage;

  const _FavoriteStageCard({super.key, required this.stage});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
        child: Container(
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(28),
            ),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OptimizedCachedImage(
                          imageUrl: stage.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              WebColors.darkBlueSurface.withOpacity(0.95),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Icon(Icons.favorite_rounded,
                            color: WebColors.primaryGoldLight, size: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: WebColors.primaryGoldLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stage.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: WebColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// SANATÇILAR
// -----------------------------------------------------------------------------
class _FavoritePlayersSection extends ConsumerWidget {
  final List<String> ids;

  const _FavoritePlayersSection({required this.ids});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playersAsync = ref.watch(playersByIdsProvider(ids));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Favori Sanatçılar',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        playersAsync.when(
          loading: () => const _SectionGridSkeleton(),
          error: (final err, final stack) => const _SectionErrorNotice(
              message: 'Favori sanatçıların yüklenemedi.'),
          data: (final players) {
            if (players.isEmpty)
              return const _SectionErrorNotice(
                  message: 'Favori sanatçıların artık bulunamıyor.');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.78,
                ),
                itemCount: players.length,
                itemBuilder: (final context, final index) =>
                    _FavoritePlayerCard(
                        key: ValueKey('fav-player-${players[index].id}'),
                        player: players[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FavoritePlayerCard extends StatelessWidget {
  final Player player;

  const _FavoritePlayerCard({super.key, required this.player});

  @override
  Widget build(final BuildContext context) {
    final fullName = '${player.firstName} ${player.lastName}'.trim();
    return GestureDetector(
      onTap: () => NavigationHandler.goToPlayer(
          context, player.id, fullName.isEmpty ? player.id : fullName),
      child: Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                        imageUrl: player.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            WebColors.darkBlueSurface.withOpacity(0.95),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Text(
                  fullName.isEmpty ? 'Sanatçı' : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORTAK DURUMLAR
// -----------------------------------------------------------------------------
class _SectionGridSkeleton extends StatelessWidget {
  const _SectionGridSkeleton();

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  const AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
              strokeWidth: 2,
            ),
          ),
        ),
      );
}

class _SectionErrorNotice extends StatelessWidget {
  final String message;

  const _SectionErrorNotice({required this.message});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          message,
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border_rounded,
                  size: 60, color: WebColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Henüz favori eklemedin.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Beğendiğin oyun, sahne ve sanatçıları kalp ikonuna dokunarak buraya ekleyebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WebColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
}

class _FavoritesSignInNotice extends StatelessWidget {
  const _FavoritesSignInNotice();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 60, color: WebColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Koleksiyonunu görmek için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
}
