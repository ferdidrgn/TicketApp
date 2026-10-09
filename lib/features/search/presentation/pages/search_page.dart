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
// Kural (sahibinin kararı): her kategori YATAY bir şerittir ve şeritte en
// fazla 10 öğe yan yana durur. Başlığın yanındaki "Tümü" o kategoriyi
// AŞAĞI DOĞRU ızgaraya açar (yerinde genişler), "Daralt" geri toplar.
//
// Mantık: searchQueryProvider / searchFilterProvider / searchResultProvider.

const List<String> _kFacets = ['Tümü', 'Oyunlar', 'Oyuncular', 'Mekânlar', 'Topluluklar'];
const String _kRecentSearches = 'tiyatrol.recent_searches';
const int _kRailMax = 10;

enum _Sec { genres, shows, players, stages, teams }

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
  final Set<_Sec> _open = {};

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
    ].take(10).toList());
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

  void _toggle(final _Sec s) {
    HapticFeedback.selectionClick();
    setState(() => _open.contains(s) ? _open.remove(s) : _open.add(s));
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

  void _openStage(final Stage s) {
    _remember(_text.text);
    NavigationHandler.goToStage(context, s.id, s.name,
        heroTag: TiyatrolHeroTags.stage(s.id, 'search'),
        imageUrl: s.imageUrl,
        title: s.name);
  }

  void _openTeam(final Team t) {
    _remember(_text.text);
    NavigationHandler.goToTeam(context, t.id, t.name,
        imageUrl: t.imageUrl, title: t.name);
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
        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
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
                data: (final data) =>
                    _results(context, data, query, w, gutter, w >= 1024),
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
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: focused ? cs.primary : Colors.transparent,
          width: 1.8,
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
          Icon(Icons.search_rounded,
              color: focused ? cs.primary : cs.onSurfaceVariant),
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
    final double width,
    final double gutter,
    final bool desktop,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool browsing = query.trim().isEmpty;
    final List<BrowseCategory> categories = browseCategoriesOf(data.shows);
    final String? activeCat =
        categories.any((final c) => c.key == _category) ? _category : null;
    final List<Show> shows = activeCat == null
        ? data.shows
        : data.shows
            .where((final s) => browseCategoryKey(s.category) == activeCat)
            .toList();
    final int total = shows.length +
        data.players.length +
        data.stages.length +
        data.teams.length;

    final double inner =
        (width > Sk.maxWidth ? Sk.maxWidth : width) - 2 * gutter;

    Widget pad(final Widget child, {final double top = 0}) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );

    final List<Widget> blocks = [];

    // ── Başlık / sonuç sayısı ──
    blocks.add(pad(
      browsing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ne izlemek\nistersin?',
                    style: Sk.display(context, size: 34, height: 1.05)),
                const SizedBox(height: 6),
                Text('Oyunları, oyuncuları ve sahneleri keşfet.',
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w500)),
              ],
            )
          : Text(
              total == 0
                  ? '“${query.trim()}” için sonuç yok'
                  : '$total sonuç · “${query.trim()}”',
              style: Sk.ui(context,
                  size: 13,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w700),
            ),
      top: 18,
    ));

    // ── Son aramalar (yatay) ──
    if (browsing && _recents.isNotEmpty) {
      blocks.add(Padding(
        padding: const EdgeInsets.only(top: 26),
        child: _HRail(
          gutter: gutter,
          width: width,
          height: 44,
          title: 'Son aramalar',
          actionLabel: 'Temizle',
          onAction: () => _saveRecents(const []),
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
      ));
    }

    // ── Popüler aramalar: gerçek oyun adları (yatay) ──
    if (browsing && data.shows.isNotEmpty) {
      blocks.add(Padding(
        padding: const EdgeInsets.only(top: 22),
        child: _HRail(
          gutter: gutter,
          width: width,
          height: 44,
          title: 'Şunlara göz at',
          children: [
            for (final Show s in data.shows.take(_kRailMax))
              ActionChip(
                label: Text(s.name),
                avatar: const Icon(Icons.north_east_rounded, size: 16),
                onPressed: () => _apply(s.name),
              ),
          ],
        ),
      ));
    }

    // ── Türler ──
    if (browsing && categories.length > 1) {
      blocks.add(_Section<BrowseCategory>(
        key: const ValueKey<String>('sec-genres'),
        title: 'Türler',
        subtitle: 'Bir tür seç, oyunlar süzülsün',
        items: categories,
        open: _open.contains(_Sec.genres),
        onToggle: () => _toggle(_Sec.genres),
        gutter: gutter,
        width: width,
        inner: inner,
        railW: 210,
        railH: 110,
        minCell: 210,
        gap: 14,
        builder: (final c, final w) => SizedBox(
          width: w,
          height: 110,
          child: _GenreTile(
            category: c,
            selected: activeCat == c.key,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = activeCat == c.key ? null : c.key);
              final int f = ref.read(searchFilterProvider);
              if (f != 0 && f != 1) {
                ref.read(searchFilterProvider.notifier).setFilter(1);
              }
            },
          ),
        ),
      ));
    }

    if (total == 0) {
      blocks.add(SizedBox(
        height: 360,
        child: SkEmpty(
          icon: Icons.search_off_rounded,
          title: browsing ? 'Henüz içerik yok' : 'Bulamadık',
          message: browsing
              ? 'Katalog dolunca burada oyunları, oyuncuları ve mekânları göreceksin.'
              : 'Yazımı kontrol et ya da başka bir ad dene.',
          actionLabel: browsing ? null : 'Aramayı temizle',
          onAction: browsing ? null : _clear,
        ),
      ));
    }

    // ── Oyunlar ──
    if (shows.isNotEmpty) {
      blocks.add(_Section<Show>(
        key: const ValueKey<String>('sec-shows'),
        title: browsing ? 'Önerilen oyunlar' : 'Oyunlar',
        subtitle: activeCat == null ? null : 'Tür: ${categories.firstWhere((final c) => c.key == activeCat).label}',
        items: shows,
        open: _open.contains(_Sec.shows),
        onToggle: () => _toggle(_Sec.shows),
        gutter: gutter,
        width: width,
        inner: inner,
        railW: 158,
        railH: 158 * 1.5,
        minCell: 158,
        gap: 14,
        builder: (final s, final w) => _ShowCard(
          show: s,
          width: w,
          query: query,
          onTap: () => _openShow(s),
        ),
      ));
    }

    // ── Oyuncular ──
    if (data.players.isNotEmpty) {
      blocks.add(_Section<Player>(
        key: const ValueKey<String>('sec-players'),
        title: 'Oyuncular',
        items: data.players,
        open: _open.contains(_Sec.players),
        onToggle: () => _toggle(_Sec.players),
        gutter: gutter,
        width: width,
        inner: inner,
        railW: 124,
        railH: 244,
        minCell: 124,
        gap: 14,
        builder: (final p, final w) => _PlayerCard(
          player: p,
          query: query,
          onTap: () => _openPlayer(p),
        ),
      ));
    }

    // ── Mekânlar ──
    if (data.stages.isNotEmpty) {
      blocks.add(_Section<Stage>(
        key: const ValueKey<String>('sec-stages'),
        title: 'Mekânlar',
        items: data.stages,
        open: _open.contains(_Sec.stages),
        onToggle: () => _toggle(_Sec.stages),
        gutter: gutter,
        width: width,
        inner: inner,
        railW: 270,
        railH: 168,
        minCell: 270,
        gap: 14,
        builder: (final s, final w) => _StageCard(
          stage: s,
          width: w,
          query: query,
          onTap: () => _openStage(s),
        ),
      ));
    }

    // ── Topluluklar ──
    if (data.teams.isNotEmpty) {
      blocks.add(_Section<Team>(
        key: const ValueKey<String>('sec-teams'),
        title: 'Topluluklar',
        items: data.teams,
        open: _open.contains(_Sec.teams),
        onToggle: () => _toggle(_Sec.teams),
        gutter: gutter,
        width: width,
        inner: inner,
        railW: 96,
        railH: 132,
        minCell: 96,
        gap: 14,
        builder: (final t, final w) => _TeamCard(
          team: t,
          query: query,
          onTap: () => _openTeam(t),
        ),
      ));
    }

    blocks.add(desktop
        ? const Padding(padding: EdgeInsets.only(top: 72), child: Footer())
        : const SizedBox(height: 130));

    return ScrollConfiguration(
      behavior: const SkScrollBehavior(),
      child: ListView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.zero,
        children: blocks,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ŞERİT + AŞAĞI AÇILAN IZGARA
// ═════════════════════════════════════════════════════════════════════════════

/// Yatay, başlıklı basit şerit (çipler için).
class _HRail extends StatelessWidget {
  final double gutter;
  final double width;
  final double height;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  const _HRail({
    required this.gutter,
    required this.width,
    required this.height,
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: SkSectionHead(
                    title: title, actionLabel: actionLabel, onAction: onAction),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, final i) => children[i],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Bir kategori: üstte başlık + "Tümü", altında en fazla 10 öğelik yatay
/// şerit. "Tümü"ye basınca şerit YERİNDE aşağı doğru ızgaraya genişler.
class _Section<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> items;
  final bool open;
  final VoidCallback onToggle;
  final double gutter;
  final double width;
  final double inner;
  final double railW;
  final double railH;
  final double minCell;
  final double gap;
  final Widget Function(T item, double width) builder;

  const _Section({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.open,
    required this.onToggle,
    required this.gutter,
    required this.width,
    required this.inner,
    required this.railW,
    required this.railH,
    required this.minCell,
    required this.gap,
    required this.builder,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool more = items.length > _kRailMax;
    final List<T> railItems = items.take(_kRailMax).toList();

    final Widget content;
    if (open) {
      final int cols =
          ((inner + gap) / (minCell + gap)).floor().clamp(1, 12).toInt();
      final double cell = (inner - gap * (cols - 1)) / cols;
      content = Padding(
        key: const ValueKey<String>('grid'),
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: Wrap(
          spacing: gap,
          runSpacing: 18,
          children: [
            for (int i = 0; i < items.length; i++)
              SizedBox(
                width: cell,
                child: Reveal(
                  index: i % cols,
                  dy: 10,
                  child: builder(items[i], cell),
                ),
              ),
          ],
        ),
      );
    } else {
      content = SizedBox(
        key: const ValueKey<String>('rail'),
        height: railH,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          itemCount: railItems.length + (more ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (final context, final i) {
            if (i == railItems.length) {
              return PressScale(
                onTap: onToggle,
                semanticLabel: '$title tümünü göster',
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: cs.primary, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_downward_rounded,
                            color: cs.onPrimary),
                      ),
                      const SizedBox(height: 10),
                      Text('+${items.length - _kRailMax}',
                          style: Sk.display(context, size: 22, height: 1.0)),
                      Text('daha',
                          style: Sk.ui(context,
                              size: 12,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }
            return builder(railItems[i], railW);
          },
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
        child: Padding(
          padding: const EdgeInsets.only(top: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(title,
                                style: Sk.display(context,
                                    size: 24, height: 1.1)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle ?? '${items.length} sonuç',
                            style: Sk.ui(context,
                                size: 12.5,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (more || open)
                      PressScale(
                        onTap: onToggle,
                        semanticLabel: open ? 'Daralt' : 'Tümünü göster',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(open ? 'Daralt' : 'Tümü',
                                  style: Sk.ui(context,
                                      size: 13,
                                      color: cs.onSecondaryContainer,
                                      weight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: open ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 18, color: cs.onSecondaryContainer),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  layoutBuilder: (final current, final previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KARTLAR
// ═════════════════════════════════════════════════════════════════════════════

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

/// Afişin üstüne yazılmış başlıklı oyun kartı (dergi kapağı).
class _ShowCard extends StatelessWidget {
  final Show show;
  final double width;
  final String query;
  final VoidCallback onTap;

  const _ShowCard({
    required this.show,
    required this.width,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticLabel: show.name,
      child: Container(
        width: width,
        height: width * 1.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: skSoftShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TiyatrolHero(
                tag: TiyatrolHeroTags.show(show.id, 'search'),
                child: SkImage(url: show.imageUrl),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.84),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
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
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (show.category.trim().isNotEmpty)
                      Text(show.category.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 11,
                              color: Colors.white70,
                              weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    _highlight(
                      context,
                      show.name,
                      query,
                      Sk.display(context,
                          size: 16, color: Colors.white, height: 1.1),
                      maxLines: 3,
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
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final String query;
  final VoidCallback onTap;

  const _PlayerCard(
      {required this.player, required this.query, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final String name = '${player.firstName} ${player.lastName}'.trim();
    return SizedBox(
      width: 124,
      child: PressScale(
        onTap: onTap,
        semanticLabel: name,
        child: Column(
          children: [
            TiyatrolHero(
              tag: TiyatrolHeroTags.player(player.id, 'search'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(62),
                  boxShadow: skSoftShadow(context, strength: 0.8),
                ),
                child: SkImage(
                  url: player.imageUrl,
                  width: 124,
                  height: 174,
                  radius: 62,
                  fallbackIcon: Icons.person_rounded,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _highlight(
              context,
              name,
              query,
              Sk.ui(context, size: 13, weight: FontWeight.w800, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  final double width;
  final String query;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.width,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) => PressScale(
        onTap: onTap,
        semanticLabel: stage.name,
        child: Container(
          width: width,
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: skSoftShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TiyatrolHero(
                  tag: TiyatrolHeroTags.stage(stage.id, 'search'),
                  child: SkImage(
                      url: stage.imageUrl,
                      fallbackIcon: Icons.location_city_rounded),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _highlight(
                        context,
                        stage.name,
                        query,
                        Sk.display(context,
                            size: 19, color: Colors.white, height: 1.1),
                      ),
                      if (stage.address.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(stage.address.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Sk.ui(context,
                                  size: 12,
                                  color: Colors.white70,
                                  weight: FontWeight.w600)),
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

class _TeamCard extends StatelessWidget {
  final Team team;
  final String query;
  final VoidCallback onTap;

  const _TeamCard(
      {required this.team, required this.query, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      child: PressScale(
        onTap: onTap,
        semanticLabel: team.name,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                    colors: [cs.primary, cs.tertiary, cs.secondary, cs.primary]),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration:
                    BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                child: ClipOval(
                  child: SkImage(
                      url: team.imageUrl,
                      width: 72,
                      height: 72,
                      fallbackIcon: Icons.groups_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _highlight(
              context,
              team.name,
              query,
              Sk.ui(context, size: 12, weight: FontWeight.w800, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreTile extends StatelessWidget {
  final BrowseCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _GenreTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: category.label,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: selected ? cs.primary : Colors.transparent, width: 2.5),
          boxShadow: skSoftShadow(context, strength: 0.6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SkImage(url: category.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.display(context,
                            size: 21, color: Colors.white, height: 1.1)),
                    const SizedBox(height: 2),
                    Text('${category.count} oyun',
                        style: Sk.ui(context,
                            size: 12,
                            color: Colors.white70,
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  right: 12,
                  top: 12,
                  child: Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(final BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkBone(width: 220, height: 34, radius: 10),
            SizedBox(height: 26),
            SkBone(height: 110, radius: 26),
            SizedBox(height: 26),
            Row(children: [
              SkBone(width: 158, height: 236, radius: 26),
              SizedBox(width: 14),
              SkBone(width: 158, height: 236, radius: 26),
            ]),
          ],
        ),
      );
}
