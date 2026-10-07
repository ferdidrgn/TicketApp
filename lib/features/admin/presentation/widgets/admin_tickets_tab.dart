import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/repositories/event_repository.dart'
    show kAdminBlockCustomerId;
import '../../../events/presentation/providers/event_mutation_provider.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../seat/presentation/providers/seats_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/admin_ticket_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import 'admin_form_widgets.dart';
import 'admin_table_tools.dart';

/// "Biletler / Koltuklar" sekmesi — Phase 2'nin gerçekten YENİ alanı.
///
/// Akış: bir Oyun (Show) seç -> o oyunun seansları (Event) arasından birini
/// seç -> o seansa ait GERÇEK biletleri (`ticketsByEventIdProvider`, alıcı
/// kimliği `userByIdProvider(uid)` ile çözülür) ve GERÇEK koltuk haritasını
/// (`stageLayoutProvider` + `eventSeatsProvider`, `seat_info.dart`'taki
/// `CuratorSeatingAuditPage` ile AYNI veri kaynakları) gör. Müsait bir
/// koltuğa dokunup operasyonel gerekçeyle (arızalı koltuk, kontenjan
/// tutma) bloke edebilir/serbest bırakabilirsin — gerçek bir satış/
/// rezervasyona ASLA dokunulmaz (bkz. `EventRepository.
/// adminSetSeatBlocked`).
class AdminTicketsTab extends ConsumerStatefulWidget {
  const AdminTicketsTab({super.key});

  @override
  ConsumerState<AdminTicketsTab> createState() => _AdminTicketsTabState();
}

class _AdminTicketsTabState extends ConsumerState<AdminTicketsTab> {
  String? _selectedShowId;
  String? _selectedEventId;
  final _showSearch = TextEditingController();
  String _eventWhen = 'all';

  @override
  void initState() {
    super.initState();
    _showSearch.addListener(_onShowSearch);
  }

  void _onShowSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _showSearch.removeListener(_onShowSearch);
    _showSearch.dispose();
    super.dispose();
  }

  List<Show> _visibleShows(final List<Show> shows) {
    if (_showSearch.text.trim().isEmpty) {
      return shows;
    }
    return shows
        .where((final s) =>
            adminQueryHits(_showSearch.text, [s.name, s.category, s.type]))
        .toList();
  }

  List<Event> _visibleEvents(final List<Event> events) {
    if (_eventWhen == 'all') {
      return events;
    }
    return events.where((final e) {
      final date = DateFormatter.parseDateString(e.date);
      if (date == null) {
        return false;
      }
      final past = date.isBefore(DateTime.now());
      return _eventWhen == 'past' ? past : !past;
    }).toList();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final showsAsync = ref.watch(showsProvider(isLimit: false));
    final shows = showsAsync.value ?? const <Show>[];
    final visibleShows = _visibleShows(shows);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(
              title: 'Bilet / Koltuk Denetimi',
              icon: Icons.confirmation_number_rounded),
          Text(
            'Bir oyun ve seans seç; o seansın gerçek biletlerini ve koltuk '
            'durumunu gör.',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          AdminListToolbar(
            searchController: _showSearch,
            searchHint: 'Oyun ara…',
            visibleCount: visibleShows.length,
            totalCount: shows.length,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
          showsAsync.when(
            loading: () => const AdminListLoading(rows: 3),
            error: (final e, final st) =>
                AdminInlineBanner(message: 'Oyunlar yüklenemedi: $e'),
            data: (final _) {
              if (shows.isEmpty)
                return const AdminInlineBanner(
                    message: 'Henüz oyun eklenmemiş.');
              if (visibleShows.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz oyun eklenmemiş.', isFiltered: true);
              final dropdownShows = _dropdownShows(shows, visibleShows);
              return AdminDropdownField<String>(
                label: 'Oyun',
                value: _selectedShowId,
                items: dropdownShows
                    .map((final s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (final v) => setState(() {
                  _selectedShowId = v;
                  _selectedEventId = null;
                }),
              );
            },
          ),
          if (_selectedShowId != null)
            Consumer(
              builder: (final context, final ref, final _) {
                // Tek String anahtarlı sağlayıcı: liste anahtarı her çizimde
                // yeni sorgu başlatıp sonsuz yüklemeye sokuyordu.
                final eventsAsync =
                    ref.watch(eventsForShowProvider(_selectedShowId!));
                return eventsAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: LinearProgressIndicator()),
                  error: (final e, final st) => AdminInlineBanner(
                      message: 'Seanslar yüklenemedi: $e'),
                  data: (final events) {
                    if (events.isEmpty)
                      return const AdminInlineBanner(
                          message: 'Bu oyunun henüz bir seansı yok.');
                    final visible = _visibleEvents(events);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminFilterChipRow(
                          group: AdminFilterGroup(
                            options: const [
                              AdminFilterOption(id: 'all', label: 'Tümü'),
                              AdminFilterOption(
                                  id: 'upcoming', label: 'Yaklaşan'),
                              AdminFilterOption(id: 'past', label: 'Geçmiş'),
                            ],
                            selectedId: _eventWhen,
                            onSelected: (final id) => setState(() {
                              _eventWhen = id;
                              _selectedEventId = null;
                            }),
                          ),
                        ),
                        if (visible.isEmpty)
                          const AdminEmptyList(
                              message: 'Bu oyunun henüz bir seansı yok.',
                              isFiltered: true)
                        else
                          AdminDropdownField<String>(
                            label: 'Seans',
                            value: visible.any(
                                    (final e) => e.id == _selectedEventId)
                                ? _selectedEventId
                                : null,
                            items: visible
                                .map((final e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(_sessionLabel(e))))
                                .toList(),
                            onChanged: (final v) =>
                                setState(() => _selectedEventId = v),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          if (_selectedEventId != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _TicketListSection(eventId: _selectedEventId!),
            const SizedBox(height: AppSpacing.xl),
            _SeatMapSection(eventId: _selectedEventId!),
          ],
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  List<Show> _dropdownShows(
      final List<Show> all, final List<Show> visible) {
    if (_selectedShowId == null) {
      return visible;
    }
    if (visible.any((final s) => s.id == _selectedShowId)) {
      return visible;
    }
    final selected = all.where((final s) => s.id == _selectedShowId);
    return [...selected, ...visible];
  }
}

/// Seans seçicideki okunur etiket: "3 Eki 2026 Cmt, 15:30" — geçmiş
/// seanslar "(geçti)" ile işaretlenir. Tarih okunamazsa ham değer.
String _sessionLabel(final Event e) {
  final DateTime? d = DateFormatter.parseDateString(e.date);
  if (d == null) return e.date.isEmpty ? 'Tarihsiz seans' : e.date;
  final String label = DateFormat('d MMM y EEE, HH:mm', 'tr').format(d);
  return d.isBefore(DateTime.now()) ? '$label (geçti)' : label;
}

// ==============================================================================
// BİLET LİSTESİ
// ==============================================================================

class _TicketListSection extends ConsumerStatefulWidget {
  final String eventId;

  const _TicketListSection({required this.eventId});

  @override
  ConsumerState<_TicketListSection> createState() => _TicketListSectionState();
}

class _TicketListSectionState extends ConsumerState<_TicketListSection> {
  final _search = TextEditingController();
  String _when = 'all';
  String _sortId = 'updated';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  List<AdminTableColumn<Ticket>> get _columns => [
        AdminTableColumn<Ticket>(
          id: 'name',
          label: 'Alıcı',
          text: (final t) => t.customerId,
          compare: (final a, final b) =>
              adminCompareText(a.customerId, b.customerId),
          cell: (final context, final t) => _TicketBuyerLabel(ticket: t),
        ),
        AdminTableColumn<Ticket>(
          id: 'seats',
          label: 'Koltuklar',
          text: (final t) => t.buySeats.join(', '),
          compare: (final a, final b) =>
              adminCompareText(a.buySeats.join(', '), b.buySeats.join(', ')),
        ),
        AdminTableColumn<Ticket>(
          id: 'price',
          label: 'Tutar',
          text: (final t) => '${t.orderPrice} ₺',
          compare: (final a, final b) {
            final pa = double.tryParse(a.orderPrice.replaceAll(',', '.')) ?? 0;
            final pb = double.tryParse(b.orderPrice.replaceAll(',', '.')) ?? 0;
            return pa.compareTo(pb);
          },
          numeric: true,
        ),
        AdminTableColumn<Ticket>(
          id: 'updated',
          label: 'Satın alma',
          text: (final t) => adminFormatStamp(t.createdAt),
          compare: (final a, final b) =>
              adminCompareDate(a.createdAt, b.createdAt),
        ),
        AdminTableColumn<Ticket>(
          id: 'status',
          label: 'Durum',
          text: (final t) => (t.isPast ?? false) ? 'Geçmiş' : 'Aktif',
          compare: (final a, final b) =>
              (a.isPast ?? false ? 1 : 0).compareTo(b.isPast ?? false ? 1 : 0),
        ),
      ];

  List<Ticket> _visible(final List<Ticket> tickets) {
    final filtered = tickets.where((final t) {
      final past = t.isPast ?? false;
      if (_when == 'past' && !past) {
        return false;
      }
      if (_when == 'upcoming' && past) {
        return false;
      }
      return adminQueryHits(_search.text, [
        t.customerId,
        t.buySeats.join(' '),
        t.orderMethod,
        t.orderPrice,
        t.id,
      ]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ticketsAsync = ref.watch(ticketsByEventIdProvider(widget.eventId));
    final tickets = ticketsAsync.value ?? const <Ticket>[];
    final visible = _visible(tickets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Satılan Biletler', icon: Icons.receipt_long_rounded),
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Alıcı, koltuk, sipariş…',
          visibleCount: visible.length,
          totalCount: tickets.length,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'upcoming', label: 'Aktif'),
                AdminFilterOption(id: 'past', label: 'Geçmiş'),
              ],
              selectedId: _when,
              onSelected: (final id) => setState(() => _when = id),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ticketsAsync.when(
          loading: () => const AdminListLoading(rows: 4),
          error: (final e, final st) =>
              AdminInlineBanner(message: 'Biletler yüklenemedi: $e'),
          data: (final _) {
            if (tickets.isEmpty)
              return const AdminEmptyList(
                  message: 'Bu seans için henüz satılmış bir bilet yok.');
            if (visible.isEmpty)
              return const AdminEmptyList(
                  message: 'Bu seans için henüz satılmış bir bilet yok.',
                  isFiltered: true);
            return AdminCatalogPane<Ticket>(
              items: visible,
              shrinkWrap: true,
              cardBuilder: (final t) => _TicketRow(ticket: t),
              table: AdminSortableTable<Ticket>(
                items: visible,
                columns: _columns,
                sortColumnId: _sortId,
                sortAscending: _sortAsc,
                onSort: ({required final columnId, required final ascending}) =>
                    setState(() {
                  _sortId = columnId;
                  _sortAsc = ascending;
                }),
                semanticLabel: (final t) =>
                    'Bilet ${t.id}, koltuk ${t.buySeats.join(', ')}',
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TicketBuyerLabel extends ConsumerWidget {
  final Ticket ticket;

  const _TicketBuyerLabel({required this.ticket});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(ticket.customerId));
    final colors = context.colors;
    return userAsync.when(
      loading: () => Text('Yükleniyor…',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
      error: (final e, final st) => Text(ticket.customerId,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      data: (final user) => Text(
        user != null
            ? '${user.firstName} ${user.lastName}'
            : 'uid: ${ticket.customerId}',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _TicketRow extends ConsumerWidget {
  final Ticket ticket;

  const _TicketRow({required this.ticket});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colors = context.colors;
    final userAsync = ref.watch(userByIdProvider(ticket.customerId));

    final purchasedAt = DateFormatter.parseDateString(ticket.createdAt);
    final purchasedLabel = purchasedAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(purchasedAt)
        : ticket.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_rounded, color: colors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userAsync.when(
                  loading: () => Text('Yükleniyor…',
                      style: TextStyle(
                          fontSize: 13, color: colors.onSurfaceVariant)),
                  error: (final e, final st) => Text(
                      'Kullanıcı: ${ticket.customerId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  data: (final user) => Text(
                    user != null
                        ? '${user.firstName} ${user.lastName} · ${user.eMail}'
                        // 🔥 DÜRÜSTLÜK: Kullanıcı dökümanı bulunamazsa
                        // (silinmiş hesap vb.) sahte bir isim UYDURULMAZ —
                        // ham uid gösterilir.
                        : 'Kullanıcı bulunamadı (uid: ${ticket.customerId})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Koltuklar: ${ticket.buySeats.join(', ')}',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant)),
                Text('Satın alma: $purchasedLabel · ${ticket.orderMethod}',
                    style: TextStyle(
                        fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${ticket.orderPrice} ₺',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: colors.primary)),
              Text(ticket.isPast == true ? 'Geçmiş' : 'Aktif',
                  style: TextStyle(
                      fontSize: 11, color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// KOLTUK HARİTASI
// ==============================================================================

class _SeatMapSection extends ConsumerWidget {
  final String eventId;

  const _SeatMapSection({required this.eventId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colors = context.colors;
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Koltuk Haritası', icon: Icons.event_seat_rounded),
        Text(
          'Sadece MÜSAİT koltuklar bloke edilebilir; bir admin bloğu sadece '
          'buradan serbest bırakılabilir. Gerçek bir satış/rezervasyona '
          'dokunulmaz.',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        eventAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator())),
          error: (final e, final st) =>
              AdminInlineBanner(message: 'Seans yüklenemedi: $e'),
          data: (final event) => _SeatGrid(event: event),
        ),
      ],
    );
  }
}

class _SeatGrid extends ConsumerWidget {
  final Event event;

  const _SeatGrid({required this.event});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colors = context.colors;
    final layoutAsync = ref.watch(stageLayoutProvider(event.stageId));
    final seatsAsync = ref.watch(eventSeatsProvider(event.id));

    return layoutAsync.when(
      loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator())),
      error: (final e, final st) =>
          AdminInlineBanner(message: 'Sahne düzeni yüklenemedi: $e'),
      data: (final layout) => seatsAsync.when(
        loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator())),
        error: (final e, final st) =>
            AdminInlineBanner(message: 'Koltuklar yüklenemedi: $e'),
        data: (final seatStatus) {
          if (layout.isEmpty)
            return Text('Bu sahne için koltuk düzeni tanımlı değil.',
                style: TextStyle(color: colors.onSurfaceVariant));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SeatLegend(),
              const SizedBox(height: AppSpacing.sm),
              ...layout.entries.map((final row) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(row.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: row.value
                                .map((final seatId) => _SeatCell(
                                      eventId: event.id,
                                      seatId: seatId,
                                      info: seatStatus[seatId],
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(final BuildContext context) {
    Widget dot(final Color c, final String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(AppRadius.xs))),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        );
    return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.xs, children: [
      dot(Colors.green, 'Müsait'),
      dot(Colors.orange, 'Rezerve'),
      dot(Colors.red, 'Satıldı'),
      dot(Colors.black54, 'Admin Bloğu'),
    ]);
  }
}

class _SeatCell extends ConsumerWidget {
  final String eventId;
  final String seatId;
  final Map<String, dynamic>? info;

  const _SeatCell(
      {required this.eventId, required this.seatId, required this.info});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final status = info?['status'] as String? ?? 'available';
    final customerId = info?['customerId'] as String?;
    final isAdminBlocked =
        status == 'sold' && customerId == kAdminBlockCustomerId;

    final Color color;
    if (isAdminBlocked)
      color = Colors.black54;
    else if (status == 'sold')
      color = Colors.red;
    else if (status == 'reserved')
      color = Colors.orange;
    else
      color = Colors.green;

    return Semantics(
      button: true,
      label: '$seatId koltuğu, '
          '${isAdminBlocked ? 'admin bloğu' : switch (status) {
              'sold' => 'satıldı',
              'reserved' => 'rezerve',
              'available' => 'boş',
              _ => status,
            }}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: () => _showSeatSheet(context, ref, status, isAdminBlocked),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            seatId.replaceAll(RegExp('[^0-9]'), ''),
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showSeatSheet(final BuildContext context, final WidgetRef ref,
      final String status, final bool isAdminBlocked) {
    showModalBottomSheet(
      context: context,
      builder: (final sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Koltuk $seatId',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: AppSpacing.xs),
              Text('Durum: ${isAdminBlocked ? 'Admin bloğu' : status}'),
              const SizedBox(height: AppSpacing.lg),
              if (status == 'available')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _setBlocked(context, ref, true);
                    },
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Koltuğu Bloke Et'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white),
                  ),
                )
              else if (isAdminBlocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _setBlocked(context, ref, false);
                    },
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Bloğu Kaldır (Müsait Yap)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                )
              else
                Text(
                  'Bu koltuk gerçek bir satış/rezervasyon içeriyor — '
                  'buradan değiştirilemez.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setBlocked(
      final BuildContext context, final WidgetRef ref, final bool blocked) async {
    await ref
        .read(eventMutationProvider.notifier)
        .adminSetSeatBlocked(eventId, seatId, blocked);
    if (!context.mounted) return;
    final state = ref.read(eventMutationProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('İşlem başarısız: ${state.error}'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(blocked ? 'Koltuk bloke edildi.' : 'Koltuk serbest bırakıldı.'),
        backgroundColor: Colors.green,
      ));
    }
  }
}
