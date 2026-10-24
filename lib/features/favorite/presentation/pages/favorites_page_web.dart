import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_account_shell.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/domain/next_session.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_mutation_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../widgets/favorite_collections.dart' show FavoriteKind, FavoriteKindLabel;

/// FAVORİLERİM — WEB. Hesap kabuğu içinde: üstte tür çipleri + süzgeç alanı,
/// altında yoğun afiş ızgarası (oyunlar) ya da iki sütunlu satırlar
/// (sahneler, sanatçılar); sağda yapışkan özet. Mobil `FavoritesPage`'den
/// AYRIDIR. Veri: `userProfileProvider` → `User.favorite*` kimlik listeleri →
/// `showsByIdsProvider` / `stagesByIdsProvider` / `playersByIdsProvider`.
/// Kaldırma gerçek kayıttır (`userMutationProvider`), "Geri al" ile döner.
class FavoritesPageWeb extends ConsumerStatefulWidget {
  const FavoritesPageWeb({super.key});

  @override
  ConsumerState<FavoritesPageWeb> createState() => _FavoritesPageWebState();
}

class _FavoritesPageWebState extends ConsumerState<FavoritesPageWeb> {
  FavoriteKind? _kind;
  final TextEditingController _filter = TextEditingController();
  bool _onlyOnStage = false;

  /// Bu oturumda görülen kimlikler: kaldırınca sağlayıcı anahtarı değişip
  /// iskelet yanıp sönmesin, "Geri al" anında geri gelsin.
  final Map<FavoriteKind, List<String>> _known = {
    for (final FavoriteKind k in FavoriteKind.values) k: <String>[],
  };

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<String> _ids(final entity.User u, final FavoriteKind k) => switch (k) {
        FavoriteKind.shows => u.favoriteShows,
        FavoriteKind.stages => u.favoriteStages,
        FavoriteKind.players => u.favoritePlayers,
      };

  entity.User _with(
          final entity.User u, final FavoriteKind k, final List<String> ids) =>
      switch (k) {
        FavoriteKind.shows => u.copyWith(favoriteShows: ids),
        FavoriteKind.stages => u.copyWith(favoriteStages: ids),
        FavoriteKind.players => u.copyWith(favoritePlayers: ids),
      };

  Future<void> _save(
      final entity.User user, final FavoriteKind kind, final List<String> ids) {
    return ref
        .read(userMutationProvider.notifier)
        .save(_with(user, kind, ids), user.imageUrl, isUpdate: true);
  }

  Future<void> _remove(final FavoriteKind kind, final String id) async {
    final entity.User? user = ref.read(userProfileProvider).value;
    if (user == null) return;
    HapticFeedback.selectionClick();
    final List<String> before = List<String>.from(_ids(user, kind));
    final List<String> after = before.where((final x) => x != id).toList();
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    await _save(user, kind, after);
    if (!mounted) return;
    final bool failed = ref.read(userMutationProvider).hasError;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 440,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        content: Text(failed
            ? 'Kaldırılamadı. Bağlantını kontrol edip tekrar dene.'
            : 'Favorilerden çıkarıldı.'),
        action: failed
            ? null
            : SnackBarAction(
                label: 'Geri al',
                onPressed: () {
                  final entity.User? now = ref.read(userProfileProvider).value;
                  if (now != null) _save(now, kind, before);
                },
              ),
      ));
  }

  FavoriteKind _effective(final entity.User? user) {
    if (_kind != null) return _kind!;
    if (user == null) return FavoriteKind.shows;
    return FavoriteKind.values.firstWhere(
      (final k) => _ids(user, k).isNotEmpty,
      orElse: () => FavoriteKind.shows,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final bool loggedIn = ref.watch(isLoggedInProvider);
    final AsyncValue<entity.User?> profile = ref.watch(userProfileProvider);
    final entity.User? user = profile.value;

    if (user != null) {
      for (final FavoriteKind k in FavoriteKind.values) {
        final List<String> known = _known[k]!;
        for (final String id in _ids(user, k)) {
          if (!known.contains(id)) known.add(id);
        }
      }
    }

    final FavoriteKind kind = _effective(user);
    final int total = user == null
        ? 0
        : user.favoriteShows.length +
            user.favoriteStages.length +
            user.favoritePlayers.length;

    final Widget body;
    if (!loggedIn || (profile.hasValue && user == null)) {
      body = WebStatePanel(
        icon: Icons.favorite_border_rounded,
        title: 'Favorilerin hesabında saklanır',
        message: 'Beğendiğin oyunları, sahneleri ve sanatçıları burada '
            'görmek için giriş yap.',
        actionLabel: 'Giriş yap',
        onAction: () => NavigationHandler.goToLogin(context),
      );
    } else if (profile.hasError && user == null) {
      body = WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Favorilerin yüklenemedi',
        message: 'Listene şu an ulaşamadık; favorilerin silinmedi. '
            'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(userProfileProvider),
      );
    } else if (user == null) {
      body = const _GridSkeleton();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            kind: kind,
            user: user,
            filter: _filter,
            onlyOnStage: _onlyOnStage,
            onKind: (final k) => setState(() {
              _kind = k;
              _filter.clear();
            }),
            onFilter: () => setState(() {}),
            onToggleOnStage: (final v) => setState(() => _onlyOnStage = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          switch (kind) {
            FavoriteKind.shows => _ShowsGrid(
                known: _known[kind]!,
                current: user.favoriteShows,
                query: _filter.text,
                onlyOnStage: _onlyOnStage,
                onRemove: (final id) => _remove(kind, id),
              ),
            FavoriteKind.stages => _StagesList(
                known: _known[kind]!,
                current: user.favoriteStages,
                query: _filter.text,
                onRemove: (final id) => _remove(kind, id),
              ),
            FavoriteKind.players => _PlayersList(
                known: _known[kind]!,
                current: user.favoritePlayers,
                query: _filter.text,
                onRemove: (final id) => _remove(kind, id),
              ),
          },
        ],
      );
    }

    return WebAccountShell(
      current: WebAccountSection.favorites,
      title: 'Favorilerim',
      subtitle: user == null || total == 0
          ? 'Kenara ayırdığın oyunlar, sahneler ve sanatçılar.'
          : '$total kayıt kenarda: ${user.favoriteShows.length} oyun, '
              '${user.favoriteStages.length} sahne, '
              '${user.favoritePlayers.length} sanatçı.',
      aside: user == null || total == 0 ? null : _Summary(user: user),
      child: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Araç çubuğu
// ─────────────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final FavoriteKind kind;
  final entity.User user;
  final TextEditingController filter;
  final bool onlyOnStage;
  final ValueChanged<FavoriteKind> onKind;
  final VoidCallback onFilter;
  final ValueChanged<bool> onToggleOnStage;

  const _Toolbar({
    required this.kind,
    required this.user,
    required this.filter,
    required this.onlyOnStage,
    required this.onKind,
    required this.onFilter,
    required this.onToggleOnStage,
  });

  int _count(final FavoriteKind k) => switch (k) {
        FavoriteKind.shows => user.favoriteShows.length,
        FavoriteKind.stages => user.favoriteStages.length,
        FavoriteKind.players => user.favoritePlayers.length,
      };

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final FavoriteKind k in FavoriteKind.values)
          SkChip(
            label: k.label,
            icon: k.icon,
            count: _count(k),
            selected: k == kind,
            onTap: () => onKind(k),
          ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 260,
          child: TextField(
            controller: filter,
            onChanged: (final _) => onFilter(),
            style: Sk.ui(context, size: 14, weight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Favorilerde ara',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: filter.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        filter.clear();
                        onFilter();
                      },
                    ),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (kind == FavoriteKind.shows)
          FilterChip(
            label: const Text('Yalnız sahnedekiler'),
            selected: onlyOnStage,
            onSelected: onToggleOnStage,
            showCheckmark: true,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Oyunlar
// ─────────────────────────────────────────────────────────────────────────

String _fold(final String s) => s
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

class _ShowsGrid extends ConsumerWidget {
  final List<String> known;
  final List<String> current;
  final String query;
  final bool onlyOnStage;
  final ValueChanged<String> onRemove;

  const _ShowsGrid({
    required this.known,
    required this.current,
    required this.query,
    required this.onlyOnStage,
    required this.onRemove,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (current.isEmpty) {
      return WebStatePanel(
        icon: Icons.theater_comedy_outlined,
        title: 'Henüz favori oyunun yok',
        message: 'Bir oyunun sayfasındaki kalbe dokun; burada seansları ve '
            'fiyatıyla birlikte toplanır.',
        actionLabel: 'Oyunlara göz at',
        onAction: () => NavigationHandler.goToDiscover(context),
      );
    }
    final async = ref.watch(showsByIdsProvider(known));
    final Set<String>? activeIds = ref
        .watch(activeShowsProvider(false))
        .value
        ?.map((final s) => s.id)
        .toSet();
    final Map<String, List<Event>> events =
        ref.watch(eventsByShowMapProvider(false)).value ?? const {};

    return async.when(
      loading: () => const _GridSkeleton(),
      error: (final _, final __) => WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Favori oyunların yüklenemedi',
        message: 'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(showsByIdsProvider(known)),
      ),
      data: (final List<Show> loaded) {
        final String q = _fold(query.trim());
        final List<Show> shows = [
          for (final String id in current)
            for (final Show s in loaded)
              if (s.id == id) s,
        ].where((final s) {
          if (q.isNotEmpty && !_fold(s.name).contains(q)) return false;
          if (onlyOnStage && activeIds != null && !activeIds.contains(s.id)) {
            return false;
          }
          return true;
        }).toList();
        if (shows.isEmpty) {
          return WebStatePanel(
            icon: Icons.search_off_rounded,
            title: 'Sonuç yok',
            message: loaded.isEmpty
                ? 'Favori oyunların artık yayında görünmüyor.'
                : 'Bu süzgece uyan favori oyunun yok.',
          );
        }
        return LayoutBuilder(builder: (final context, final box) {
          final _PosterGrid g = _PosterGrid.of(box.maxWidth);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: g.delegate,
            itemCount: shows.length,
            itemBuilder: (final context, final i) {
              final Show s = shows[i];
              return _ShowCard(
                key: ValueKey('fav-show-${s.id}'),
                show: s,
                closed: activeIds != null && !activeIds.contains(s.id),
                next: nextSessionHint(events[s.id]),
                onRemove: () => onRemove(s.id),
              );
            },
          );
        });
      },
    );
  }
}

/// Afiş ızgarası: sütun sayısı genişliğe göre, afiş 3:4 sabit, altında sabit
/// metin bloğu — kartlar başlık uzunluğundan bağımsız hizalı kalır.
class _PosterGrid {
  final int cols;
  final double extent;
  const _PosterGrid(this.cols, this.extent);

  static const double textBlock = 122;

  factory _PosterGrid.of(final double width) {
    final int cols = (width / 220).floor().clamp(2, 6);
    final double w = (width - (cols - 1) * AppSpacing.lg) / cols;
    return _PosterGrid(cols, w * 4 / 3 + textBlock);
  }

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisExtent: extent,
      );
}

class _ShowCard extends StatelessWidget {
  final Show show;
  final bool closed;
  final NextSessionHint? next;
  final VoidCallback onRemove;

  const _ShowCard({
    super.key,
    required this.show,
    required this.closed,
    required this.next,
    required this.onRemove,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String meta = [
      if (show.category.trim().isNotEmpty) show.category.trim(),
      if (show.duration.trim().isNotEmpty) show.duration.trim(),
    ].join(' · ');
    final String when = next != null
        ? skDateTime(next!.when)
        : (show.hasExternalTicketing ? 'Başka platformda' : 'Seans yok');
    final String? price = next?.price == null ? null : 'Başlangıç ${skPrice(next!.price!)}';

    return Opacity(
      opacity: closed ? 0.62 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PressScale(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NavigationHandler.goToShow(context, show.id, show.name);
                  },
                  semanticLabel: '${show.name}, oyunu aç',
                  child: SkImage(
                      url: show.imageUrl, radius: AppRadius.sm, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: 'Favorilerden çıkar',
                    child: Semantics(
                      button: true,
                      label: '${show.name} favorilerden çıkar',
                      excludeSemantics: true,
                      child: Material(
                        color: cs.surface.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onRemove,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.favorite_rounded,
                                size: 22, color: cs.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (closed)
                  const Positioned(
                      left: 8,
                      top: 8,
                      child: SkBadge(label: 'Perdesi kapandı')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Sk.display(context, size: 17, height: 1.15)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context,
                    size: 12.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500)),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 12.5, color: cs.primary, weight: FontWeight.w800)),
              ),
            ],
          ),
          if (price != null)
            Text(price,
                style: Sk.ui(context,
                    size: 12.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sahneler ve sanatçılar
// ─────────────────────────────────────────────────────────────────────────

class _StagesList extends ConsumerWidget {
  final List<String> known;
  final List<String> current;
  final String query;
  final ValueChanged<String> onRemove;

  const _StagesList({
    required this.known,
    required this.current,
    required this.query,
    required this.onRemove,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (current.isEmpty) {
      return WebStatePanel(
        icon: Icons.location_on_outlined,
        title: 'Henüz favori sahnen yok',
        message: 'Sevdiğin salonları kenara ayır; yeni oyunları bir bakışta '
            'gör.',
        actionLabel: 'Yakındaki sahneler',
        onAction: () => NavigationHandler.goToNearby(context),
      );
    }
    final async = ref.watch(stagesByIdsProvider(known));
    return async.when(
      loading: () => const _RowsSkeleton(),
      error: (final _, final __) => WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Favori sahnelerin yüklenemedi',
        message: 'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(stagesByIdsProvider(known)),
      ),
      data: (final List<Stage> loaded) {
        final String q = _fold(query.trim());
        final List<Stage> items = [
          for (final String id in current)
            for (final Stage s in loaded)
              if (s.id == id && (q.isEmpty || _fold(s.name).contains(q))) s,
        ];
        if (items.isEmpty) {
          return const WebStatePanel(
              icon: Icons.search_off_rounded,
              title: 'Sonuç yok',
              message: 'Bu aramaya uyan favori sahnen yok.');
        }
        return _TwoColumn(children: [
          for (final Stage s in items)
            _EntityRow(
              key: ValueKey('fav-stage-${s.id}'),
              imageUrl: s.imageUrl,
              title: s.name,
              subtitle: s.address,
              icon: Icons.location_on_outlined,
              onOpen: () => NavigationHandler.goToStage(context, s.id, s.name),
              onRemove: () => onRemove(s.id),
            ),
        ]);
      },
    );
  }
}

class _PlayersList extends ConsumerWidget {
  final List<String> known;
  final List<String> current;
  final String query;
  final ValueChanged<String> onRemove;

  const _PlayersList({
    required this.known,
    required this.current,
    required this.query,
    required this.onRemove,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (current.isEmpty) {
      return WebStatePanel(
        icon: Icons.person_outline_rounded,
        title: 'Henüz favori sanatçın yok',
        message: 'Sevdiğin oyuncuları takip et; oynadıkları oyunlar burada '
            'görünür.',
        actionLabel: 'Keşfet',
        onAction: () => NavigationHandler.goToDiscover(context),
      );
    }
    final async = ref.watch(playersByIdsProvider(known));
    return async.when(
      loading: () => const _RowsSkeleton(),
      error: (final _, final __) => WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Favori sanatçıların yüklenemedi',
        message: 'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(playersByIdsProvider(known)),
      ),
      data: (final List<Player> loaded) {
        final String q = _fold(query.trim());
        final List<Player> items = [
          for (final String id in current)
            for (final Player p in loaded)
              if (p.id == id &&
                  (q.isEmpty ||
                      _fold('${p.firstName} ${p.lastName}').contains(q)))
                p,
        ];
        if (items.isEmpty) {
          return const WebStatePanel(
              icon: Icons.search_off_rounded,
              title: 'Sonuç yok',
              message: 'Bu aramaya uyan favori sanatçın yok.');
        }
        return _TwoColumn(children: [
          for (final Player p in items)
            Builder(builder: (final context) {
              final String name = '${p.firstName} ${p.lastName}'.trim();
              final int n = p.nowShowsId.length;
              return _EntityRow(
                key: ValueKey('fav-player-${p.id}'),
                imageUrl: p.imageUrl,
                title: name.isEmpty ? 'Sanatçı' : name,
                subtitle: n == 0 ? null : '$n güncel oyun',
                icon: Icons.person_outline_rounded,
                onOpen: () => NavigationHandler.goToPlayer(
                    context, p.id, name.isEmpty ? p.id : name),
                onRemove: () => onRemove(p.id),
              );
            }),
        ]);
      },
    );
  }
}

class _TwoColumn extends StatelessWidget {
  final List<Widget> children;
  const _TwoColumn({required this.children});

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final box) {
          final int cols = box.maxWidth >= 640 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 88,
            children: children,
          );
        },
      );
}

class _EntityRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _EntityRow({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.icon,
    required this.onOpen,
    required this.onRemove,
    this.subtitle,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onOpen();
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SkImage(
                        url: imageUrl,
                        width: 60,
                        height: 60,
                        radius: AppRadius.sm,
                        fallbackIcon: icon),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Sk.ui(context,
                                  size: 15, weight: FontWeight.w800)),
                          if (subtitle != null && subtitle!.trim().isNotEmpty)
                            Text(subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Sk.ui(context,
                                    size: 12.5,
                                    color: cs.onSurfaceVariant,
                                    weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Favorilerden çıkar',
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.favorite_rounded, color: cs.error),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yapışkan özet
// ─────────────────────────────────────────────────────────────────────────

class _Summary extends ConsumerWidget {
  final entity.User user;
  const _Summary({required this.user});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Show> shows = user.favoriteShows.isEmpty
        ? const []
        : (ref.watch(showsByIdsProvider(user.favoriteShows)).value ??
            const []);
    final Map<String, List<Event>> events =
        ref.watch(eventsByShowMapProvider(false)).value ?? const {};

    Show? nextShow;
    NextSessionHint? nextHint;
    for (final Show s in shows) {
      final NextSessionHint? h = nextSessionHint(events[s.id]);
      if (h == null) continue;
      if (nextHint == null || h.when.isBefore(nextHint.when)) {
        nextHint = h;
        nextShow = s;
      }
    }
    final Show? target = nextShow;
    final NextSessionHint? hint = nextHint;

    Widget stat(final IconData icon, final String label, final int n) => Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(label,
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600))),
            Text('$n',
                style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
          ],
        );

    return WebPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ÖZET',
              style: Sk.ui(context,
                  size: 11,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w800,
                  letterSpacing: 1.8)),
          const SizedBox(height: AppSpacing.lg),
          stat(Icons.theater_comedy_outlined, 'Oyun', user.favoriteShows.length),
          const SizedBox(height: AppSpacing.md),
          stat(Icons.location_on_outlined, 'Sahne', user.favoriteStages.length),
          const SizedBox(height: AppSpacing.md),
          stat(Icons.person_outline_rounded, 'Sanatçı',
              user.favoritePlayers.length),
          Divider(height: AppSpacing.xxxl, color: cs.outlineVariant),
          Text('Sıradaki seans',
              style: Sk.ui(context, size: 13, weight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          if (target == null || hint == null)
            Text('Favori oyunlarının yaklaşan seansı yok.',
                style: Sk.ui(context,
                    size: 13.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500,
                    height: 1.45))
          else ...[
            Text(target.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Sk.display(context, size: 18, height: 1.15)),
            const SizedBox(height: 2),
            Text(skDateTime(hint.when),
                style: Sk.ui(context,
                    size: 13.5, color: cs.primary, weight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  NavigationHandler.goToShow(context, target.id, target.name),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Oyuna git'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// İskeletler
// ─────────────────────────────────────────────────────────────────────────

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: LayoutBuilder(builder: (final context, final box) {
          final _PosterGrid g = _PosterGrid.of(box.maxWidth);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: g.delegate,
            itemCount: g.cols * 2,
            itemBuilder: (final _, final __) => const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: SkBone(
                        height: double.infinity, radius: AppRadius.sm)),
                SizedBox(height: 12),
                SkBone(height: 16, width: 140, radius: 6),
                SizedBox(height: 8),
                SkBone(height: 12, width: 90, radius: 6),
                SizedBox(height: 60),
              ],
            ),
          );
        }),
      );
}

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton();

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: Column(
          children: [
            SkBone(height: 88, radius: AppRadius.md),
            SizedBox(height: AppSpacing.md),
            SkBone(height: 88, radius: AppRadius.md),
            SizedBox(height: AppSpacing.md),
            SkBone(height: 88, radius: AppRadius.md),
          ],
        ),
      );
}
