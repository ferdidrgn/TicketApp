import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_mutation_provider.dart';
import '../pages/admin_campaign_form_page.dart';
import 'admin_table_tools.dart';

/// "Kampanyalar" sekmesi — GERÇEK `adminCampaignsProvider` (ham, süzgeçsiz
/// liste — bkz. `campaign_mutation_provider.dart`) listesini yerelde arar;
/// yayında/taslak süzgeci; masaüstünde sıralanabilir tablo, mobilde kart.
/// `admin_teams_tab.dart` ile AYNI desen.
class AdminCampaignsTab extends ConsumerStatefulWidget {
  const AdminCampaignsTab({super.key});

  @override
  ConsumerState<AdminCampaignsTab> createState() => _AdminCampaignsTabState();
}

class _AdminCampaignsTabState extends ConsumerState<AdminCampaignsTab> {
  final _search = TextEditingController();
  String _status = 'all';
  String _sortId = 'title';
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

  static String _dayLabel(final String raw) {
    final parsed = DateFormatter.parseDateString(raw);
    if (parsed == null) return '—';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  /// Kampanya başlığı ve görseli dolu değilse (web yönetim panelinden de
  /// girilebilen yarım kayıt) — bu, `campaignsProvider`'ın vitrinden
  /// gizlediği TAM AYNI koşul (bkz. `campaign_provider.dart`).
  static bool _isPublished(final Campaign c) =>
      c.title.trim().isNotEmpty && c.imageUrl.trim().isNotEmpty;

  List<AdminTableColumn<Campaign>> get _columns => [
        AdminTableColumn<Campaign>(
          id: 'title',
          label: 'Başlık',
          text: (final c) => c.title,
          compare: (final a, final b) => adminCompareText(a.title, b.title),
          cell: (final context, final c) => Row(
            children: [
              AdminThumb(imageUrl: c.imageUrl, fallback: Icons.local_offer_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(c.title.isEmpty ? 'İsimsiz kampanya' : c.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        AdminTableColumn<Campaign>(
          id: 'start',
          label: 'Başlangıç',
          text: (final c) => _dayLabel(c.startDate),
          compare: (final a, final b) =>
              adminCompareDate(a.startDate, b.startDate),
        ),
        AdminTableColumn<Campaign>(
          id: 'end',
          label: 'Bitiş',
          text: (final c) => _dayLabel(c.endDate),
          compare: (final a, final b) => adminCompareDate(a.endDate, b.endDate),
        ),
        AdminTableColumn<Campaign>(
          id: 'updated',
          label: 'Güncelleme',
          text: (final c) => adminFormatStamp(c.updatedAt),
          compare: (final a, final b) =>
              adminCompareDate(a.updatedAt, b.updatedAt),
        ),
      ];

  List<Campaign> _visible(final List<Campaign> campaigns) {
    final filtered = campaigns.where((final c) {
      final published = _isPublished(c);
      if (_status == 'published' && !published) return false;
      if (_status == 'draft' && published) return false;
      return adminQueryHits(_search.text, [c.title, c.url]);
    }).toList();
    return adminSorted(
      items: filtered,
      columns: _columns,
      sortColumnId: _sortId,
      sortAscending: _sortAsc,
    );
  }

  void _open(final Campaign? campaign) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (final _) => AdminCampaignFormPage(campaign: campaign)));
  }

  @override
  Widget build(final BuildContext context) {
    final campaignsAsync = ref.watch(adminCampaignsProvider);
    final campaigns = campaignsAsync.value ?? const <Campaign>[];
    final visible = _visible(campaigns);

    return Column(
      children: [
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Kampanya başlığı, bağlantı…',
          visibleCount: visible.length,
          totalCount: campaigns.length,
          primaryLabel: 'Yeni Kampanya',
          primarySemantics: 'Yeni kampanya ekle',
          onPrimary: () => _open(null),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'all', label: 'Tümü'),
                AdminFilterOption(id: 'published', label: 'Yayında'),
                AdminFilterOption(id: 'draft', label: 'Taslak'),
              ],
              selectedId: _status,
              onSelected: (final id) => setState(() => _status = id),
            ),
          ],
        ),
        Expanded(
          child: campaignsAsync.when(
            loading: () => const AdminListLoading(),
            error: (final e, final st) =>
                AdminListError(message: 'Kampanyalar yüklenemedi: $e'),
            data: (final _) {
              if (campaigns.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz kampanya eklenmemiş.');
              if (visible.isEmpty)
                return const AdminEmptyList(
                    message: 'Henüz kampanya eklenmemiş.', isFiltered: true);
              return AdminCatalogPane<Campaign>(
                items: visible,
                cardBuilder: (final campaign) =>
                    _CampaignRow(campaign: campaign),
                table: AdminSortableTable<Campaign>(
                  items: visible,
                  columns: _columns,
                  sortColumnId: _sortId,
                  sortAscending: _sortAsc,
                  onSort: ({required final columnId, required final ascending}) =>
                      setState(() {
                    _sortId = columnId;
                    _sortAsc = ascending;
                  }),
                  onRowTap: (final campaign) => _open(campaign),
                  semanticLabel: (final c) =>
                      '${c.title.isEmpty ? "İsimsiz kampanya" : c.title}, düzenlemek için dokun',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final Campaign campaign;

  const _CampaignRow({required this.campaign});

  @override
  Widget build(final BuildContext context) {
    final start = _AdminCampaignsTabState._dayLabel(campaign.startDate);
    final end = _AdminCampaignsTabState._dayLabel(campaign.endDate);
    final hasRange = start != '—' || end != '—';
    return AdminEntityCard(
      title: campaign.title.isEmpty ? 'İsimsiz kampanya' : campaign.title,
      subtitle: hasRange ? '$start – $end' : 'Tarih belirtilmemiş',
      semanticLabel:
          '${campaign.title.isEmpty ? "İsimsiz kampanya" : campaign.title}, düzenlemek için dokun',
      leading: AdminThumb(
          imageUrl: campaign.imageUrl, fallback: Icons.local_offer_rounded),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (final _) => AdminCampaignFormPage(campaign: campaign))),
    );
  }
}
