import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../pages/admin_event_form_page.dart';
import 'admin_table_tools.dart';

/// "Seanslar" sekmesi — TÜM oyunların TÜM seanslarını (Event) BİR ARADA
/// listeler; web yönetim panelindeki bağımsız "Seanslar" görünümünün
/// (`site/js/admin/schema.js` → `Event`) mobil karşılığı.
///
/// Bu, `AdminEventSection`'ın (bir oyunun düzenleme ekranına GÖMÜLÜ seans
/// bölümü) YERİNE geçmez — o bölüm aynen kalır, bu sadece "tüm seansları
/// tek yerden gör/yönet" için YENİ, ek bir giriş noktasıdır. Veri kaynağı
/// AYNI `eventsByShowMapProvider`/`eventMutationProvider` (bkz.
/// `show_provider.dart`/`event_mutation_provider.dart`) — ikinci bir
/// sorgu/yazma yolu İCAT EDİLMEDİ.
class AdminEventsTab extends ConsumerStatefulWidget {
  const AdminEventsTab({super.key});

  @override
  ConsumerState<AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends ConsumerState<AdminEventsTab> {
  final _search = TextEditingController();
  String _timeFilter = 'all'; // all | upcoming | past
  String _sortId = 'date';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  List<AdminTableColumn<_EventRow>> get _columns => [
        AdminTableColumn<_EventRow>(
          id: 'show',
          label: 'Oyun',
          text: (final r) => r.showName,
          compare: (final a, final b) =>
              adminCompareText(a.showName, b.showName),
          cell: (final context, final r) => Text(r.showName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        AdminTableColumn<_EventRow>(
          id: 'stage',
          label: 'Sahne',
          text: (final r) => r.stageName,
          compare: (final a, final b) =>
              adminCompareText(a.stageName, b.stageName),
        ),
        AdminTableColumn<_EventRow>(
          id: 'date',
          label: 'Tarih',
          text: (final r) => r.event.date,
          compare: (final a, final b) =>
              adminCompareDate(a.event.date, b.event.date),
          cell: (final context, final r) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(adminFormatStamp(r.event.date),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TimeTag(isPast: r.isPast),
            ],
          ),
        ),
        AdminTableColumn<_EventRow>(
          id: 'price',
          label: 'Fiyat',
          numeric: true,
          text: (final r) => r.event.price,
          compare: (final a, final b) =>
              (double.tryParse(a.event.price) ?? -1)
                  .compareTo(double.tryParse(b.event.price) ?? -1),
          cell: (final context, final r) => Text(
            r.event.price.trim() == '0'
                ? 'Ücretsiz'
                : r.event.price.trim().isEmpty
                    ? '—'
                    : '${r.event.price} ₺',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ];

  List<_EventRow> _buildRows(
      final Map<String, List<Event>> eventsByShow,
      final List<Show> shows,
      final List<Stage> stages) {
    final showNameById = {for (final s in shows) s.id: s.name};
    final stageNameById = {for (final s in stages) s.id: s.name};
    final now = DateTime.now();
    final rows = <_EventRow>[];
    for (final events in eventsByShow.values) {
      for (final event in events) {
        final date = DateFormatter.parseDateString(event.date);
        rows.add(_EventRow(
          event: event,
          showName: showNameById[event.showId] ?? 'Bilinmeyen oyun',
          stageName: stageNameById[event.stageId] ?? 'Bilinmeyen sahne',
          isPast: date != null && date.isBefore(now),
        ));
      }
    }
    // Aynı etkinlik iki oyuna aynı anda bağlı görünebilirse (showId yedek
    // eşleşmesi) tekilleştir — gösterge tek satırda.
    final seen = <String>{};
    return rows.where((final r) => seen.add(r.event.id)).toList();
  }

  List<_EventRow> _visible(final List<_EventRow> rows) {
    final filtered = rows.where((final r) {
      if (_timeFilter == 'upcoming' && r.isPast) return false;
      if (_timeFilter == 'past' && !r.isPast) return false;
      return adminQueryHits(_search.text, [
        r.showName,
        r.stageName,
        r.event.date,
        r.event.price,
      ]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Event? event) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (final _) => AdminEventFormPage(event: event)));
  }

  @override
  Widget build(final BuildContext context) {
    final showsAsync = ref.watch(showsProvider(isLimit: false));
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
    final eventsAsync = ref.watch(eventsByShowMapProvider(false));

    final shows = showsAsync.value ?? const <Show>[];
    final stages = stagesAsync.value ?? const <Stage>[];
    final eventsMap = eventsAsync.value;
    final rows = eventsMap == null
        ? const <_EventRow>[]
        : _buildRows(eventsMap, shows, stages);
    final visible = _visible(rows);
    final isLoading = eventsAsync.isLoading && eventsMap == null;
    final error = eventsAsync.hasError ? eventsAsync.error : null;

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Oyun, sahne, tarih…',
          visibleCount: visible.length,
          totalCount: rows.length,
          primaryLabel: 'Yeni Seans',
          primarySemantics: 'Yeni seans ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'upcoming', label: 'Yaklaşan'),
                AdminFilterOption(id: 'past', label: 'Geçmiş'),
              ],
              selectedId: _timeFilter,
              onSelected: (final id) => setState(() => _timeFilter = id),
            ),
          ],
        ),
        Expanded(
          child: isLoading
              ? const AdminListLoading()
              : error != null
                  ? AdminListError(message: 'Seanslar yüklenemedi: $error')
                  : rows.isEmpty
                      ? const AdminEmptyList(message: 'Henüz seans eklenmemiş.')
                      : visible.isEmpty
                          ? const AdminEmptyList(
                              message: 'Henüz seans eklenmemiş.',
                              isFiltered: true)
                          : AdminCatalogPane<_EventRow>(
                              items: visible,
                              cardBuilder: (final row) => _EventCard(row: row,
                                  onTap: () => _open(row.event)),
                              table: AdminSortableTable<_EventRow>(
                                items: visible,
                                columns: _columns,
                                sortColumnId: _sortId,
                                sortAscending: _sortAsc,
                                onSort: (
                                        {required final columnId,
                                        required final ascending}) =>
                                    setState(() {
                                  _sortId = columnId;
                                  _sortAsc = ascending;
                                }),
                                onRowTap: (final row) => _open(row.event),
                                semanticLabel: (final r) =>
                                    '${r.showName}, ${r.stageName}, ${r.event.date}, düzenlemek için dokun',
                              ),
                            ),
        ),
      ],
    );
  }
}

class _EventRow {
  final Event event;
  final String showName;
  final String stageName;
  final bool isPast;

  const _EventRow({
    required this.event,
    required this.showName,
    required this.stageName,
    required this.isPast,
  });
}

class _TimeTag extends StatelessWidget {
  final bool isPast;

  const _TimeTag({required this.isPast});

  @override
  Widget build(final BuildContext context) {
    final color = isPast ? Colors.grey : Colors.green;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isPast ? 'Geçti' : 'Yaklaşan',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventRow row;
  final VoidCallback onTap;

  const _EventCard({required this.row, required this.onTap});

  @override
  Widget build(final BuildContext context) => AdminEntityCard(
        title: row.showName,
        subtitle: '${row.stageName} · ${adminFormatStamp(row.event.date)}',
        semanticLabel:
            '${row.showName}, ${row.stageName}, ${row.event.date}, düzenlemek için dokun',
        leading: CircleAvatar(
          backgroundColor:
              (row.isPast ? Colors.grey : Colors.green).withOpacity(0.15),
          child: Icon(Icons.event_rounded,
              color: row.isPast ? Colors.grey : Colors.green, size: 18),
        ),
        onTap: onTap,
      );
}
