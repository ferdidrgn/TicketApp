import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/theatre_show_card.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

/// FAVORİLER — mobil, tablet ve masaüstünün ortak içerik parçaları.
///
/// Favori oyunlar kullanıcının kenara ayırdığı biletlerdir: mobilde
/// `ShowTicketRow` (kompakt bilet satırı), tablet/masaüstünde bilet koçanlı
/// `TheatreShowCard` ızgarası. Takviminde gelecek seansı kalmayan oyunlar
/// gizlenmez; "Perdesi kapananlar" başlığı altında soluk durur.
/// Sahneler ve sanatçılar bilet değildir → sade liste satırı
/// (`BrowseListTile`), bilet süsü yok.
///
/// Veri: `User.favoriteShows/Stages/Players` ID listeleri →
/// `showsByIdsProvider` / `stagesByIdsProvider` / `playersByIdsProvider`.
/// Firestore'da artık olmayan kayıt sessizce düşer; yer tutucu uydurulmaz.

enum FavoriteLayout { mobile, tablet, desktop }

enum FavoriteKind { shows, stages, players }

extension FavoriteKindLabel on FavoriteKind {
  String get label => switch (this) {
        FavoriteKind.shows => 'Oyunlar',
        FavoriteKind.stages => 'Sahneler',
        FavoriteKind.players => 'Sanatçılar',
      };

  IconData get icon => switch (this) {
        FavoriteKind.shows => Icons.theater_comedy_outlined,
        FavoriteKind.stages => Icons.location_on_outlined,
        FavoriteKind.players => Icons.person_outline_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────
// Ortak kaydırma kabuğu
// ─────────────────────────────────────────────────────────────────────────

/// Her sekmenin/panelin kendi kaydırılabilir alanı. [header] masaüstünde
/// bölüm başlığıdır; mobilde sekme zaten başlık olduğu için boştur.
class _FavoriteScroll extends StatelessWidget {
  final EdgeInsets padding;
  final Widget? header;
  final List<Widget> slivers;

  const _FavoriteScroll({
    required this.padding,
    required this.slivers,
    this.header,
  });

  @override
  Widget build(final BuildContext context) {
    final EdgeInsets side =
        EdgeInsets.only(left: padding.left, right: padding.right);
    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: padding.top)),
        if (header != null)
          SliverPadding(
              padding: side, sliver: SliverToBoxAdapter(child: header)),
        for (final Widget sliver in slivers)
          SliverPadding(padding: side, sliver: sliver),
        SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
      ],
    );
  }
}

Widget _box(final Widget child) => SliverToBoxAdapter(child: child);

Widget _gap(final double h) => SliverToBoxAdapter(child: SizedBox(height: h));

Widget _notice(final TicketNotice notice) =>
    _box(Align(alignment: Alignment.topLeft, child: notice));

// ─────────────────────────────────────────────────────────────────────────
// Durumlar
// ─────────────────────────────────────────────────────────────────────────

/// Giriş yapılmamışken: ne olduğunu söyler + tek adım.
class FavoriteSignInNotice extends StatelessWidget {
  const FavoriteSignInNotice({super.key});

  @override
  Widget build(final BuildContext context) => TicketNotice(
        label: 'FAVORİLER',
        title: 'Favorilerin hesabında saklanır',
        message: 'Beğendiğin oyunları, sahneleri ve sanatçıları görmek için '
            'giriş yap.',
        actionLabel: 'Giriş yap',
        actionIcon: Icons.login_rounded,
        onAction: () => NavigationHandler.goToLogin(context),
      );
}

/// Favoriler (kullanıcı profili) yüklenemediğinde.
class FavoriteErrorNotice extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const FavoriteErrorNotice({
    super.key,
    required this.onRetry,
    this.title = 'Favorilerin yüklenemedi',
  });

  @override
  Widget build(final BuildContext context) => TicketNotice(
        label: 'BAĞLANTI',
        title: title,
        message: 'Listene şu an ulaşamadık; favorilerin silinmedi. İnternet '
            'bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        actionIcon: Icons.refresh_rounded,
        onAction: onRetry,
      );
}

TicketNotice _emptyNotice(final BuildContext context, final FavoriteKind kind,
    {final bool missing = false}) {
  final String title = missing
      ? switch (kind) {
          FavoriteKind.shows => 'Favori oyunların artık yayında değil',
          FavoriteKind.stages => 'Favori sahnelerin artık yayında değil',
          FavoriteKind.players => 'Favori sanatçıların artık yayında değil',
        }
      : switch (kind) {
          FavoriteKind.shows => 'Henüz favori oyunun yok',
          FavoriteKind.stages => 'Henüz favori sahnen yok',
          FavoriteKind.players => 'Henüz favori sanatçın yok',
        };
  final String message = switch (kind) {
    FavoriteKind.shows =>
      'Bir oyunun sayfasındaki kalbe dokun; bileti burada kenarda dursun.',
    FavoriteKind.stages =>
      'Sahne sayfasındaki kalbe dokunduğun mekanlar burada listelenir.',
    FavoriteKind.players =>
      'Sanatçı sayfasındaki kalbe dokunduğun isimler burada listelenir.',
  };
  return TicketNotice(
    label: 'FAVORİLER',
    title: title,
    message: message,
    actionLabel: 'Oyunlara göz at',
    actionIcon: Icons.explore_outlined,
    onAction: () => NavigationHandler.goToDiscover(context),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// İskeletler
// ─────────────────────────────────────────────────────────────────────────

List<Widget> _rowSkeletons(final double height, {final int count = 5}) => [
      SliverList.separated(
        itemCount: count,
        separatorBuilder: (final _, final __) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (final _, final __) => TicketRowSkeleton(height: height),
      ),
    ];

double _cardMax(final FavoriteLayout layout) =>
    layout == FavoriteLayout.desktop ? 240 : 220;

/// Profil (favori ID'leri) gelene kadar: oyun görünümünün şeklinde iskelet.
class FavoriteSkeletonView extends StatelessWidget {
  final FavoriteLayout layout;
  final EdgeInsets padding;
  final Widget? header;

  const FavoriteSkeletonView({
    super.key,
    required this.layout,
    required this.padding,
    this.header,
  });

  @override
  Widget build(final BuildContext context) => _FavoriteScroll(
        padding: padding,
        header: header,
        slivers: layout == FavoriteLayout.mobile
            ? _rowSkeletons(96)
            : [
                SliverGrid.builder(
                  gridDelegate: browseShowGridDelegate(_cardMax(layout)),
                  itemCount: layout == FavoriteLayout.desktop ? 8 : 6,
                  itemBuilder: (final _, final __) =>
                      const TicketCardSkeleton(),
                ),
              ],
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Oyunlar
// ─────────────────────────────────────────────────────────────────────────

class FavoriteShowsView extends ConsumerWidget {
  final List<String> ids;
  final FavoriteLayout layout;
  final EdgeInsets padding;
  final Widget? header;

  const FavoriteShowsView({
    super.key,
    required this.ids,
    required this.layout,
    required this.padding,
    this.header,
  });

  void _open(final BuildContext context, final Show show) {
    HapticFeedback.lightImpact();
    NavigationHandler.goToShow(context, show.id, show.name);
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ids.isEmpty) {
      return _FavoriteScroll(
        padding: padding,
        header: header,
        slivers: [_notice(_emptyNotice(context, FavoriteKind.shows))],
      );
    }

    final showsAsync = ref.watch(showsByIdsProvider(ids));
    // Takviminde gelecek seansı kalmayan oyunu dürüstçe ayırmak için —
    // limitsiz sürüm: favori bir oyun "son eklenen 20" içinde olmayabilir.
    final Set<String>? activeIds = ref
        .watch(activeShowsProvider(false))
        .value
        ?.map((final s) => s.id)
        .toSet();

    final bool grid = layout != FavoriteLayout.mobile;

    final List<Widget> slivers = showsAsync.when(
      loading: () => grid
          ? [
              SliverGrid.builder(
                gridDelegate: browseShowGridDelegate(_cardMax(layout)),
                itemCount: layout == FavoriteLayout.desktop ? 8 : 6,
                itemBuilder: (final _, final __) => const TicketCardSkeleton(),
              ),
            ]
          : _rowSkeletons(96),
      error: (final _, final __) => [
        _notice(FavoriteErrorNotice(
          title: 'Favori oyunların yüklenemedi',
          onRetry: () => ref.invalidate(showsByIdsProvider(ids)),
        )),
      ],
      data: (final shows) {
        if (shows.isEmpty) {
          return [
            _notice(_emptyNotice(context, FavoriteKind.shows, missing: true))
          ];
        }
        // Aktiflik bilgisi yoksa (yükleniyor/hata) hepsi tek listede.
        final List<Show> onStage = activeIds == null
            ? shows
            : shows.where((final s) => activeIds.contains(s.id)).toList();
        final List<Show> closed = activeIds == null
            ? const <Show>[]
            : shows.where((final s) => !activeIds.contains(s.id)).toList();

        final bool sectioned = closed.isNotEmpty;
        return [
          if (onStage.isNotEmpty) ...[
            if (sectioned)
              _box(BrowseSectionTitle(title: 'Sahnede', count: onStage.length)),
            _showsSliver(context, onStage, grid: grid, dimmed: false),
          ],
          if (closed.isNotEmpty) ...[
            if (onStage.isNotEmpty) _gap(AppSpacing.xxxl),
            _box(BrowseSectionTitle(
                title: 'Perdesi kapananlar', count: closed.length)),
            _showsSliver(context, closed, grid: grid, dimmed: true),
          ],
        ];
      },
    );

    return _FavoriteScroll(padding: padding, header: header, slivers: slivers);
  }

  Widget _showsSliver(final BuildContext context, final List<Show> shows,
      {required final bool grid, required final bool dimmed}) {
    Widget wrap(final Widget child) => dimmed
        // Seansı kalmayan oyun: kullanılmış bir bilet gibi soluk.
        ? Opacity(opacity: 0.62, child: child)
        : child;

    if (grid) {
      return SliverGrid.builder(
        gridDelegate: browseShowGridDelegate(_cardMax(layout)),
        itemCount: shows.length,
        itemBuilder: (final context, final i) => wrap(
          TheatreShowCard(
            key: ValueKey('fav-show-${shows[i].id}'),
            show: shows[i],
            onTap: () => _open(context, shows[i]),
          ),
        ),
      );
    }
    return SliverList.separated(
      itemCount: shows.length,
      separatorBuilder: (final _, final __) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (final context, final i) => wrap(
        ShowTicketRow(
          key: ValueKey('fav-show-${shows[i].id}'),
          show: shows[i],
          onTap: () => _open(context, shows[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sahneler ve sanatçılar — sade satırlar
// ─────────────────────────────────────────────────────────────────────────

/// Mobilde tek sütun liste; tablet/masaüstünde genişliğe göre sütunlanan
/// sabit yükseklikli satırlar.
Widget _rowsSliver({
  required final FavoriteLayout layout,
  required final int count,
  required final Widget Function(BuildContext, int) builder,
}) {
  if (layout == FavoriteLayout.mobile) {
    return SliverList.separated(
      itemCount: count,
      separatorBuilder: (final _, final __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: builder,
    );
  }
  return SliverGrid.builder(
    gridDelegate: browseRowGridDelegate(maxRowWidth: 460, rowHeight: 72),
    itemCount: count,
    itemBuilder: builder,
  );
}

class FavoriteStagesView extends ConsumerWidget {
  final List<String> ids;
  final FavoriteLayout layout;
  final EdgeInsets padding;
  final Widget? header;

  const FavoriteStagesView({
    super.key,
    required this.ids,
    required this.layout,
    required this.padding,
    this.header,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ids.isEmpty) {
      return _FavoriteScroll(
        padding: padding,
        header: header,
        slivers: [_notice(_emptyNotice(context, FavoriteKind.stages))],
      );
    }
    final stagesAsync = ref.watch(stagesByIdsProvider(ids));
    final List<Widget> slivers = stagesAsync.when(
      loading: () => _rowSkeletons(72, count: 4),
      error: (final _, final __) => [
        _notice(FavoriteErrorNotice(
          title: 'Favori sahnelerin yüklenemedi',
          onRetry: () => ref.invalidate(stagesByIdsProvider(ids)),
        )),
      ],
      data: (final List<Stage> stages) => stages.isEmpty
          ? [
              _notice(
                  _emptyNotice(context, FavoriteKind.stages, missing: true))
            ]
          : [
              _rowsSliver(
                layout: layout,
                count: stages.length,
                builder: (final context, final i) {
                  final Stage stage = stages[i];
                  return BrowseListTile(
                    key: ValueKey('fav-stage-${stage.id}'),
                    imageUrl: stage.imageUrl,
                    title: stage.name,
                    subtitle: stage.address,
                    fallbackIcon: Icons.location_on_outlined,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      NavigationHandler.goToStage(
                          context, stage.id, stage.name);
                    },
                  );
                },
              ),
            ],
    );
    return _FavoriteScroll(padding: padding, header: header, slivers: slivers);
  }
}

class FavoritePlayersView extends ConsumerWidget {
  final List<String> ids;
  final FavoriteLayout layout;
  final EdgeInsets padding;
  final Widget? header;

  const FavoritePlayersView({
    super.key,
    required this.ids,
    required this.layout,
    required this.padding,
    this.header,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ids.isEmpty) {
      return _FavoriteScroll(
        padding: padding,
        header: header,
        slivers: [_notice(_emptyNotice(context, FavoriteKind.players))],
      );
    }
    final playersAsync = ref.watch(playersByIdsProvider(ids));
    final List<Widget> slivers = playersAsync.when(
      loading: () => _rowSkeletons(72, count: 4),
      error: (final _, final __) => [
        _notice(FavoriteErrorNotice(
          title: 'Favori sanatçıların yüklenemedi',
          onRetry: () => ref.invalidate(playersByIdsProvider(ids)),
        )),
      ],
      data: (final List<Player> players) => players.isEmpty
          ? [
              _notice(
                  _emptyNotice(context, FavoriteKind.players, missing: true))
            ]
          : [
              _rowsSliver(
                layout: layout,
                count: players.length,
                builder: (final context, final i) {
                  final Player player = players[i];
                  final String fullName =
                      '${player.firstName} ${player.lastName}'.trim();
                  final int current = player.nowShowsId.length;
                  return BrowseListTile(
                    key: ValueKey('fav-player-${player.id}'),
                    imageUrl: player.imageUrl,
                    title: fullName.isEmpty ? 'Sanatçı' : fullName,
                    subtitle: current == 0 ? null : '$current güncel oyun',
                    fallbackIcon: Icons.person_outline_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      NavigationHandler.goToPlayer(
                        context,
                        player.id,
                        fullName.isEmpty ? player.id : fullName,
                      );
                    },
                  );
                },
              ),
            ],
    );
    return _FavoriteScroll(padding: padding, header: header, slivers: slivers);
  }
}

/// Seçili türün içerik görünümü (masaüstü sağ paneli ve mobil sekmeler).
class FavoriteKindView extends StatelessWidget {
  final FavoriteKind kind;
  final List<String> ids;
  final FavoriteLayout layout;
  final EdgeInsets padding;
  final Widget? header;

  const FavoriteKindView({
    super.key,
    required this.kind,
    required this.ids,
    required this.layout,
    required this.padding,
    this.header,
  });

  @override
  Widget build(final BuildContext context) => switch (kind) {
        FavoriteKind.shows => FavoriteShowsView(
            ids: ids, layout: layout, padding: padding, header: header),
        FavoriteKind.stages => FavoriteStagesView(
            ids: ids, layout: layout, padding: padding, header: header),
        FavoriteKind.players => FavoritePlayersView(
            ids: ids, layout: layout, padding: padding, header: header),
      };
}
