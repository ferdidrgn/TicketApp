import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// ARAMA — "Sahne"
// =============================================================================
//
// Mantık: searchQueryProvider / searchFilterProvider / searchResultProvider
// (değişmedi). Yüzey: odaklanınca canlanan arama alanı, tür çipleri, son
// aramalar (kalıcı), yazdıkça canlı sonuçlar, eşleşen harfler vurgulu,
// afiş ızgarası + oyuncu/mekân/topluluk satırları. Tek yüzey: telefon,
// tablet, web.

const List<String> _kFacets = ['Tümü', 'Oyunlar', 'Oyuncular', 'Mekânlar', 'Topluluklar'];
const String _kRecentSearches = 'tiyatrol.recent_searches';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  String? _category;
  List<String> _recents = const [];

  @override
  void initState() {
    super.initState();
    _text.text = ref.read(searchQueryProvider);
    _focus.addListener(() => setState(() {}));
    _loadRecents();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recents = p.getStringList(_kRecentSearches) ?? const []);
  }

  Future<void> _saveRecents(final List<String> next) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setStringList(_kRecentSearches, next);
    if (mounted) setState(() => _recents = next);
  }

  Future<void> _remember(final String raw) async {
    final String clean = raw.trim();
    if (clean.length < 2) return;
    await _saveRecents([
      clean,
      ..._recents.where((final r) => r.toLowerCase() != clean.toLowerCase()),
    ].take(8).toList());
  }

  void _setQuery(final String v) {
    ref.read(searchQueryProvider.notifier).update(v);
    setState(() {});
  }

  void _apply(final String v) {
    HapticFeedback.selectionClick();
    _text.value = TextEditingValue(
        text: v, selection: TextSelection.collapsed(offset: v.length));
    _setQuery(v);
  }

  void _clear() {
    _text.clear();
    _setQuery('');
    _focus.requestFocus();
  }

  void _openShow(final Show s) {
    _remember(_text.text);
    NavigationHandler.goToShow(context, s.id, s.name,
        heroTag: TiyatrolHeroTags.show(s.id, 'search'),
        imageUrl: s.imageUrl,
        title: s.name);
  }

  void _openPlayer(final Player p) {
    _remember(_text.text);
    final String n = '${p.firstName} ${p.lastName}'.trim();
    NavigationHandler.goToPlayer(context, p.id, n,
        heroTag: TiyatrolHeroTags.player(p.id, 'search'),
        imageUrl: p.imageUrl,
        title: n);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int filter = ref.watch(searchFilterProvider);
    final String query = ref.watch(searchQueryProvider);
    final AsyncValue<SearchResultState> state = ref.watch(searchResultProvider);

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scroll,
      onRefresh: () => ref.invalidate(searchResultProvider),
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
      ),
      child: LayoutBuilder(builder: (final context, final box) {
        final double w = box.maxWidth;
        final double gutter = Sk.gutter(w);
        final bool desktop = w >= 1024;
        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            PressScale(
                              onTap: () =>
                                  NavigationHandler.smartGoBack(context),
                              semanticLabel: 'Geri dön',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back_rounded,
                                    color: cs.onSurface),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _field(cs)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _kFacets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (final context, final i) => SkChip(
                              label: _kFacets[i],
                              selected: filter == i,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(searchFilterProvider.notifier)
                                    .setFilter(i);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: state.isLoading && state.hasValue ? 2 : 0,
              child: const LinearProgressIndicator(minHeight: 2),
            ),
            Expanded(
              child: state.when(
                loading: () => const _Skeleton(),
                error: (_, __) => SkEmpty(
                  icon: Icons.cloud_off_rounded,
                  title: 'Arama yüklenemedi',
                  message: 'Bağlantını kontrol edip tekrar dene.',
                  actionLabel: 'Tekrar dene',
                  onAction: () => ref.invalidate(searchResultProvider),
                ),
                data: (final data) => _results(
                    context, data, query, filter, w, gutter, desktop),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─── arama alanı ─────────────────────────────────────────────────────────

  Widget _field(final ColorScheme cs) {
    final bool focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: focused ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
          width: focused ? 1.8 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey<bool>(focused),
              color: focused ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Oyun, oyuncu, mekân ya da topluluk ara',
              child: TextField(
                controller: _text,
                focusNode: _focus,
                autofocus: true,
                onChanged: _setQuery,
                onSubmitted: (final v) {
                  _remember(v);
                  _focus.unfocus();
                },
                textInputAction: TextInputAction.search,
                style: Sk.ui(context, size: 16, weight: FontWeight.w600),
                cursorColor: cs.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Oyun, oyuncu, mekân ara',
                  hintStyle: Sk.ui(context,
                      size: 16,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w500),
                ),
              ),
            ),
          ),
          if (_text.text.isNotEmpty)
            IconButton(
              tooltip: 'Aramayı temizle',
              onPressed: _clear,
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // ─── sonuçlar ────────────────────────────────────────────────────────────

  Widget _results(
    final BuildContext context,
    final SearchResultState data,
    final String query,
    final int filter,
    final double width,
    final double gutter,
    final bool desktop,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool browsing = query.trim().isEmpty;
    final List<BrowseCategory> categories = browseCategoriesOf(data.shows);
    final String? activeCat = categories.any((final c) => c.key == _category)
        ? _category
        : null;
    final List<Show> shows = activeCat == null
        ? data.shows
        : data.shows
            .where((final s) => browseCategoryKey(s.category) == activeCat)
            .toList();
    final int total =
        shows.length + data.players.length + data.stages.length + data.teams.length;

    final double inner = (width > Sk.maxWidth ? Sk.maxWidth : width) - 2 * gutter;
    final int cols = (inner / 176).floor().clamp(2, 6);
    final double cellW = (inner - (cols - 1) * 14) / cols;

    final List<Widget> slivers = [];

    SliverToBoxAdapter box(final Widget child, {final double top = 0}) =>
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
                child: child,
              ),
            ),
          ),
        );

    if (browsing) {
      if (_recents.isNotEmpty) {
        slivers.add(box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkSectionHead(
                title: 'Son aramalar',
                actionLabel: 'Temizle',
                onAction: () => _saveRecents(const []),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final String r in _recents)
                    InputChip(
                      label: Text(r),
                      avatar: const Icon(Icons.history_rounded, size: 18),
                      onPressed: () => _apply(r),
                      onDeleted: () => _saveRecents(
                          _recents.where((final x) => x != r).toList()),
                      deleteButtonTooltipMessage: 'Kaldır',
                    ),
                ],
              ),
            ],
          ),
          top: 18,
        ));
      }
      if (categories.length > 1) {
        slivers.add(box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkSectionHead(title: 'Türe göre gez'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final BrowseCategory c in categories)
                    SkChip(
                      label: c.label,
                      count: c.count,
                      selected: activeCat == c.key,
                      onTap: () {
                        setState(
                            () => _category = activeCat == c.key ? null : c.key);
                        final int f = ref.read(searchFilterProvider);
                        if (f != 0 && f != 1) {
                          ref.read(searchFilterProvider.notifier).setFilter(1);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
          top: 26,
        ));
      }
    } else {
      slivers.add(box(
        Text(
          total == 0
              ? '“${query.trim()}” için sonuç yok'
              : '$total sonuç · “${query.trim()}”',
          style: Sk.ui(context,
              size: 13,
              color: cs.onSurfaceVariant,
              weight: FontWeight.w700),
        ),
        top: 14,
      ));
    }

    if (total == 0) {
      slivers.add(SliverToBoxAdapter(
        child: SizedBox(
          height: 380,
          child: SkEmpty(
            icon: Icons.search_off_rounded,
            title: browsing ? 'Henüz içerik yok' : 'Bulamadık',
            message: browsing
                ? 'Katalog dolunca burada oyunları, oyuncuları ve mekânları göreceksin.'
                : 'Yazımı kontrol et ya da başka bir ad dene. Önerilen oyunlara göz atabilirsin.',
            actionLabel: browsing ? null : 'Aramayı temizle',
            onAction: browsing ? null : _clear,
          ),
        ),
      ));
    }

    if (shows.isNotEmpty) {
      slivers.add(box(
        SkSectionHead(
          title: browsing ? 'Önerilen oyunlar' : 'Oyunlar',
          subtitle: '${shows.length} oyun',
        ),
        top: 28,
      ));
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(
            _side(width, gutter), 14, _side(width, gutter), 0),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 18,
            crossAxisSpacing: 14,
            mainAxisExtent: cellW * 1.48 + 66,
          ),
          delegate: SliverChildBuilderDelegate(
            (final context, final i) => Reveal(
              index: i % cols,
              child: _ShowCell(
                show: shows[i],
                width: cellW,
                query: query,
                onTap: () => _openShow(shows[i]),
              ),
            ),
            childCount: shows.length,
          ),
        ),
      ));
    }

    if (data.players.isNotEmpty) {
      slivers.add(box(
        SkSectionHead(
            title: 'Oyuncular', subtitle: '${data.players.length} kişi'),
        top: 34,
      ));
      slivers.add(SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
            child: SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                itemCount: data.players.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (final context, final i) => _PlayerCell(
                  player: data.players[i],
                  query: query,
                  onTap: () => _openPlayer(data.players[i]),
                ),
              ),
            ),
          ),
        ),
      ));
    }

    if (data.stages.isNotEmpty) {
      slivers.add(box(
        SkSectionHead(
            title: 'Mekânlar', subtitle: '${data.stages.length} sahne'),
        top: 30,
      ));
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(
            _side(width, gutter), 14, _side(width, gutter), 0),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 520,
            mainAxisExtent: 104,
            mainAxisSpacing: 12,
            crossAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (final context, final i) => _StageRow(
              stage: data.stages[i],
              query: query,
              onTap: () {
                _remember(_text.text);
                final Stage s = data.stages[i];
                NavigationHandler.goToStage(context, s.id, s.name,
                    imageUrl: s.imageUrl, title: s.name);
              },
            ),
            childCount: data.stages.length,
          ),
        ),
      ));
    }

    if (data.teams.isNotEmpty) {
      slivers.add(box(
        SkSectionHead(
            title: 'Topluluklar', subtitle: '${data.teams.length} topluluk'),
        top: 30,
      ));
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(
            _side(width, gutter), 14, _side(width, gutter), 0),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 520,
            mainAxisExtent: 84,
            mainAxisSpacing: 10,
            crossAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (final context, final i) => _TeamRow(
              team: data.teams[i],
              query: query,
              onTap: () {
                _remember(_text.text);
                final Team t = data.teams[i];
                NavigationHandler.goToTeam(context, t.id, t.name,
                    imageUrl: t.imageUrl, title: t.name);
              },
            ),
            childCount: data.teams.length,
          ),
        ),
      ));
    }

    slivers.add(SliverToBoxAdapter(
      child: desktop
          ? const Padding(padding: EdgeInsets.only(top: 72), child: Footer())
          : const SizedBox(height: 130),
    ));

    return ScrollConfiguration(
      behavior: const SkScrollBehavior(),
      child: CustomScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: slivers,
      ),
    );
  }

  /// Ortalanmış `maxWidth` içinde sliver kenar boşluğu.
  double _side(final double width, final double gutter) =>
      width > Sk.maxWidth ? (width - Sk.maxWidth) / 2 + gutter : gutter;
}

// ─── hücreler ───────────────────────────────────────────────────────────────

/// Eşleşen kısmı vurgulayan metin.
Widget _highlight(final BuildContext context, final String text,
    final String query, final TextStyle style,
    {final int maxLines = 2}) {
  final String q = query.trim().toLowerCase();
  final int at = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
  if (at < 0) {
    return Text(text,
        maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style);
  }
  final Color accent = Theme.of(context).colorScheme.primary;
  return RichText(
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(style: style, children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
        text: text.substring(at, at + q.length),
        style: TextStyle(
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.14),
            fontWeight: FontWeight.w900),
      ),
      TextSpan(text: text.substring(at + q.length)),
    ]),
  );
}

class _ShowCell extends StatelessWidget {
  final Show show;
  final double width;
  final String query;
  final VoidCallback onTap;

  const _ShowCell({
    required this.show,
    required this.width,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: show.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TiyatrolHero(
            tag: TiyatrolHeroTags.show(show.id, 'search'),
            child: Stack(
              children: [
                SkImage(
                    url: show.imageUrl,
                    width: width,
                    height: width * 1.48,
                    radius: 18),
                if (show.hasExternalTicketing)
                  const Positioned(
                    left: 8,
                    top: 8,
                    child: SkBadge(
                        label: 'Başka platform',
                        onImage: true,
                        icon: Icons.open_in_new_rounded),
                  )
                else if (show.isRecentlyAdded)
                  const Positioned(
                      left: 8, top: 8, child: SkBadge(label: 'Yeni', accent: true)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _highlight(context, show.name, query,
              Sk.ui(context,
                  size: 14,
                  weight: FontWeight.w800,
                  height: 1.2,
                  color: cs.onSurface)),
          if (show.category.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(show.category.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context,
                      size: 12,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

class _PlayerCell extends StatelessWidget {
  final Player player;
  final String query;
  final VoidCallback onTap;

  const _PlayerCell(
      {required this.player, required this.query, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final String name = '${player.firstName} ${player.lastName}'.trim();
    return SizedBox(
      width: 120,
      child: PressScale(
        onTap: onTap,
        semanticLabel: name,
        child: Column(
          children: [
            TiyatrolHero(
              tag: TiyatrolHeroTags.player(player.id, 'search'),
              child: SkImage(
                url: player.imageUrl,
                width: 120,
                height: 168,
                radius: 60,
                fallbackIcon: Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 10),
            _highlight(
              context,
              name,
              query,
              Sk.ui(context, size: 13, weight: FontWeight.w700, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final Stage stage;
  final String query;
  final VoidCallback onTap;

  const _StageRow(
      {required this.stage, required this.query, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: stage.name,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            SkImage(
                url: stage.imageUrl,
                width: 84,
                height: 84,
                radius: 16,
                fallbackIcon: Icons.location_city_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlight(context, stage.name, query,
                      Sk.ui(context, size: 15, weight: FontWeight.w800)),
                  if (stage.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(stage.address.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final Team team;
  final String query;
  final VoidCallback onTap;

  const _TeamRow(
      {required this.team, required this.query, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: team.name,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SkImage(
                  url: team.imageUrl,
                  width: 56,
                  height: 56,
                  fallbackIcon: Icons.groups_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _highlight(context, team.name, query,
                  Sk.ui(context, size: 15, weight: FontWeight.w800)),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 14,
          runSpacing: 18,
          children: List.generate(
            6,
            (_) => const SkBone(width: 160, height: 280, radius: 18),
          ),
        ),
      );
}
