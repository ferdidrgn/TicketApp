import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_site_header.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../reviews/presentation/widgets/review_widgets.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/domain/next_session.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';

/// ARAMA / KEŞFET — WEB. Mağaza listeleme sayfası düzeni:
/// solda yapışkan süzgeç paneli (ne arıyorsun, tür, görünüm), sağda sonuç
/// başlığı + sıralama + afiş ızgarası; oyuncu/mekân/topluluk sonuçları
/// altta ayrı bloklarda. Mobil uygulamanın arama sayfasından AYRIDIR.
class SearchPageWeb extends ConsumerStatefulWidget {
  const SearchPageWeb({super.key});

  @override
  ConsumerState<SearchPageWeb> createState() => _SearchPageWebState();
}

enum _Sort { relevance, date, price, az }

const Map<_Sort, String> _sortLabels = {
  _Sort.relevance: 'Önerilen',
  _Sort.date: 'En yakın tarih',
  _Sort.price: 'En düşük fiyat',
  _Sort.az: 'A–Z',
};

class _SearchPageWebState extends ConsumerState<SearchPageWeb> {
  final TextEditingController _text = TextEditingController();
  String? _category;
  _Sort _sort = _Sort.relevance;
  bool _onlyUpcoming = false;

  @override
  void initState() {
    super.initState();
    _text.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setQuery(final String v) {
    ref.read(searchQueryProvider.notifier).update(v);
    setState(() {});
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String query = ref.watch(searchQueryProvider);
    final int filter = ref.watch(searchFilterProvider);
    final async = ref.watch(searchResultProvider);
    final SearchResultState? data = async.value;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WebSiteHeader(currentIndex: 1),
            LayoutBuilder(builder: (final context, final box) {
              final double w = box.maxWidth;
              final bool desktop = w >= 1024;
              final double gutter = w >= 1200 ? 48 : (w >= 768 ? 32 : 18);
              final List<Show> allShows = data?.shows ?? const [];
              final List<BrowseCategory> categories =
                  browseCategoriesOf(allShows);

              List<Show> shows = [
                for (final Show s in allShows)
                  if (_category == null ||
                      browseCategoryKey(s.category) == _category)
                    if (!_onlyUpcoming ||
                        data!.nextByShow.containsKey(s.id))
                      s,
              ];
              final Map<String, NextSessionHint> next =
                  data?.nextByShow ?? const {};
              switch (_sort) {
                case _Sort.relevance:
                  break;
                case _Sort.date:
                  shows.sort((a, b) {
                    final DateTime? x = next[a.id]?.when;
                    final DateTime? y = next[b.id]?.when;
                    if (x == null && y == null) return 0;
                    if (x == null) return 1;
                    if (y == null) return -1;
                    return x.compareTo(y);
                  });
                case _Sort.price:
                  shows.sort((a, b) => (next[a.id]?.price ?? 1e9)
                      .compareTo(next[b.id]?.price ?? 1e9));
                case _Sort.az:
                  shows.sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              }

              final Widget side = _Sidebar(
                controller: _text,
                onQuery: _setQuery,
                categories: categories,
                category: _category,
                onCategory: (final v) => setState(() => _category = v),
                filter: filter,
                onFilter: (final i) =>
                    ref.read(searchFilterProvider.notifier).setFilter(i),
                onlyUpcoming: _onlyUpcoming,
                onUpcoming: (final v) => setState(() => _onlyUpcoming = v),
                onClear: () => setState(() {
                  _category = null;
                  _onlyUpcoming = false;
                  _text.clear();
                  ref.read(searchQueryProvider.notifier).update('');
                }),
              );

              final double mainW =
                  (w > 1360 ? 1360 : w) - 2 * gutter - (desktop ? 300 + 40 : 0);
              final Widget results = _Results(
                query: query,
                loading: async.isLoading && data == null,
                shows: shows,
                players: data?.players ?? const [],
                stages: data?.stages ?? const [],
                teams: data?.teams ?? const [],
                next: next,
                sort: _sort,
                onSort: (final v) => setState(() => _sort = v),
                width: mainW,
                showShows: filter == 0 || filter == 1,
                showPlayers: filter == 0 || filter == 2,
                showStages: filter == 0 || filter == 3,
                showTeams: filter == 0 || filter == 4,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: side),
                              const SizedBox(width: 40),
                              Expanded(child: results),
                            ],
                          )
                        : Column(children: [
                            side,
                            const SizedBox(height: 28),
                            results,
                          ]),
                  ),
                ),
              );
            }),
            const SizedBox(height: 72),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQuery;
  final List<BrowseCategory> categories;
  final String? category;
  final ValueChanged<String?> onCategory;
  final int filter;
  final ValueChanged<int> onFilter;
  final bool onlyUpcoming;
  final ValueChanged<bool> onUpcoming;
  final VoidCallback onClear;

  const _Sidebar({
    required this.controller,
    required this.onQuery,
    required this.categories,
    required this.category,
    required this.onCategory,
    required this.filter,
    required this.onFilter,
    required this.onlyUpcoming,
    required this.onUpcoming,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    Widget head(final String t) => Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 12),
          child: Text(t, style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
        );

    Widget option(final String label, final bool sel, final VoidCallback tap,
            {final int? count}) =>
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                Icon(
                    sel
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: sel ? cs.primary : cs.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: Sk.ui(context,
                          size: 14.5,
                          weight: sel ? FontWeight.w800 : FontWeight.w600)),
                ),
                if (count != null)
                  Text('$count',
                      style: Sk.ui(context,
                          size: 13,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
              ]),
            ),
          ),
        );

    const List<String> kinds = ['Tümü', 'Oyunlar', 'Oyuncular', 'Mekânlar', 'Topluluklar'];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Süzgeçler', style: Sk.display(context, size: 24, height: 1.1)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: onQuery,
            decoration: InputDecoration(
              hintText: 'Ne arıyorsun?',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          head('Ne göster'),
          for (int i = 0; i < kinds.length; i++)
            option(kinds[i], filter == i, () => onFilter(i)),
          if (categories.length > 1) ...[
            head('Tür'),
            option('Tüm türler', category == null, () => onCategory(null)),
            for (final BrowseCategory c in categories)
              option(c.label, category == c.key,
                  () => onCategory(category == c.key ? null : c.key),
                  count: c.count),
          ],
          head('Seans'),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onUpcoming(!onlyUpcoming),
              child: Row(children: [
                Icon(
                    onlyUpcoming
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                    color: onlyUpcoming ? cs.primary : cs.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Yaklaşan seansı olanlar',
                      style: Sk.ui(context, size: 14.5, weight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: const StadiumBorder()),
            child: const Text('Süzgeçleri temizle'),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final String query;
  final bool loading;
  final List<Show> shows;
  final List<Player> players;
  final List<Stage> stages;
  final List<Team> teams;
  final Map<String, NextSessionHint> next;
  final _Sort sort;
  final ValueChanged<_Sort> onSort;
  final double width;
  final bool showShows, showPlayers, showStages, showTeams;

  const _Results({
    required this.query,
    required this.loading,
    required this.shows,
    required this.players,
    required this.stages,
    required this.teams,
    required this.next,
    required this.sort,
    required this.onSort,
    required this.width,
    required this.showShows,
    required this.showPlayers,
    required this.showStages,
    required this.showTeams,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final bool anyShows = showShows && shows.isNotEmpty;
    final bool anyPlayers = showPlayers && players.isNotEmpty;
    final bool anyStages = showStages && stages.isNotEmpty;
    final bool anyTeams = showTeams && teams.isNotEmpty;
    final int total =
        (showShows ? shows.length : 0) +
        (showPlayers ? players.length : 0) +
        (showStages ? stages.length : 0) +
        (showTeams ? teams.length : 0);

    final String title = query.trim().isEmpty
        ? 'Tüm oyunlar'
        : '“${query.trim()}” için sonuçlar';

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(56),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Icon(Icons.search_off_rounded, size: 44, color: cs.onSurfaceVariant),
          const SizedBox(height: 14),
          Text('Sonuç bulunamadı',
              style: Sk.ui(context, size: 18, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Başka bir kelime dene ya da süzgeçleri temizle.',
              style: Sk.ui(context,
                  size: 14, color: cs.onSurfaceVariant, weight: FontWeight.w500)),
        ]),
      );
    }

    const double gap = 24;
    final int cols = (width / 220).floor().clamp(2, 5);
    final double cw = (width - gap * (cols - 1)) / cols;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sk.display(context, size: 30, height: 1.1)),
          ),
          if (anyShows) ...[
            Text('${shows.length} oyun',
                style: Sk.ui(context,
                    size: 14,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
            const SizedBox(width: 18),
            DropdownButtonHideUnderline(
              child: DropdownButton<_Sort>(
                value: sort,
                borderRadius: BorderRadius.circular(12),
                items: [
                  for (final _Sort s in _Sort.values)
                    DropdownMenuItem(value: s, child: Text(_sortLabels[s]!)),
                ],
                onChanged: (final v) => v == null ? null : onSort(v),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 24),
        if (anyShows)
          Wrap(spacing: gap, runSpacing: 34, children: [
            for (final Show s in shows)
              SizedBox(width: cw, child: _Card(show: s, next: next[s.id])),
          ]),
        if (anyPlayers) ...[
          const SizedBox(height: 56),
          Text('Oyuncular', style: Sk.display(context, size: 26, height: 1.1)),
          const SizedBox(height: 18),
          Wrap(spacing: 26, runSpacing: 22, children: [
            for (final Player p in players.take(18))
              _PersonChip(
                name: '${p.firstName} ${p.lastName}'.trim(),
                imageUrl: p.imageUrl,
                onTap: () => NavigationHandler.goToPlayer(
                    context, p.id, '${p.firstName} ${p.lastName}'.trim(),
                    imageUrl: p.imageUrl,
                    title: '${p.firstName} ${p.lastName}'.trim()),
              ),
          ]),
        ],
        if (anyStages) ...[
          const SizedBox(height: 56),
          Text('Mekânlar', style: Sk.display(context, size: 26, height: 1.1)),
          const SizedBox(height: 18),
          Wrap(spacing: 20, runSpacing: 14, children: [
            for (final Stage s in stages.take(12))
              _RowLink(
                  icon: Icons.location_city_rounded,
                  title: s.name,
                  sub: s.address,
                  onTap: () => NavigationHandler.goToStage(context, s.id, s.name,
                      imageUrl: s.imageUrl, title: s.name)),
          ]),
        ],
        if (anyTeams) ...[
          const SizedBox(height: 56),
          Text('Topluluklar', style: Sk.display(context, size: 26, height: 1.1)),
          const SizedBox(height: 18),
          Wrap(spacing: 20, runSpacing: 14, children: [
            for (final Team t in teams.take(12))
              _RowLink(
                  icon: Icons.groups_rounded,
                  title: t.name,
                  sub: '',
                  onTap: () => NavigationHandler.goToTeam(context, t.id, t.name,
                      imageUrl: t.imageUrl, title: t.name)),
          ]),
        ],
      ],
    );
  }
}

class _Card extends StatefulWidget {
  final Show show;
  final NextSessionHint? next;
  const _Card({required this.show, required this.next});

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = widget.show;
    final NextSessionHint? n = widget.next;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name,
            imageUrl: show.imageUrl, title: show.name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: _hover ? 0.4 : 0.2),
                      blurRadius: _hover ? 24 : 12,
                      offset: Offset(0, _hover ? 12 : 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Stack(fit: StackFit.expand, children: [
                    SkImage(url: show.imageUrl, alignment: Alignment.topCenter),
                    Positioned(
                        right: 10, top: 10, child: RatingChip(showId: show.id)),
                    if (show.hasExternalTicketing)
                      const Positioned(
                        left: 10,
                        top: 10,
                        child: SkBadge(
                            label: 'Başka platform',
                            onImage: true,
                            icon: Icons.open_in_new_rounded),
                      ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (show.category.trim().isNotEmpty)
              Text(show.category.trim(),
                  style: Sk.ui(context,
                      size: 12, color: cs.primary, weight: FontWeight.w800)),
            Text(show.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context,
                    size: 15.5,
                    weight: FontWeight.w800,
                    height: 1.25,
                    color: _hover ? cs.primary : cs.onSurface)),
            const SizedBox(height: 4),
            Text(
                n == null
                    ? 'Tarih yakında'
                    : '${skDayPhrase(n.when)} · ${skClock(n.when)}',
                style: Sk.ui(context,
                    size: 12.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
            if (n?.price != null)
              Text("${skPrice(n!.price!)}'den",
                  style: Sk.ui(context,
                      size: 15, color: cs.primary, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  const _PersonChip(
      {required this.name, required this.imageUrl, required this.onTap});

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 110,
            child: Column(children: [
              ClipOval(
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: SkImage(
                      url: imageUrl,
                      alignment: const Alignment(0, -0.35),
                      fallbackIcon: Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Text(name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context,
                      size: 13.5, weight: FontWeight.w800, height: 1.2)),
            ]),
          ),
        ),
      );
}

class _RowLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _RowLink(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(icon, color: cs.onPrimaryContainer)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
                    if (sub.trim().isNotEmpty)
                      Text(sub.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
