import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'scroll_reveal.dart';

/// 🔴 "ŞU AN SAHNEDE" ÇAĞRI BANDI
///
/// Oyuncunun aktif olarak sahnelenen bir gösterisi varsa hero'nun hemen
/// altında beliren, nabız gibi atan canlı bir gösterge ile öne çıkan bant.
/// Veri yoksa (aktif gösteri yok) hiçbir şey render etmez — uydurma içerik
/// eklenmez.
class PlayerOnStageBanner extends StatelessWidget {
  final List<Show> activeShows;

  const PlayerOnStageBanner({super.key, required this.activeShows});

  @override
  Widget build(final BuildContext context) {
    if (activeShows.isEmpty) return const SizedBox.shrink();

    return ScrollReveal(
      delay: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WebColors.primaryGoldDark.withOpacity(0.22),
              WebColors.darkBlueSurface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _PulsingDot(),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ŞU AN SAHNEDE',
                    style: TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: activeShows
                        .map((final s) => _ActiveShowLink(show: s))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveShowLink extends StatefulWidget {
  final Show show;

  const _ActiveShowLink({required this.show});

  @override
  State<_ActiveShowLink> createState() => _ActiveShowLinkState();
}

class _ActiveShowLinkState extends State<_ActiveShowLink> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => NavigationHandler.goToShow(
            context, widget.show.id, widget.show.name),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? WebColors.primaryGold
                : WebColors.veryDarkBlue.withOpacity(0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: _hovered
                  ? WebColors.primaryGold
                  : WebColors.primaryGold.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.show.name,
                style: TextStyle(
                  color: _hovered ? WebColors.veryDarkBlue : WebColors.whiteText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 15,
                  color:
                      _hovered ? WebColors.veryDarkBlue : WebColors.primaryGoldLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final _) {
          final double t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22 * (0.5 + t * 0.5),
                height: 22 * (0.5 + t * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WebColors.primaryGold.withOpacity(0.35 * (1 - t)),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: WebColors.primaryGold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
