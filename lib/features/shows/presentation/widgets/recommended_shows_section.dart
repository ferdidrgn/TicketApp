import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/theatre_show_card.dart';
import '../providers/recommended_shows_provider.dart';

/// "Sana Özel" — kullanıcının GERÇEK favori/satın alma geçmişinden
/// türetilmiş öneriler (bkz. `recommended_shows_provider.dart`). Gerçek bir
/// sinyal yoksa (yeni kullanıcı, hiç favori/bilet yok) SESSİZCE gizlenir —
/// uydurma bir "senin için seçtik" listesi asla gösterilmez.
class RecommendedShowsSection extends ConsumerWidget {
  const RecommendedShowsSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedShowsProvider);

    return recommendedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (final _, final __) => const SizedBox.shrink(),
      data: (final shows) {
        if (shows.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 18, color: WebColors.primaryGold),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'SANA ÖZEL',
                      style: TextStyle(
                        color: WebColors.whiteText,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  itemCount: shows.length,
                  separatorBuilder: (final _, final __) =>
                      const SizedBox(width: AppSpacing.lg),
                  itemBuilder: (final context, final index) {
                    final show = shows[index];
                    return SizedBox(
                      width: 160,
                      child: TheatreShowCard(
                        show: show,
                        onTap: () =>
                            NavigationHandler.goToShow(context, show.id, show.name),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
