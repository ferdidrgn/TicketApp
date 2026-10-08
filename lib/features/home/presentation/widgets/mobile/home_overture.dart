import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/craft.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../providers/home_sessions_provider.dart';
import '../common/home_ui.dart';

/// Modern Material: yumuşak yuvarlak afiş + üzerine binen yüzey.
/// Karanlık tam perde yok — tema yüzeyi, yay geçiş, gerçek afiş.
class HomeOverture extends StatelessWidget {
  final Show show;
  final HomeSession? session;
  final Animation<double> reveal;
  final VoidCallback onOpen;
  final VoidCallback onSearch;
  final Widget topBar;

  const HomeOverture({
    super.key,
    required this.show,
    required this.session,
    required this.reveal,
    required this.onOpen,
    required this.onSearch,
    required this.topBar,
  });

  void _open() {
    HapticFeedback.mediumImpact();
    TiyatrolHeroFlight.prepare(
      TiyatrolHeroTags.show(show.id, 'home-overture'),
      imageUrl: show.imageUrl,
      title: show.name,
    );
    onOpen();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double posterH =
        (MediaQuery.sizeOf(context).height * 0.52).clamp(280.0, 460.0);
    final String heroTag = TiyatrolHeroTags.show(show.id, 'home-overture');
    final DateTime? when = session?.date;
    final String whenLabel = when == null
        ? ''
        : '${when.day} ${_month(when)}  ·  ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final String place = session?.stage?.name.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        topBar,
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: PressScale(
            label: show.name,
            onTap: _open,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.level3(cs.shadow),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: SizedBox(
                  height: posterH,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TiyatrolHero(
                        tag: heroTag,
                        child: OptimizedCachedImage(
                          imageUrl: show.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: 0,
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x66000000),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: FadeTransition(
            opacity: reveal,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: reveal,
                curve: AppMotion.spring,
              )),
              child: Material(
                color: cs.surface,
                elevation: 0,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.md + safe.bottom * 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeText(context, 'Bu akşam', 'Tonight'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AuthWipeReveal(
                        reveal: reveal,
                        child: Text(
                          show.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: cs.onSurface,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (whenLabel.isNotEmpty || place.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          [whenLabel, if (place.isNotEmpty) place]
                              .join('  ·  '),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      HomeSearchField(
                        onTap: onSearch,
                        hint: AppLocalizations.of(context)!
                            .homeHeroSearchPlaceholder,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TicketStampButton(
                        label: homeText(context, 'Bilet al', 'Get tickets'),
                        onTap: _open,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _month(final DateTime d) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return months[d.month - 1];
  }
}

class HomeOvertureSkeleton extends StatelessWidget {
  const HomeOvertureSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double posterH =
        (MediaQuery.sizeOf(context).height * 0.52).clamp(280.0, 460.0);
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final Widget poster = Container(
      height: posterH,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.huge, AppSpacing.xl, 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
    if (reduce) return poster;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: poster,
    );
  }
}
