import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../pages/admin_team_form_page.dart';
import 'admin_form_widgets.dart';

/// "Topluluklar" sekmesi — Phase 2: GERÇEK `teamsProvider(isLimit: false)`
/// verisiyle beslenen, düzenlemeye/silmeye giden tıklanabilir bir liste +
/// üstte "Yeni Topluluk" butonu (bkz. `AdminShowsTab`'daki AYNI desen).
class AdminTeamsTab extends ConsumerWidget {
  const AdminTeamsTab({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(isLimit: false));
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: 'Yeni topluluk ekle',
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (final _) => const AdminTeamFormPage())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Topluluk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final e, final st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child:
                    AdminInlineBanner(message: 'Topluluklar yüklenemedi: $e'),
              ),
            ),
            data: (final teams) {
              if (teams.isEmpty)
                return Center(
                    child: Text('Henüz topluluk eklenmemiş.',
                        style: TextStyle(color: colors.onSurfaceVariant)));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: teams.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (final context, final index) =>
                    _TeamRow(team: teams[index]),
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
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${team.name}, düzenlemek için dokun',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminTeamFormPage(team: team))),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: team.imageUrl.isNotEmpty
                    ? Image.network(team.imageUrl,
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (final c, final e, final s) =>
                            _placeholderIcon(colors))
                    : _placeholderIcon(colors),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      team.description.isNotEmpty
                          ? team.description
                          : 'Açıklama yok',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(final ColorScheme colors) => Container(
        width: 44,
        height: 44,
        color: colors.surfaceContainerHighest,
        child:
            Icon(Icons.groups_rounded, color: colors.onSurfaceVariant, size: 20),
      );
}
