import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../favorite/presentation/widgets/favorite_toggle_button.dart';
import '../../../home/presentation/widgets/web/landing/landing_palette.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../users/domain/entities/favorite_type.dart';
import '../providers/player_provider.dart';

/// 🎭 Sanatçı Profili — WEB. "Crimson Noir" tanıtım sayfasıyla aynı görsel
/// dil: koyu zemin + kızıl aksan, tam genişlikte "band" bölümler. Mobil
/// uygulamaya (player_details_mobil.dart) HİÇBİR ŞEKİLDE dokunmuyor — o
/// dosya olduğu gibi kalıyor, bu sadece web tarafının kendi görünümü.
/// Tüm veri aynı gerçek `playerDetailProvider`'dan geliyor.
class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with GlobalScrollMixin {
  @override
  Widget build(final BuildContext context) {
    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));
    final width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 900;
    final double hPad = width > 1400 ? 100 : (width > 900 ? 60 : 24);

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      title: 'Sanatçı Profili',
      subtitle: 'Sahnenin arkasındaki emek',
      rightIcon: Icons.star_rounded,
      isLoading: playerAsync.isLoading,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: LandingPalette.bg,
        ambientColor: LandingPalette.crimson.withOpacity(0.04),
      ),
      child: playerAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (final err, final _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: BentoErrorState(
              message: 'Sanatçı profili yüklenirken bir sorun oluştu.',
              onRetry: () =>
                  ref.invalidate(playerDetailProvider(widget.playerId)),
            ),
          ),
        ),
        data: (final state) => CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _PlayerHero(state: state, hPad: hPad),
            ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'HAKKINDA',
                title: 'Sanatçı Öyküsü',
                hPad: hPad,
                child: isLarge
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 6,
                              child: _BioBlock(state: state, isLarge: isLarge)),
                          const SizedBox(width: 48),
                          Expanded(flex: 4, child: _StatsColumn(state: state)),
                        ],
                      )
                    : Column(
                        children: [
                          _BioBlock(state: state, isLarge: isLarge),
                          const SizedBox(height: 32),
                          _StatsColumn(state: state),
                        ],
                      ),
              ),
            ),
            if (state.player.achievements.isNotEmpty)
              SliverToBoxAdapter(
                child: LandingSectionBand(
                  eyebrow: 'ÖDÜLLER',
                  title: 'Başarı Hikayesi',
                  hPad: hPad,
                  alt: true,
                  child: _AchievementsTimeline(
                      achievements: state.player.achievements),
                ),
              ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'ŞU AN SAHNEDE',
                title: 'Aktif Oyunlar',
                hPad: hPad,
                child: state.activeShows.isEmpty
                    ? const LandingComingSoonCard(
                        icon: Icons.theater_comedy_outlined,
                        message: 'Şu an sahnede bir oyunu bulunmuyor.',
                      )
                    : _ShowsRow(shows: state.activeShows),
              ),
            ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'ARŞİV',
                title: 'Geçmiş Oyunlar',
                hPad: hPad,
                alt: true,
                child: state.pastShows.isEmpty
                    ? const LandingComingSoonCard(
                        icon: Icons.history_rounded,
                        message: 'Arşiv henüz güncellenmemiş.',
                      )
                    : _ShowsRow(shows: state.pastShows),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

class _PlayerHero extends StatelessWidget {
  final PlayerDetailState state;
  final double hPad;
  const _PlayerHero({required this.state, required this.hPad});

  @override
  Widget build(final BuildContext context) {
    final player = state.player;
    return SizedBox(
      height: 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (player.imageUrl.isNotEmpty)
            CachedNetworkImage(imageUrl: player.imageUrl, fit: BoxFit.cover)
          else
            const ColoredBox(color: LandingPalette.surface),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LandingPalette.emberGlow),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  LandingPalette.bg.withOpacity(0.35),
                  LandingPalette.bg.withOpacity(0.55),
                  LandingPalette.bg,
                ],
              ),
            ),
          ),
          Positioned(
            left: hPad,
            right: hPad,
            bottom: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: LandingPalette.crimsonLight
                                  .withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('USTA SANATÇI',
                            style: TextStyle(
                                color: LandingPalette.crimsonLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${player.firstName}\n${player.lastName}'
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 0.95,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _circleIconBtn(
                      child: FavoriteToggleButton(
                        itemId: player.id,
                        type: FavoriteType.player,
                        inactiveColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _circleIconBtn(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.white, size: 20),
                        onPressed: () => TiyatrolDeeplinkService.shareActor(
                          id: player.id,
                          name: '${player.firstName} ${player.lastName}',
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
    );
  }

  Widget _circleIconBtn({required final Widget child}) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: LandingPalette.microBorderStrong),
        ),
        child: child,
      );
}

class _BioBlock extends StatelessWidget {
  final PlayerDetailState state;
  final bool isLarge;
  const _BioBlock({required this.state, required this.isLarge});

  @override
  Widget build(final BuildContext context) {
    final player = state.player;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (player.bio.trim().isNotEmpty)
          Text(player.bio,
              style: TextStyle(
                  height: 1.9,
                  fontSize: isLarge ? 16.5 : 15,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.2))
        else
          Text('Bu sanatçı için henüz bir biyografi eklenmedi.',
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.4))),
        if (player.quote.trim().isNotEmpty) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: LandingPalette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border(
                left: BorderSide(color: LandingPalette.crimson, width: 4),
              ),
            ),
            child: Text('"${player.quote.trim()}"',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1.5)),
          ),
        ],
        if (player.collaborations.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text('GÜÇLÜ İŞBİRLİKLERİ',
              style: TextStyle(
                  color: LandingPalette.crimsonLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: player.collaborations
                .map((final c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: LandingPalette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LandingPalette.microBorder),
                      ),
                      child: Text(c,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _StatsColumn extends StatelessWidget {
  final PlayerDetailState state;
  const _StatsColumn({required this.state});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Expanded(
              child: _statCard('AKTİF', '${state.activeShows.length}',
                  LandingPalette.crimson)),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard('ARŞİV', '${state.pastShows.length}',
                  LandingPalette.crimsonLight)),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard('ÖDÜL', '${state.player.achievements.length}',
                  LandingPalette.live)),
        ],
      );

  Widget _statCard(final String label, final String value, final Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color.withOpacity(0.7),
                    letterSpacing: 1.2)),
          ],
        ),
      );
}

class _AchievementsTimeline extends StatelessWidget {
  final List<Map<String, String>> achievements;
  const _AchievementsTimeline({required this.achievements});

  @override
  Widget build(final BuildContext context) => Column(
        children: [
          for (var i = 0; i < achievements.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: LandingPalette.crimson,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: LandingPalette.crimson.withOpacity(0.25),
                              width: 4),
                        ),
                      ),
                      if (i != achievements.length - 1)
                        Expanded(
                          child: Container(
                              width: 2,
                              color: LandingPalette.crimson.withOpacity(0.2)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(achievements[i]['year'] ?? '----',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: LandingPalette.crimsonLight,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(achievements[i]['title'] ?? '',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3)),
                          if ((achievements[i]['detail'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(achievements[i]['detail']!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13.5)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _ShowsRow extends StatelessWidget {
  final List<Show> shows;
  const _ShowsRow({required this.shows});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 260,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shows.length,
          separatorBuilder: (final _, final __) => const SizedBox(width: 18),
          itemBuilder: (final context, final i) {
            final show = shows[i];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
              child: Container(
                width: 190,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Text(show.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}
