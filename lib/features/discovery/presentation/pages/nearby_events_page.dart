import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/discovery_provider.dart';

const _kFilters = ['Tümü', 'Tiyatro', 'Konser', 'Sahne', 'Bugün', 'Yakında'];

class NearbyEventsPage extends ConsumerStatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  ConsumerState<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends ConsumerState<NearbyEventsPage> {
  String _selectedFilter = 'Tümü';

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final double cardWidth = isLargeScreen ? 400 : context.screenWidth - 48;

    final eventsAsync = ref.watch(upcomingEventsProvider);
    final stagesAsync = ref.watch(popularStagesProvider);

    final events = _applyFilter(eventsAsync.value ?? const []);

    return BasePageWrapper(
      title: 'YAKININIZDAKİ ETKİNLİKLER',
      subtitle: 'Bu hafta sahnelerde neler var?',
      showBackButton: false,
      rightIcon: Icons.tune_rounded,
      showFab: true,
      isLoading: eventsAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface, safeAreaTop: true),
      onRefresh: () {
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(popularStagesProvider);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildDiscoveryBanner(context, events.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kFilters
                    .map((final f) =>
                        _buildFilterChip(f, f == _selectedFilter, context))
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SectionHeader(
                title: 'Sizin İçin Önerilenler',
                subtitle: 'Yaklaşan etkinlikler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (eventsAsync.isLoading)
            const SliverToBoxAdapter(
              child: SizedBox(
                  height: 320, child: Center(child: CircularProgressIndicator())),
            )
          else if (events.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyEvents(context))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (final context, final index) {
                    final item = events[index];
                    return Container(
                      width: cardWidth * 0.85,
                      margin: EdgeInsets.only(
                        right: index < events.length - 1 ? 16 : 0,
                      ),
                      child: EventsCard(
                        width: cardWidth * 0.85,
                        imageUrl: item.show.imageUrl,
                        showName: item.show.name,
                        category: item.show.category,
                        fullDateString: DateFormatter.parseFormattedDateTime(
                                item.event.date,
                                formatWithMonthName: true)['date'] ??
                            '',
                        timeString: DateFormatter.parseFormattedDateTime(
                                item.event.date,
                                formatWithMonthName: true)['time'] ??
                            '',
                        stage: item.stage?.name ?? '',
                        price: item.price,
                        onTap: () => NavigationHandler.goToShow(
                            context, item.show.id, item.show.name),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SectionHeader(
                title: 'Popüler Sahne ve Mekanlar',
                subtitle: 'En çok etkinlik barındıran sahneler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          stagesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                  height: 120, child: Center(child: CircularProgressIndicator())),
            ),
            error: (final e, final _) => const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
            data: (final stages) => stages.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLargeScreen ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (final context, final index) =>
                            _buildVenueCard(context, stages[index]),
                        childCount: stages.length,
                      ),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  List<DiscoverEvent> _applyFilter(final List<DiscoverEvent> events) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Tiyatro':
        return events
            .where((final e) => e.show.category.toLowerCase().contains('tiyatro'))
            .toList();
      case 'Konser':
        return events
            .where((final e) => e.show.category.toLowerCase().contains('konser'))
            .toList();
      case 'Sahne':
        return events.where((final e) => e.stage != null).toList();
      case 'Bugün':
        return events.where((final e) {
          final d = DateFormatter.parseDateString(e.event.date);
          return d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).toList();
      case 'Yakında':
        return events.where((final e) {
          final d = DateFormatter.parseDateString(e.event.date);
          return d != null && d.difference(now).inDays <= 14;
        }).toList();
      case 'Tümü':
      default:
        return events;
    }
  }

  Widget _buildEmptyEvents(final BuildContext context) => SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: context.colors.outline),
              const SizedBox(height: 12),
              Text('Bu filtreye uygun etkinlik bulunamadı.',
                  style: TextStyle(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      );

  Widget _buildDiscoveryBanner(final BuildContext context, final int eventCount) =>
      Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              context.primaryColor,
              context.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                Icons.star_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Icon(
                Icons.location_on_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Şehrin Ritmini Keşfet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          eventCount > 0
                              ? '$eventCount yaklaşan etkinlik sizi bekliyor.'
                              : 'Yakında yeni etkinlikler eklenecek.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
      final String text, final bool isActive, final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : context.colors.onSurfaceVariant,
          ),
        ),
        selected: isActive,
        onSelected: (final selected) {
          if (selected) setState(() => _selectedFilter = text);
        },
        backgroundColor: context.colors.surfaceContainerHighest,
        selectedColor: context.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildVenueCard(final BuildContext context, final Stage stage) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: context.colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.theater_comedy_rounded,
                color: context.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                stage.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sahne',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
