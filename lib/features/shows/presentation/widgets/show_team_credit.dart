import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../teams/presentation/providers/team_provider.dart';

/// Gösteriyi sahneye koyan Topluluk/Prodüksiyon için küçük, dokunulabilir
/// bir kredi satırı. `Show.teamId` üzerinden ilgili takımı çeker ve
/// dokunulduğunda takım detay sayfasına yönlendirir.
///
/// [onPaper] → bilet kağıdına basılı hâli (mürekkep renkleri, zemin yok);
/// değilse temanın yüzey renkleriyle yumuşak bir hap.
///
/// Yükleniyor / bulunamadı / boş `teamId` → [SizedBox.shrink] (ikincil parça).
class ShowTeamCredit extends ConsumerWidget {
  final String teamId;
  final bool onPaper;

  const ShowTeamCredit({super.key, required this.teamId, this.onPaper = false});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (teamId.isEmpty) {
      return const SizedBox.shrink();
    }

    final team = ref.watch(teamDetailProvider(teamId)).value?.team;
    if (team == null || team.name.isEmpty) {
      return const SizedBox.shrink();
    }

    final ColorScheme cs = Theme.of(context).colorScheme;

    final Widget avatar = ClipOval(
      child: SkImage(
        url: team.imageUrl,
        width: 32,
        height: 32,
        radius: 16,
        fallbackIcon: Icons.groups_2_rounded,
      ),
    );

    final Widget text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODÜKSİYON',
          style: onPaper
              ? TicketInk.label()
              : Sk.ui(
                  context,
                  size: 11,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
        ),
        const SizedBox(height: 2),
        Text(
          team.name,
          style: onPaper
              ? TicketInk.value()
              : Sk.ui(context, size: 14, weight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm + 2),
        Flexible(child: text),
        const SizedBox(width: AppSpacing.xs),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: onPaper
              ? TicketInk.inkSoft(0.5)
              : cs.onSurfaceVariant,
        ),
      ],
    );

    return PressScale(
      semanticLabel: 'Prodüksiyon: ${team.name}. Topluluk sayfasını aç',
      onTap: () {
        HapticFeedback.selectionClick();
        NavigationHandler.goToTeam(
          context,
          team.id,
          team.name,
          heroTag: TiyatrolHeroTags.team(team.id, 'show'),
          imageUrl: team.imageUrl,
          title: team.name,
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: onPaper
            ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: onPaper
            ? null
            : BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
        child: row,
      ),
    );
  }
}
