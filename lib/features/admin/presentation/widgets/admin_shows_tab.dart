import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../pages/admin_show_form_page.dart';
import 'admin_form_widgets.dart';

/// "Oyunlar" sekmesi — GERÇEK `showsProvider(isLimit: false)` verisiyle
/// beslenen liste + her satırda düzenlemeye giden bir ok + üstte "Yeni
/// Oyun" butonu.
class AdminShowsTab extends ConsumerWidget {
  const AdminShowsTab({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showsAsync = ref.watch(showsProvider(isLimit: false));
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
              label: 'Yeni oyun ekle',
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (final _) => const AdminShowFormPage())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Oyun'),
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
          child: showsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final e, final st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AdminInlineBanner(message: 'Oyunlar yüklenemedi: $e'),
              ),
            ),
            data: (final shows) {
              if (shows.isEmpty)
                return Center(
                    child: Text('Henüz oyun eklenmemiş.',
                        style: TextStyle(color: colors.onSurfaceVariant)));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: shows.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (final context, final index) =>
                    _ShowRow(show: shows[index]),
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
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${show.name}, düzenlemek için dokun',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminShowFormPage(show: show))),
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
                child: show.imageUrl.isNotEmpty
                    ? Image.network(show.imageUrl,
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
                    Text(show.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      show.hasExternalTicketing
                          ? 'Harici bilet'
                          : (show.category.isNotEmpty
                              ? show.category
                              : 'Kategori yok'),
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
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
        child: Icon(Icons.theater_comedy_rounded,
            color: colors.onSurfaceVariant, size: 20),
      );
}
