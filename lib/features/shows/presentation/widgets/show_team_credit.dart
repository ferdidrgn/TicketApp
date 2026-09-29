import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../teams/presentation/providers/team_provider.dart';

/// 🎭 Gösteriyi sahneye koyan Topluluk/Prodüksiyon için küçük, dokunulabilir
/// bir kredi satırı. `Show.teamId` üzerinden ilgili takımı çeker ve
/// dokunulduğunda takım detay sayfasına yönlendirir.
///
/// [onPaper] → bilet kağıdına basılı hâli (mürekkep renkleri, zemin yok);
/// değilse temanın yüzey renkleriyle küçük bir hap.
///
/// Bu, ikincil/kritik olmayan bir parça olduğundan; takım henüz
/// yükleniyorsa, bulunamadıysa veya `teamId` boşsa hiçbir şey render etmez
/// (rahatsız edici bir yükleniyor/hata göstergesi yerine [SizedBox.shrink]).
class ShowTeamCredit extends ConsumerWidget {
  final String teamId;
  final bool onPaper;

  const ShowTeamCredit({super.key, required this.teamId, this.onPaper = false});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (teamId.isEmpty) return const SizedBox.shrink();

    final teamDetailAsync = ref.watch(teamDetailProvider(teamId));
    final team = teamDetailAsync.value?.team;

    if (team == null || team.name.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final Color accent = onPaper ? TicketInk.accentOf(context) : colors.primary;

    final Widget avatar = team.imageUrl.isNotEmpty
        ? ClipOval(
            child: OptimizedCachedImage(
              imageUrl: team.imageUrl,
              width: 32,
              height: 32,
              isCircular: true,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: onPaper
                  ? TicketInk.inkSoft(0.08)
                  : colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_2_rounded, size: 17, color: accent),
          );

    final Widget text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODÜKSİYON',
          style: onPaper
              ? TicketInk.label()
              : context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
        ),
        const SizedBox(height: 2),
        Text(
          team.name,
          style: onPaper
              ? TicketInk.value()
              : context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Semantics(
      button: true,
      label: 'Prodüksiyon: ${team.name}. Topluluk sayfasını aç',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          focusColor: accent.withOpacity(0.14),
          hoverColor: (onPaper ? TicketInk.ink : colors.onSurface)
              .withOpacity(0.05),
          onTap: () => NavigationHandler.goToTeam(context, team.id, team.name),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: onPaper
                ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
                : const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: onPaper
                ? null
                : BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: colors.outlineVariant.withOpacity(0.5)),
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: AppSpacing.sm + 2),
                Flexible(child: text),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: onPaper
                        ? TicketInk.inkSoft(0.5)
                        : colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
