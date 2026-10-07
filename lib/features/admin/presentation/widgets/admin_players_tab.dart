import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../pages/admin_player_form_page.dart';
import 'admin_table_tools.dart';

/// "Oyuncular" sekmesi — GERÇEK `playersProvider(isLimit: false)` listesini
/// yerelde arar; görseli olan / olmayan süzgeci; masaüstünde sıralanabilir
/// tablo, mobilde kart.
class AdminPlayersTab extends ConsumerStatefulWidget {
  const AdminPlayersTab({super.key});

  @override
  ConsumerState<AdminPlayersTab> createState() => _AdminPlayersTabState();
}

class _AdminPlayersTabState extends ConsumerState<AdminPlayersTab> {
  final _search = TextEditingController();
  String _image = 'all';
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

  String _fullName(final Player p) => '${p.firstName} ${p.lastName}'.trim();

  List<AdminTableColumn<Player>> get _columns => [
        AdminTableColumn<Player>(
          id: 'name',
          label: 'Ad',
          text: _fullName,
          compare: (final a, final b) =>
              adminCompareText(_fullName(a), _fullName(b)),
          cell: (final context, final p) => Row(
            children: [
              AdminThumb(imageUrl: p.imageUrl, fallback: Icons.person_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(_fullName(p),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        AdminTableColumn<Player>(
          id: 'image',
          label: 'Görsel',
          text: (final p) => p.imageUrl.trim().isEmpty ? 'Yok' : 'Var',
          compare: (final a, final b) => (a.imageUrl.trim().isEmpty ? 0 : 1)
              .compareTo(b.imageUrl.trim().isEmpty ? 0 : 1),
        ),
        AdminTableColumn<Player>(
          id: 'updated',
          label: 'Güncelleme',
          text: (final p) => adminFormatStamp(p.updatedAt),
          compare: (final a, final b) =>
              adminCompareDate(a.updatedAt, b.updatedAt),
        ),
      ];

  List<Player> _visible(final List<Player> players) {
    final filtered = players.where((final p) {
      final hasImage = p.imageUrl.trim().isNotEmpty;
      if (_image == 'has' && !hasImage) {
        return false;
      }
      if (_image == 'none' && hasImage) {
        return false;
      }
      return adminQueryHits(_search.text, [
        p.firstName,
        p.lastName,
        _fullName(p),
        p.bio,
      ]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Player? player) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (final _) => AdminPlayerFormPage(player: player)));
  }

  @override
  Widget build(final BuildContext context) {
    final playersAsync = ref.watch(playersProvider(isLimit: false));
    final players = playersAsync.value ?? const <Player>[];
    final visible = _visible(players);

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Oyuncu adı…',
          visibleCount: visible.length,
          totalCount: players.length,
          primaryLabel: 'Yeni Oyuncu',
          primarySemantics: 'Yeni oyuncu ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'has', label: 'Görseli var'),
                AdminFilterOption(id: 'none', label: 'Görseli yok'),
              ],
              selectedId: _image,
              onSelected: (final id) => setState(() => _image = id),
            ),
          ],
        ),
        Expanded(
          child: playersAsync.when(
            loading: () => const AdminListLoading(),
            error: (final e, final st) =>
                AdminListError(message: 'Oyuncular yüklenemedi: $e'),
            data: (final _) {
              if (players.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz oyuncu eklenmemiş.');
              if (visible.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz oyuncu eklenmemiş.', isFiltered: true);
              return AdminCatalogPane<Player>(
                items: visible,
                cardBuilder: (final player) => _PlayerRow(player: player),
                table: AdminSortableTable<Player>(
                  items: visible,
                  columns: _columns,
                  sortColumnId: _sortId,
                  sortAscending: _sortAsc,
                  onSort: ({required final columnId, required final ascending}) =>
                      setState(() {
                    _sortId = columnId;
                    _sortAsc = ascending;
                  }),
                  onRowTap: (final player) => _open(player),
                  semanticLabel: (final p) =>
                      '${_fullName(p)}, düzenlemek için dokun',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;

  const _PlayerRow({required this.player});

  @override
  Widget build(final BuildContext context) {
    final name = '${player.firstName} ${player.lastName}'.trim();
    return AdminEntityCard(
      title: name,
      subtitle: '${player.achievements.length} ödül · '
          '${player.collaborations.length} iş birliği'
          '${player.imageUrl.trim().isEmpty ? ' · görsel yok' : ''}',
      semanticLabel: '$name, düzenlemek için dokun',
      leading: AdminThumb(
          imageUrl: player.imageUrl, fallback: Icons.person_rounded),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (final _) => AdminPlayerFormPage(player: player))),
    );
  }
}
