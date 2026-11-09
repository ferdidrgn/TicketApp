import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/datasources/team_remote_data_source.dart';
import '../../domain/entities/team_manager_entities.dart';
import '../providers/team_providers.dart';
import 'team_manager_widgets.dart';

String _fmtWhen(final int ms) =>
    DateFormat('d MMM, HH:mm', 'tr_TR').format(DateTime.fromMillisecondsSinceEpoch(ms));

/// Ekip yöneticisi — "Özet" sekmesi: `teamStats` callable'ının döndürdüğü
/// satış/doluluk/giriş sayılarını gösterir. Kişisel veri YOK; yalnız
/// sunucunun verdiği sayılar kullanılır, uydurma metrik eklenmez.
class TeamStatsTab extends ConsumerWidget {
  final List<TeamManagerTeam> teams;

  const TeamStatsTab({super.key, required this.teams});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final statsAsync = ref.watch(teamStatsProvider(null));
    final teamNames = {for (final t in teams) t.teamId: t.name};

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teamStatsProvider(null)),
      child: statsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [TeamLoadingSkeleton(rows: 4, rowHeight: 100)],
        ),
        error: (final e, final st) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TeamInlineBanner(
              message: e is TeamException ? e.message : 'Özet yüklenemedi.',
            ),
          ],
        ),
        data: (final shows) {
          if (shows.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                TeamSectionCard(
                  child: TeamEmptyState(
                    message: 'Gösterilecek oyun yok.',
                    icon: Icons.theater_comedy_rounded,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final show in shows)
                _ShowStatsCard(show: show, teamName: teamNames[show.teamId]),
            ],
          );
        },
      ),
    );
  }
}

class _ShowStatsCard extends StatelessWidget {
  final TeamStatsShow show;
  final String? teamName;

  const _ShowStatsCard({required this.show, this.teamName});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return TeamSectionCard(
      title: show.name.isEmpty ? 'Oyun' : show.name,
      icon: Icons.theater_comedy_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (teamName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(teamName!,
                  style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant)),
            ),
          Row(
            children: [
              TeamStatTile(value: '${show.totals.sold}', label: 'Satılan'),
              TeamStatTile(value: '${show.totals.held}', label: 'Tutulan'),
              TeamStatTile(
                  value: '${show.totals.checkedIn}', label: 'Girişi yapılan'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (show.events.isEmpty)
            Text('Seans yok.', style: TextStyle(color: colors.onSurfaceVariant))
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: colors.surfaceContainerHighest),
                    children: [
                      _cell(context, 'Seans', isHeader: true),
                      _cell(context, 'Satılan', isHeader: true),
                      _cell(context, 'Doluluk', isHeader: true),
                      _cell(context, 'Giriş', isHeader: true),
                    ],
                  ),
                  for (final event in show.events)
                    TableRow(
                      children: [
                        _cell(context, _fmtWhen(event.ms)),
                        _cell(context, '${event.sold}/${event.total}'),
                        _cell(context, '%${event.occupancy}'),
                        _cell(context, '${event.checkedIn}/${event.activeTickets}'),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(final BuildContext context, final String text,
      {final bool isHeader = false}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: isHeader ? colors.onSurfaceVariant : colors.onSurface,
        ),
      ),
    );
  }
}
