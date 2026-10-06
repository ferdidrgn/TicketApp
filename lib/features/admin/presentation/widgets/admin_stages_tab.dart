import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../pages/admin_stage_form_page.dart';
import 'admin_form_widgets.dart';

/// "Sahneler" sekmesi — Phase 2: GERÇEK `stagesProvider(isLimit: false)`
/// verisiyle beslenen, düzenlemeye/silmeye giden tıklanabilir bir liste +
/// üstte "Yeni Sahne" butonu (bkz. `AdminShowsTab`'daki AYNI desen).
class AdminStagesTab extends ConsumerWidget {
  const AdminStagesTab({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
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
              label: 'Yeni sahne ekle',
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (final _) => const AdminStageFormPage())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Sahne'),
                style: adminPrimaryActionStyle(context),
              ),
            ),
          ),
        ),
        Expanded(
          child: stagesAsync.when(
            loading: () => const AdminListSkeleton(),
            error: (final e, final st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AdminInlineBanner(message: 'Sahneler yüklenemedi: $e'),
              ),
            ),
            data: (final stages) {
              if (stages.isEmpty)
                return Center(
                    child: Text('Henüz sahne eklenmemiş.',
                        style: TextStyle(color: colors.onSurfaceVariant)));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: stages.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (final context, final index) =>
                    _StageRow(stage: stages[index]),
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
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${stage.name}, düzenlemek için dokun',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminStageFormPage(stage: stage))),
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
                child: stage.imageUrl.isNotEmpty
                    ? Image.network(stage.imageUrl,
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
                    Text(stage.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      stage.address.isNotEmpty ? stage.address : 'Adres yok',
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
        child: Icon(Icons.location_city_rounded,
            color: colors.onSurfaceVariant, size: 20),
      );
}
