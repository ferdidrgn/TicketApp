import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../pages/admin_show_form_page.dart';
import 'admin_table_tools.dart';

/// "Oyunlar" sekmesi — GERÇEK `showsProvider(isLimit: false)` listesini
/// yerelde arar, kategori / harici-iç bilet ile süzer; masaüstünde
/// sıralanabilir tablo, mobilde kart.
class AdminShowsTab extends ConsumerStatefulWidget {
  const AdminShowsTab({super.key});

  @override
  ConsumerState<AdminShowsTab> createState() => _AdminShowsTabState();
}

class _AdminShowsTabState extends ConsumerState<AdminShowsTab> {
  final _search = TextEditingController();
  String _ticketKind = 'all';
  String _category = 'all';
  String _sortId = 'name';
  bool _sortAsc = true;

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

  List<AdminTableColumn<Show>> get _columns => [
        AdminTableColumn<Show>(
          id: 'name',
          label: 'Ad',
          text: (final s) => s.name,
          compare: (final a, final b) => adminCompareText(a.name, b.name),
          cell: (final context, final s) => Row(
            children: [
              AdminThumb(
                  imageUrl: s.imageUrl, fallback: Icons.theater_comedy_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        AdminTableColumn<Show>(
          id: 'category',
          label: 'Kategori',
          text: (final s) => s.category.isEmpty ? '—' : s.category,
          compare: (final a, final b) =>
              adminCompareText(a.category, b.category),
        ),
        AdminTableColumn<Show>(
          id: 'ticket',
          label: 'Bilet',
          text: (final s) =>
              s.hasExternalTicketing ? 'Harici' : 'Uygulama içi',
          compare: (final a, final b) => (a.hasExternalTicketing ? 1 : 0)
              .compareTo(b.hasExternalTicketing ? 1 : 0),
        ),
        AdminTableColumn<Show>(
          id: 'updated',
          label: 'Güncelleme',
          text: (final s) => adminFormatStamp(s.updatedAt),
          compare: (final a, final b) =>
              adminCompareDate(a.updatedAt, b.updatedAt),
        ),
      ];

  List<Show> _visible(final List<Show> shows) {
    final filtered = shows.where((final s) {
      if (_ticketKind == 'external' && !s.hasExternalTicketing) {
        return false;
      }
      if (_ticketKind == 'internal' && s.hasExternalTicketing) {
        return false;
      }
      if (_category != 'all' && s.category != _category) {
        return false;
      }
      return adminQueryHits(_search.text, [
        s.name,
        s.category,
        s.type,
        s.description,
      ]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Show? show) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (final _) => AdminShowFormPage(show: show)));
  }

  @override
  Widget build(final BuildContext context) {
    final showsAsync = ref.watch(showsProvider(isLimit: false));
    final shows = showsAsync.value ?? const <Show>[];
    final visible = _visible(shows);
    final categories = shows
        .map((final s) => s.category.trim())
        .where((final c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort(adminCompareText);

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Oyun adı, kategori…',
          visibleCount: visible.length,
          totalCount: shows.length,
          primaryLabel: 'Yeni Oyun',
          primarySemantics: 'Yeni oyun ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'internal', label: 'Uygulama içi'),
                AdminFilterOption(id: 'external', label: 'Harici bilet'),
              ],
              selectedId: _ticketKind,
              onSelected: (final id) => setState(() => _ticketKind = id),
            ),
            if (categories.isNotEmpty)
              AdminFilterGroup(
                options: [
                  const AdminFilterOption(id: 'all', label: 'Tüm kategoriler'),
                  ...categories.map((final c) =>
                      AdminFilterOption(id: c, label: c)),
                ],
                selectedId: _category,
                onSelected: (final id) => setState(() => _category = id),
              ),
          ],
        ),
        Expanded(
          child: showsAsync.when(
            loading: () => const AdminListLoading(),
            error: (final e, final st) =>
                AdminListError(message: 'Oyunlar yüklenemedi: $e'),
            data: (final _) {
              if (shows.isEmpty)
                return const AdminEmptyList(message: 'Henüz oyun eklenmemiş.');
              if (visible.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz oyun eklenmemiş.', isFiltered: true);
              return AdminCatalogPane<Show>(
                items: visible,
                cardBuilder: (final show) => _ShowRow(show: show),
                table: AdminSortableTable<Show>(
                  items: visible,
                  columns: _columns,
                  sortColumnId: _sortId,
                  sortAscending: _sortAsc,
                  onSort: ({required final columnId, required final ascending}) =>
                      setState(() {
                    _sortId = columnId;
                    _sortAsc = ascending;
                  }),
                  onRowTap: (final show) => _open(show),
                  semanticLabel: (final s) =>
                      '${s.name}, düzenlemek için dokun',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShowRow extends StatelessWidget {
  final Show show;

  const _ShowRow({required this.show});

  @override
  Widget build(final BuildContext context) => AdminEntityCard(
        title: show.name,
        subtitle: show.hasExternalTicketing
            ? 'Harici bilet'
            : (show.category.isNotEmpty ? show.category : 'Kategori yok'),
        semanticLabel: '${show.name}, düzenlemek için dokun',
        leading: AdminThumb(
            imageUrl: show.imageUrl, fallback: Icons.theater_comedy_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminShowFormPage(show: show))),
      );
}
