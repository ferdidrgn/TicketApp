import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/shared/widgets/section_header.dart';
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
  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final eventsAsync = ref.watch(upcomingEventsProvider);

    final filteredEvents = eventsAsync.value == null
        ? const <DiscoverEvent>[]
        : widget.selectedCategory == null
            ? eventsAsync.value!
            : eventsAsync.value!
                .where((final e) => e.show.category == widget.selectedCategory)
                .toList();

    return BasePageWrapper(
      title: widget.selectedCategory ?? 'İlhamını Bul',
      subtitle: widget.selectedCategory != null
          ? '${widget.selectedCategory} kategorisindeki etkinlikler'
          : 'Küratörlerin hazırladığı özel seçkiler',
      showBackButton: false,
      showFab: true,
      isLoading: eventsAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
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
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SectionHeader(
                          title: 'Haftanın Başyapıtları', subtitle: 'Seçkiler'),
                      const SizedBox(height: 16),
                      _buildTrendingSlider(context, filteredEvents.take(6).toList()),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(title: 'Tümünü Keşfet'),
                          _buildFilterButton(context),
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
          return GestureDetector(
            onTap: () =>
                NavigationHandler.goToShow(context, item.show.id, item.show.name),
            child: Container(
              width: 320,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: context.colors.shadow.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
                image: DecorationImage(
                  image: NetworkImage(item.show.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3), BlendMode.darken),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildTag(context, index == 0 ? 'YENİ' : 'YAKINDA'),
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
          );
        },
      ),
    );
  }

  Widget _buildResponsiveEventList(
      final bool isLargeScreen, final List<DiscoverEvent> events) {
    final cards = events
        .map((final item) => EventsCard(
              imageUrl: item.show.imageUrl,
              showName: item.show.name,
              category: item.show.category,
              stage: item.stage?.name ?? '',
              price: item.price,
              fullDateString: _dateOf(item),
              timeString: _timeOf(item),
              onTap: () => NavigationHandler.goToShow(
                  context, item.show.id, item.show.name),
            ))
        .toList();

    if (isLargeScreen) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2.5,
        children: cards,
      );
    }
    return Column(
      children: cards
          .expand((final c) => [c, const SizedBox(height: 16)])
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

  Widget _buildTag(final BuildContext context, final String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(tag,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      );

  Widget _buildShowInfo(final BuildContext context, final Show show) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show.category.toUpperCase(),
              style: TextStyle(
                  color: context.colors.primary,
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

  Widget _buildFilterButton(final BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon:
              Icon(Icons.tune_rounded, size: 18, color: context.colors.primary),
          label: Text('Filtrele',
              style: TextStyle(
                  color: context.colors.primary, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildEmptyState(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_rounded,
                  size: 56, color: context.colors.outline),
              const SizedBox(height: 16),
              Text(
                widget.selectedCategory == null
                    ? 'Şu anda yaklaşan bir etkinlik yok.'
                    : '"${widget.selectedCategory}" kategorisinde yaklaşan etkinlik yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorState(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: context.colors.error),
              const SizedBox(height: 16),
              const Text('Etkinlikler yüklenemedi.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(upcomingEventsProvider),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
}
