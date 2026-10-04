import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../home/presentation/widgets/common/home_showcase.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../widgets/browse_controls.dart';

/// KEŞFET — oyunlara türe göre göz atma.
///
/// - Kategoriler: gerçek `Show.category`'den, büyük/küçük harf ve boşluk
///   farkı TEK kategori sayılır ("komedi" = "Komedi"). Her kategori kendi
///   gerçek afişiyle fotoğraflı bir kart; dokununca süzer, tekrar dokununca
///   "Tümü"ne döner. `/discover?category=…` bağlantısı (ana sayfadaki ruh
///   hâli kartları) da aynı normalleştirmeyle eşleşir.
/// - Sahnede / Geçmiş geçişi, sıralama (yakın tarih / yeni eklenen / A–Z).
/// - "Haritada gör" kartı → Yakınımdakiler (50 km halkalı harita).
/// - Sonuçlar bilet değil, sinematik afiş kartı (`HomePosterCard`).
/// - Sahnede modunda, takviminde seansı olmayan oyunlar gizlenmez: ayrı
///   bölümde, ilk 6'sı + "Tümünü göster".
class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

/// Kategori anahtarı: Türkçe büyük harfleri doğru küçültür, boşlukları
/// sadeleştirir. Görünen ad, en sık kullanılan orijinal yazımdır.
String discoveryCategoryKey(final String raw) => raw
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase();

class _Category {
  final String key;
  final String label;
  final int count;
  final String imageUrl;
  const _Category(this.key, this.label, this.count, this.imageUrl);
}

List<_Category> _categoriesOf(final List<Show> shows) {
  final Map<String, Map<String, int>> spellings = {};
  final Map<String, List<Show>> byKey = {};
  for (final s in shows) {
    final String raw = s.category.trim();
    if (raw.isEmpty) continue;
    final String k = discoveryCategoryKey(raw);
    byKey.putIfAbsent(k, () => []).add(s);
    final sp = spellings.putIfAbsent(k, () => {});
    sp[raw] = (sp[raw] ?? 0) + 1;
  }
  final list = byKey.entries.map((final e) {
    final sp = spellings[e.key]!;
    final String label =
        (sp.entries.toList()..sort((final a, final b) => b.value.compareTo(a.value)))
            .first
            .key;
    final String img = e.value
        .map((final s) => s.imageUrl.trim())
        .firstWhere((final u) => u.isNotEmpty, orElse: () => '');
    return _Category(e.key, label, e.value.length, img);
  }).toList()
    ..sort((final a, final b) {
      final c = b.count.compareTo(a.count);
      return c != 0 ? c : a.label.compareTo(b.label);
    });
  return list;
}

enum _Sort { soonest, newest, alpha }

const Map<_Sort, String> _sortLabels = {
  _Sort.soonest: 'Yakın tarih',
  _Sort.newest: 'Yeni eklenen',
  _Sort.alpha: 'A–Z',
};

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  String? _categoryKey;
  bool _showPast = false;
  _Sort _sort = _Sort.soonest;
  bool _showAllInactive = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _categoryKey = _keyOf(widget.selectedCategory);
  }

  @override
  void didUpdateWidget(covariant final DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _categoryKey = _keyOf(widget.selectedCategory);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String? _keyOf(final String? raw) =>
      (raw == null || raw.trim().isEmpty) ? null : discoveryCategoryKey(raw);

  void _pickCategory(final String? key) {
    HapticFeedback.selectionClick();
    setState(() {
      _categoryKey = (key == _categoryKey) ? null : key;
      _showAllInactive = false;
    });
    // Adres satırı seçimle uyumlu kalsın (paylaşılabilir/geri tuşu).
    if (widget.selectedCategory != null && key == null) {
      context.go('/discover');
    }
  }

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  void _retry() {
    ref.invalidate(showsProvider);
    ref.invalidate(eventsByShowIdsProvider);
    ref.invalidate(showsActiveFirstProvider);
    ref.invalidate(pastShowsProvider);
    ref.invalidate(activeShowsProvider);
  }

  List<Show> _sorted(final List<Show> shows) {
    switch (_sort) {
      case _Sort.soonest:
        return shows; // sağlayıcı zaten en yakın seansa göre sıralı
      case _Sort.newest:
        final l = List<Show>.of(shows);
        sortShowsByCreatedAtDescending(l);
        return l;
      case _Sort.alpha:
        return List<Show>.of(shows)
          ..sort((final a, final b) => discoveryCategoryKey(a.name)
              .compareTo(discoveryCategoryKey(b.name)));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<List<Show>> showsState = _showPast
        ? ref.watch(pastShowsProvider(false))
        : ref.watch(showsActiveFirstProvider(false));
    final AsyncValue<List<Show>> activeState =
        ref.watch(activeShowsProvider(false));

    final bool loading = (showsState.isLoading && !showsState.hasValue) ||
        (!_showPast && activeState.isLoading && !activeState.hasValue);
    final bool failed = !loading &&
        ((showsState.hasError && !showsState.hasValue) ||
            (!_showPast && activeState.hasError && !activeState.hasValue));

    final List<Show> all = showsState.value ?? const <Show>[];
    final Set<String> activeIds =
        (activeState.value ?? const <Show>[]).map((final s) => s.id).toSet();
    final List<_Category> categories = _categoriesOf(all);
    // İstenen kategori bu modun verisinde yoksa "Tümü".
    final String? key =
        categories.any((final c) => c.key == _categoryKey) ? _categoryKey : null;
    final List<Show> filtered = key == null
        ? all
        : all
            .where((final s) => discoveryCategoryKey(s.category) == key)
            .toList();
    final List<Show> primary = _sorted(_showPast
        ? filtered
        : filtered.where((final s) => activeIds.contains(s.id)).toList());
    final List<Show> secondary = _showPast
        ? const []
        : _sorted(
            filtered.where((final s) => !activeIds.contains(s.id)).toList());

    final view = _View(
      loading: loading,
      failed: failed,
      categories: categories,
      categoryKey: key,
      primary: primary,
      secondary: secondary,
    );

    return context.isDesktop
        ? _desktop(context, view)
        : _compact(context, view, tablet: context.isTablet);
  }

  String? _lede(final _View v) {
    if (v.loading || v.failed) return null;
    final String? label = v.categoryLabel;
    final int n = v.primary.length;
    if (_showPast) {
      return label == null
          ? 'Perdesi kapanmış $n oyun.'
          : '“$label” türünde perdesi kapanmış $n oyun.';
    }
    if (n == 0) {
      return label == null
          ? 'Şu an sahnede oyun yok.'
          : '“$label” türünde şu an sahnede oyun yok.';
    }
    return label == null
        ? 'Şu an sahnede $n oyun var. Türe göre süz, birine dokun.'
        : '“$label” türünde şu an sahnede $n oyun var.';
  }

  // ─────────────────────────────────────────────────────────────────────
  // Ortak sliver'lar
  // ─────────────────────────────────────────────────────────────────────

  Widget _box(final double gutter, final Widget child, {final double bottom = 0}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
        sliver: SliverToBoxAdapter(child: child),
      );

  List<Widget> _results(final _View v, final double gutter, final int columns) {
    if (v.loading) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: columns * 2,
            itemBuilder: (final _, final __) => const TicketCardSkeleton(),
          ),
        ),
      ];
    }
    if (v.failed) {
      return [
        _box(
          gutter,
          Align(
            alignment: Alignment.centerLeft,
            child: TicketNotice(
              label: 'KEŞFET',
              title: 'Oyunlar yüklenemedi',
              message: 'İnternet bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              actionIcon: Icons.refresh_rounded,
              onAction: _retry,
            ),
          ),
        ),
      ];
    }
    final cs = Theme.of(context).colorScheme;
    final List<Show> inactive = _showAllInactive
        ? v.secondary
        : v.secondary.take(columns * 2).toList();
    return [
      if (v.primary.isEmpty)
        _box(
          gutter,
          Align(
            alignment: Alignment.centerLeft,
            child: TicketNotice(
              label: 'KEŞFET',
              title: v.categoryLabel == null
                  ? 'Şu an sahnede oyun yok'
                  : '“${v.categoryLabel}” türünde oyun yok',
              message: v.categoryLabel == null
                  ? 'Geçmiş oyunlara göz atabilirsin.'
                  : 'Başka bir tür seç ya da tümüne bak.',
              actionLabel:
                  v.categoryLabel == null ? 'Geçmiş oyunlar' : 'Tüm türler',
              onAction: v.categoryLabel == null
                  ? () => setState(() => _showPast = true)
                  : () => _pickCategory(null),
            ),
          ),
          bottom: AppSpacing.xxl,
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: v.primary.length,
            itemBuilder: (final context, final i) => HomePosterCard(
              key: ValueKey('disc-${v.primary[i].id}'),
              show: v.primary[i],
              onTap: () => _openShow(v.primary[i]),
            ),
          ),
        ),
      if (inactive.isNotEmpty) ...[
        _box(
          gutter,
          BrowseSectionTitle(
            title: 'Şu an sahnede değil',
            count: v.secondary.length,
          ),
        ),
        _box(
          gutter,
          Text(
            'Takviminde yaklaşan seansı olmayan oyunlar.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          bottom: AppSpacing.md,
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: inactive.length,
            itemBuilder: (final context, final i) => Opacity(
              opacity: 0.85,
              child: HomePosterCard(
                show: inactive[i],
                onTap: () => _openShow(inactive[i]),
              ),
            ),
          ),
        ),
        if (!_showAllInactive && v.secondary.length > inactive.length)
          _box(
            gutter,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showAllInactive = true),
                child: Text('Tümünü göster (${v.secondary.length})'),
              ),
            ),
          ),
      ],
    ];
  }

  SliverGridDelegate _grid(final int columns) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.56,
      );

  Widget _sortChips(final double gutter) => BrowseChoiceChips(
        options: [for (final s in _Sort.values) BrowseOption(_sortLabels[s]!)],
        selectedIndex: _sort.index,
        onSelected: (final i) {
          HapticFeedback.selectionClick();
          setState(() => _sort = _Sort.values[i]);
        },
        padding: EdgeInsets.symmetric(horizontal: gutter),
      );

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet
  // ─────────────────────────────────────────────────────────────────────

  Widget _compact(final BuildContext context, final _View v,
      {required final bool tablet}) {
    final cs = Theme.of(context).colorScheme;
    final double gutter = tablet ? AppSpacing.xxl : AppSpacing.lg;
    return BasePageWrapper(
      showBackButton: false,
      customScrollController: _scroll,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: RefreshIndicator(
        onRefresh: () async => _retry(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  gutter, AppSpacing.xl, gutter, AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: BrowseHeading(
                    title: _showPast ? 'Geçmiş oyunlar' : 'Keşfet',
                    lede: _lede(v)),
              ),
            ),
            _box(
              gutter,
              ShowsModeToggle(
                showPast: _showPast,
                onChanged: (final past) => setState(() {
                  _showPast = past;
                  _showAllInactive = false;
                }),
              ),
              bottom: AppSpacing.xl,
            ),
            if (v.categories.isNotEmpty) ...[
              _box(gutter, const BrowseSectionTitle(title: 'Türler')),
              SliverToBoxAdapter(
                child: _CategoryStrip(
                  categories: v.categories,
                  selectedKey: v.categoryKey,
                  total: v.categories.fold(0, (final n, final c) => n + c.count),
                  onPick: _pickCategory,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
            if (!_showPast)
              _box(gutter, const _NearbyTeaser(), bottom: AppSpacing.xl),
            SliverToBoxAdapter(child: _sortChips(gutter)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ..._results(v, gutter, tablet ? 3 : 2),
            if (kIsWeb) ...[
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section)),
              const SliverToBoxAdapter(child: Footer()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü: solda türler, sağda sonuçlar
  // ─────────────────────────────────────────────────────────────────────

  Widget _desktop(final BuildContext context, final _View v) {
    final cs = Theme.of(context).colorScheme;
    const double gutter = AppSpacing.huge;
    final Widget sidebar = SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.massive, AppSpacing.md, AppSpacing.xxl),
        children: [
          ShowsModeToggle(
            showPast: _showPast,
            onChanged: (final past) => setState(() {
              _showPast = past;
              _showAllInactive = false;
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const BrowseSideLabel('Türler'),
          BrowseSideOption(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            selected: v.categoryKey == null,
            onTap: () => _pickCategory(null),
          ),
          for (final c in v.categories)
            BrowseSideOption(
              label: c.label,
              count: c.count,
              selected: v.categoryKey == c.key,
              onTap: () => _pickCategory(c.key),
            ),
          if (!_showPast) ...[
            const SizedBox(height: AppSpacing.xxl),
            const _NearbyTeaser(),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          VerticalDivider(width: 1, color: cs.outlineVariant),
          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                _box(
                  gutter,
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.massive),
                    child: BrowseHeading(
                        title: _showPast ? 'Geçmiş oyunlar' : 'Keşfet',
                        lede: _lede(v)),
                  ),
                  bottom: AppSpacing.xl,
                ),
                SliverToBoxAdapter(child: _sortChips(gutter)),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl)),
                ..._results(v, gutter, 5),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.section)),
                const SliverToBoxAdapter(child: Footer()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _View {
  final bool loading;
  final bool failed;
  final List<_Category> categories;
  final String? categoryKey;
  final List<Show> primary;
  final List<Show> secondary;

  const _View({
    required this.loading,
    required this.failed,
    required this.categories,
    required this.categoryKey,
    required this.primary,
    required this.secondary,
  });

  String? get categoryLabel {
    if (categoryKey == null) return null;
    for (final c in categories) {
      if (c.key == categoryKey) return c.label;
    }
    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Tür şeridi: "Tümü" + afişli kategori kartları
// ═════════════════════════════════════════════════════════════════════════

class _CategoryStrip extends StatelessWidget {
  final List<_Category> categories;
  final String? selectedKey;
  final int total;
  final ValueChanged<String?> onPick;
  final EdgeInsets padding;

  const _CategoryStrip({
    required this.categories,
    required this.selectedKey,
    required this.total,
    required this.onPick,
    required this.padding,
  });

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          children: [
            _CategoryCard(
              label: 'Tümü',
              count: total,
              imageUrl: '',
              selected: selectedKey == null,
              onTap: () => onPick(null),
            ),
            for (final c in categories)
              _CategoryCard(
                label: c.label,
                count: c.count,
                imageUrl: c.imageUrl,
                selected: selectedKey == c.key,
                onTap: () => onPick(c.key),
              ),
          ],
        ),
      );
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final int count;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.count,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasImage = imageUrl.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count oyun',
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 2.4,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md - 2),
            child: Material(
              color: hasImage ? Colors.black : cs.primaryContainer,
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Opacity(
                        opacity: selected ? 0.9 : 0.6,
                        child: OptimizedCachedImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: 0,
                        ),
                      ),
                    if (hasImage)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x11000000), Color(0xCC000000)],
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        top: AppSpacing.xs + 2,
                        right: AppSpacing.xs + 2,
                        child: Icon(Icons.check_circle_rounded,
                            size: 20, color: cs.primary),
                      ),
                    Positioned(
                      left: AppSpacing.sm + 2,
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: hasImage
                                  ? Colors.white
                                  : cs.onPrimaryContainer,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$count oyun',
                            style: TextStyle(
                              color: hasImage
                                  ? const Color(0xCCFFFFFF)
                                  : cs.onPrimaryContainer.withValues(alpha: 0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// "Haritada gör" — Yakınımdakiler'e kısa yol (konum burada istenmez)
// ═════════════════════════════════════════════════════════════════════════

class _NearbyTeaser extends StatelessWidget {
  const _NearbyTeaser();

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Haritada gör: yakınındaki sahneler',
      excludeSemantics: true,
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.go('/nearby'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_outlined,
                      color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haritada gör',
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
                      Text('50 km içindeki ve daha uzaktaki sahneler',
                          style: TextStyle(
                            color:
                                cs.onSecondaryContainer.withValues(alpha: 0.8),
                            fontSize: 12.5,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
