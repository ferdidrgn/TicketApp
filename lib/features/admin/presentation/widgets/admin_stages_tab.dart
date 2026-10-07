import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../pages/admin_stage_form_page.dart';
import 'admin_table_tools.dart';

/// "Sahneler" sekmesi — GERÇEK `stagesProvider(isLimit: false)` listesini
/// yerelde arar; adresi dolu / boş süzgeci; masaüstünde sıralanabilir
/// tablo, mobilde kart.
class AdminStagesTab extends ConsumerStatefulWidget {
  const AdminStagesTab({super.key});

  @override
  ConsumerState<AdminStagesTab> createState() => _AdminStagesTabState();
}

class _AdminStagesTabState extends ConsumerState<AdminStagesTab> {
  final _search = TextEditingController();
  String _address = 'all';
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

  List<AdminTableColumn<Stage>> get _columns => [
        AdminTableColumn<Stage>(
          id: 'name',
          label: 'Ad',
          text: (final s) => s.name,
          compare: (final a, final b) => adminCompareText(a.name, b.name),
          cell: (final context, final s) => Row(
            children: [
              AdminThumb(
                  imageUrl: s.imageUrl, fallback: Icons.location_city_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        AdminTableColumn<Stage>(
          id: 'address',
          label: 'Adres',
          text: (final s) => s.address.isEmpty ? 'Adres yok' : s.address,
          compare: (final a, final b) =>
              adminCompareText(a.address, b.address),
        ),
        AdminTableColumn<Stage>(
          id: 'updated',
          label: 'Güncelleme',
          text: (final s) => adminFormatStamp(s.updatedAt),
          compare: (final a, final b) =>
              adminCompareDate(a.updatedAt, b.updatedAt),
        ),
      ];

  List<Stage> _visible(final List<Stage> stages) {
    final filtered = stages.where((final s) {
      final filled = s.address.trim().isNotEmpty;
      if (_address == 'filled' && !filled) {
        return false;
      }
      if (_address == 'empty' && filled) {
        return false;
      }
      return adminQueryHits(_search.text, [
        s.name,
        s.address,
        s.description,
        s.capacity,
      ]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Stage? stage) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (final _) => AdminStageFormPage(stage: stage)));
  }

  @override
  Widget build(final BuildContext context) {
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
    final stages = stagesAsync.value ?? const <Stage>[];
    final visible = _visible(stages);

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Sahne adı, adres…',
          visibleCount: visible.length,
          totalCount: stages.length,
          primaryLabel: 'Yeni Sahne',
          primarySemantics: 'Yeni sahne ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'filled', label: 'Adresi dolu'),
                AdminFilterOption(id: 'empty', label: 'Adres yok'),
              ],
              selectedId: _address,
              onSelected: (final id) => setState(() => _address = id),
            ),
          ],
        ),
        Expanded(
          child: stagesAsync.when(
            loading: () => const AdminListLoading(),
            error: (final e, final st) =>
                AdminListError(message: 'Sahneler yüklenemedi: $e'),
            data: (final _) {
              if (stages.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz sahne eklenmemiş.');
              if (visible.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz sahne eklenmemiş.', isFiltered: true);
              return AdminCatalogPane<Stage>(
                items: visible,
                cardBuilder: (final stage) => _StageRow(stage: stage),
                table: AdminSortableTable<Stage>(
                  items: visible,
                  columns: _columns,
                  sortColumnId: _sortId,
                  sortAscending: _sortAsc,
                  onSort: ({required final columnId, required final ascending}) =>
                      setState(() {
                    _sortId = columnId;
                    _sortAsc = ascending;
                  }),
                  onRowTap: (final stage) => _open(stage),
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

class _StageRow extends StatelessWidget {
  final Stage stage;

  const _StageRow({required this.stage});

  @override
  Widget build(final BuildContext context) => AdminEntityCard(
        title: stage.name,
        subtitle: stage.address.isNotEmpty ? stage.address : 'Adres yok',
        semanticLabel: '${stage.name}, düzenlemek için dokun',
        leading: AdminThumb(
            imageUrl: stage.imageUrl, fallback: Icons.location_city_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminStageFormPage(stage: stage))),
      );
}
