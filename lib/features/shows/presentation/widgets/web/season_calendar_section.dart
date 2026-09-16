import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/util/date_formatter.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../events/presentation/providers/season_calendar_provider.dart';

/// Ana sayfadaki "Sezon Takvimi": tüm oyunların tüm etkinliklerini ay ay
/// gösterir. Gösterilen oyun adı ve tarihler `seasonCalendarEntriesProvider`
/// üzerinden gerçek Firestore verisinden gelir — sabit/placeholder içerik
/// kullanılmaz.
class SeasonCalendarSection extends ConsumerStatefulWidget {
  const SeasonCalendarSection({super.key});

  @override
  ConsumerState<SeasonCalendarSection> createState() =>
      _SeasonCalendarSectionState();
}

class _SeasonCalendarSectionState extends ConsumerState<SeasonCalendarSection> {
  int _selectedMonth = DateTime.now().month;
  final int _year = DateTime.now().year;

  @override
  Widget build(final BuildContext context) {
    final entriesAsync = ref.watch(seasonCalendarEntriesProvider);

    return Container(
      width: double.infinity,
      color: WebColors.darkBlueBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: context.paddingAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                SizedBox(height: context.gridSpacing),
                _buildMonthTabs(context),
                SizedBox(height: context.gridSpacing * 1.5),
                entriesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: WebColors.primaryGold)),
                  ),
                  error: (final err, final _) => _buildMessage(
                      'Takvim yüklenemedi.', WebColors.error),
                  data: (final entries) => _buildMonthGrid(context, entries),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEZON TAKVİMİ',
                    style: TextStyle(
                      color: WebColors.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    )),
                SizedBox(height: context.gridSpacing / 2),
                Text(
                  '${DateFormatter.getMonthName(_selectedMonth).toUpperCase()} $_year',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: Colors.white,
                    fontSize: context.responsive(mobile: 30.0, desktop: 44.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildMonthTabs(final BuildContext context) => SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 12,
          itemBuilder: (final context, final index) {
            final month = index + 1;
            final bool isActive = month == _selectedMonth;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedMonth = month),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        isActive ? WebColors.primaryGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? WebColors.primaryGold
                          : WebColors.primaryGold.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    DateFormatter.getMonthName(month).toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? WebColors.darkBlueBackground
                          : WebColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildMonthGrid(
      final BuildContext context, final List<SeasonCalendarEntry> entries) {
    final monthEntries = entries
        .where((final e) =>
            e.dateTime!.year == _year && e.dateTime!.month == _selectedMonth)
        .toList();

    if (monthEntries.isEmpty)
      return _buildMessage(
          'Bu ayda planlanmış bir etkinlik yok.', WebColors.textSecondary);

    return Wrap(
      spacing: context.gridSpacing,
      runSpacing: context.gridSpacing,
      children: monthEntries
          .map((final entry) => _buildEventCard(context, entry))
          .toList(),
    );
  }

  Widget _buildMessage(final String text, final Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text(text, style: TextStyle(color: color, fontSize: 14))),
      );

  Widget _buildEventCard(
      final BuildContext context, final SeasonCalendarEntry entry) {
    final show = entry.show;
    final dateTime = entry.dateTime!;
    final day = dateTime.day.toString();
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return SizedBox(
      width: context.responsive(mobile: 260.0, desktop: 300.0),
      child: InkWell(
        onTap: show == null
            ? null
            : () => NavigationHandler.goToShow(context, show.id, show.name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(day,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          color: WebColors.darkBlueBackground,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        )),
                    Text(time,
                        style: TextStyle(
                          color: WebColors.darkBlueBackground,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  show?.name ?? 'Etkinlik',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
