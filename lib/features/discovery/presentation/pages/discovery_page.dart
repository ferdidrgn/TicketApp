import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/widgets/bento/bento_primitives.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../providers/discovery_provider.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant final DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _activeCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final eventsAsync = ref.watch(upcomingEventsProvider);

    final filteredEvents = eventsAsync.value == null
        ? const <DiscoverEvent>[]
        : _activeCategory == null
            ? eventsAsync.value!
            : eventsAsync.value!
                .where((final e) => e.show.category == _activeCategory)
                .toList();

    return BasePageWrapper(
      title: _activeCategory ?? 'İlhamını Bul',
      subtitle: _activeCategory != null
          ? '$_activeCategory kategorisindeki etkinlikler'
          : 'Küratörlerin hazırladığı özel seçkiler',
      showBackButton: false,
      showFab: true,
      isLoading: eventsAsync.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        safeAreaTop: true,
      ),
      onRefresh: () => ref.invalidate(upcomingEventsProvider),
      child: eventsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (final err, final _) => _buildErrorState(context),
        data: (final _) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1200 : double.infinity),
            child: filteredEvents.isEmpty
                ? _buildEmptyState(context)
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const BentoSectionHeader(
                        title: 'Haftanın Başyapıtları',
                        subtitle: 'Küratör seçkileri',
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTrendingSlider(context, filteredEvents.take(6).toList()),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: BentoSectionHeader(
                              title: 'Tümünü Keşfet',
                              icon: Icons.grid_view_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildFilterButton(context, eventsAsync.value ?? const []),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildResponsiveEventList(isLargeScreen, filteredEvents),
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSlider(
      final BuildContext context, final List<DiscoverEvent> events) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (final context, final index) {
          final item = events[index];
          return FadeInUp(
            delay: Duration(milliseconds: 60 * index),
            child: GestureDetector(
              onTap: () => NavigationHandler.goToShow(
                  context, item.show.id, item.show.name),
              child: Container(
                width: 320,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: BentoColors.microBorder),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        offset: Offset(0, 10)),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(item.show.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.35), BlendMode.darken),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: BentoBadge(
                        label: index == 0 ? 'YENİ' : 'YAKINDA',
                        color: index == 0 ? BentoColors.emerald : BentoColors.indigo,
                        backgroundColor: Colors.black.withOpacity(0.45),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: _buildShowInfo(context, item.show),
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

  Widget _buildResponsiveEventList(
      final bool isLargeScreen, final List<DiscoverEvent> events) {
    final cards = <Widget>[
      for (var i = 0; i < events.length; i++)
        FadeInUp(
          delay: Duration(milliseconds: 40 * i),
          child: EventsCard(
            imageUrl: events[i].show.imageUrl,
            showName: events[i].show.name,
            category: events[i].show.category,
            stage: events[i].stage?.name ?? '',
            price: events[i].price,
            fullDateString: _dateOf(events[i]),
            timeString: _timeOf(events[i]),
            onTap: () => NavigationHandler.goToShow(
                context, events[i].show.id, events[i].show.name),
          ),
        ),
    ];

    if (isLargeScreen) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.5,
        children: cards,
      );
    }
    return Column(
      children: cards
          .expand((final c) => [c, const SizedBox(height: 14)])
          .toList(),
    );
  }

  String _dateOf(final DiscoverEvent item) => DateFormatter.parseFormattedDateTime(
      item.event.date,
      formatWithMonthName: true)['date'] ?? '';

  String _timeOf(final DiscoverEvent item) => DateFormatter.parseFormattedDateTime(
      item.event.date,
      formatWithMonthName: true)['time'] ?? '';

  // --- KÜÇÜK UI BİLEŞENLERİ ---

  Widget _buildShowInfo(final BuildContext context, final Show show) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show.category.toUpperCase(),
              style: const TextStyle(
                  color: BentoColors.indigoLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(show.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.1)),
        ],
      );

  Widget _buildFilterButton(
          final BuildContext context, final List<DiscoverEvent> events) =>
      Material(
        color: _activeCategory != null
            ? BentoColors.indigo.withOpacity(0.16)
            : BentoColors.highlight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openCategoryFilterSheet(context, events),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    _activeCategory != null
                        ? Icons.filter_alt_rounded
                        : Icons.tune_rounded,
                    size: 16,
                    color: BentoColors.indigoLight),
                const SizedBox(width: 6),
                Text(_activeCategory ?? 'Filtrele',
                    style: const TextStyle(
                        color: BentoColors.indigoLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );

  void _openCategoryFilterSheet(
      final BuildContext context, final List<DiscoverEvent> events) {
    final categories = events
        .map((final e) => e.show.category)
        .where((final c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: BentoColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (final sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kategoriye Göre Filtrele',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Şu an filtrelenecek kategori yok.',
                      style: TextStyle(color: Color(0xFFA1A1AA))),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CategoryChip(
                      label: 'Tümü',
                      selected: _activeCategory == null,
                      onTap: () {
                        setState(() => _activeCategory = null);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    for (final category in categories)
                      _CategoryChip(
                        label: category,
                        selected: _activeCategory == category,
                        onTap: () {
                          setState(() => _activeCategory = category);
                          Navigator.pop(sheetContext);
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BentoEmptyState(
            icon: Icons.explore_off_rounded,
            title: 'Yaklaşan etkinlik yok',
            message: _activeCategory == null
                ? 'Şu anda yaklaşan bir etkinlik yok.'
                : '"$_activeCategory" kategorisinde yaklaşan etkinlik yok.',
          ),
        ),
      );

  Widget _buildErrorState(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BentoErrorState(
            message: 'Etkinlikler yüklenemedi.',
            onRetry: () => ref.invalidate(upcomingEventsProvider),
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(final BuildContext context) => Material(
        color: selected ? BentoColors.indigo : BentoColors.highlight,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFD4D4D8),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      );
}
