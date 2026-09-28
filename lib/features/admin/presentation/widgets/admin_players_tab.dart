import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../pages/admin_player_form_page.dart';
import 'admin_form_widgets.dart';

/// "Oyuncular" sekmesi — Phase 2: GERÇEK `playersProvider(isLimit: false)`
/// verisiyle beslenen, düzenlemeye/silmeye giden tıklanabilir bir liste +
/// üstte "Yeni Oyuncu" butonu (bkz. `AdminShowsTab`'daki AYNI desen).
/// `achievements`/`collaborations` düzenleme artık `AdminPlayerFormPage`
/// içinde gerçek bir editör (bkz. o dosya) — Phase 1'in bilinçli sınırı
/// kapatıldı.
class AdminPlayersTab extends ConsumerWidget {
  const AdminPlayersTab({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider(isLimit: false));
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
              label: 'Yeni oyuncu ekle',
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (final _) => const AdminPlayerFormPage())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Oyuncu'),
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
          child: playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final e, final st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child:
                    AdminInlineBanner(message: 'Oyuncular yüklenemedi: $e'),
              ),
            ),
            data: (final players) {
              if (players.isEmpty)
                return Center(
                    child: Text('Henüz oyuncu eklenmemiş.',
                        style: TextStyle(color: colors.onSurfaceVariant)));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: players.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (final context, final index) =>
                    _PlayerRow(player: players[index]),
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
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '${player.firstName} ${player.lastName}, düzenlemek için dokun',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (final _) => AdminPlayerFormPage(player: player))),
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
                child: player.imageUrl.isNotEmpty
                    ? Image.network(player.imageUrl,
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
                    Text('${player.firstName} ${player.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${player.achievements.length} ödül · '
                      '${player.collaborations.length} iş birliği',
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
        child:
            Icon(Icons.person_rounded, color: colors.onSurfaceVariant, size: 20),
      );
}
