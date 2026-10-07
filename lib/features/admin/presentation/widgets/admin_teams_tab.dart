import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../pages/admin_team_form_page.dart';
import 'admin_table_tools.dart';

/// "Topluluklar" sekmesi — GERÇEK `teamsProvider(isLimit: false)` listesini
/// yerelde arar; oyunu olan / boş süzgeci; masaüstünde sıralanabilir
/// tablo, mobilde kart.
class AdminTeamsTab extends ConsumerStatefulWidget {
  const AdminTeamsTab({super.key});

  @override
  ConsumerState<AdminTeamsTab> createState() => _AdminTeamsTabState();
}

class _AdminTeamsTabState extends ConsumerState<AdminTeamsTab> {
  final _search = TextEditingController();
  String _shows = 'all';
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

  List<AdminTableColumn<Team>> get _columns => [
        AdminTableColumn<Team>(
          id: 'name',
          label: 'Ad',
          text: (final t) => t.name,
          compare: (final a, final b) => adminCompareText(a.name, b.name),
          cell: (final context, final t) => Row(
            children: [
              AdminThumb(imageUrl: t.imageUrl, fallback: Icons.groups_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(t.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        AdminTableColumn<Team>(
          id: 'shows',
          label: 'Oyunlar',
          text: (final t) => '${t.showsId.length}',
          compare: (final a, final b) =>
              a.showsId.length.compareTo(b.showsId.length),
          numeric: true,
        ),
        AdminTableColumn<Team>(
          id: 'updated',
          label: 'Güncelleme',
          text: (final t) => adminFormatStamp(t.updatedAt),
          compare: (final a, final b) =>
              adminCompareDate(a.updatedAt, b.updatedAt),
        ),
      ];

  List<Team> _visible(final List<Team> teams) {
    final filtered = teams.where((final t) {
      final hasShows = t.showsId.isNotEmpty;
      if (_shows == 'has' && !hasShows) {
        return false;
      }
      if (_shows == 'empty' && hasShows) {
        return false;
      }
      return adminQueryHits(_search.text, [t.name, t.description]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Team? team) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (final _) => AdminTeamFormPage(team: team)));
  }

  @override
  Widget build(final BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider(isLimit: false));
    final teams = teamsAsync.value ?? const <Team>[];
    final visible = _visible(teams);

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Topluluk adı, açıklama…',
          visibleCount: visible.length,
          totalCount: teams.length,
          primaryLabel: 'Yeni Topluluk',
          primarySemantics: 'Yeni topluluk ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'has', label: 'Oyunu var'),
                AdminFilterOption(id: 'empty', label: 'Oyunu yok'),
              ],
              selectedId: _shows,
              onSelected: (final id) => setState(() => _shows = id),
            ),
          ],
        ),
        Expanded(
          child: teamsAsync.when(
            loading: () => const AdminListLoading(),
            error: (final e, final st) =>
                AdminListError(message: 'Topluluklar yüklenemedi: $e'),
            data: (final _) {
              if (teams.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz topluluk eklenmemiş.');
              if (visible.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz topluluk eklenmemiş.', isFiltered: true);
              return AdminCatalogPane<Team>(
                items: visible,
                cardBuilder: (final team) => _TeamRow(team: team),
                table: AdminSortableTable<Team>(
                  items: visible,
                  columns: _columns,
                  sortColumnId: _sortId,
                  sortAscending: _sortAsc,
                  onSort: ({required final columnId, required final ascending}) =>
                      setState(() {
                    _sortId = columnId;
                    _sortAsc = ascending;
                  }),
                  onRowTap: (final team) => _open(team),
                  semanticLabel: (final t) =>
                      '${t.name}, düzenlemek için dokun',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  final Team team;

  const _TeamRow({required this.team});

  @override
  Widget build(final BuildContext context) => AdminEntityCard(
        title: team.name,
        subtitle: team.showsId.isEmpty
            ? 'Kayıtlı oyun yok'
            : '${team.showsId.length} oyun'
                '${team.description.isNotEmpty ? ' · ${team.description}' : ''}',
        semanticLabel: '${team.name}, düzenlemek için dokun',
        leading:
            AdminThumb(imageUrl: team.imageUrl, fallback: Icons.groups_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminTeamFormPage(team: team))),
      );
}
