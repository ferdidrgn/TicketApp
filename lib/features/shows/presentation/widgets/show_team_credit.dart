import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../teams/presentation/providers/team_provider.dart';

/// 🎭 Gösteriyi sahneye koyan Topluluk/Prodüksiyon için küçük, dokunulabilir
/// bir kredi satırı. `Show.teamId` üzerinden ilgili takımı çeker ve
/// dokunulduğunda takım detay sayfasına yönlendirir.
///
/// Bu, ikincil/kritik olmayan bir süsleme parçası olduğundan; takım henüz
/// yükleniyorsa, bulunamadıysa veya `teamId` boşsa hiçbir şey render etmez
/// (rahatsız edici bir yükleniyor/hata göstergesi yerine [SizedBox.shrink]).
class ShowTeamCredit extends ConsumerWidget {
  final String teamId;

  const ShowTeamCredit({super.key, required this.teamId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (teamId.isEmpty) return const SizedBox.shrink();

    final teamDetailAsync = ref.watch(teamDetailProvider(teamId));
    final team = teamDetailAsync.value?.team;

    if (team == null || team.name.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => NavigationHandler.goToTeam(context, team.id, team.name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (team.imageUrl.isNotEmpty)
                ClipOval(
                  child: OptimizedCachedImage(
                    imageUrl: team.imageUrl,
                    width: 28,
                    height: 28,
                    isCircular: true,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_2_rounded,
                      size: 16, color: colors.primary),
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRODÜKSİYON',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      team.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
