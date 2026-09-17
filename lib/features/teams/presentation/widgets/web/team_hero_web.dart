import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../domain/entities/team.dart';

/// 🎬 CİNEMATİC EKİP HERO (MASAÜSTÜ)
///
/// `landing/index.html`'in "Kadro" bölümündeki koyu çam yeşili sahne
/// hissini; tam genişlikte, alçak kontrastlı bir görsel + geniş, kendinden
/// emin bir başlık ile masaüstünde yeniden kuruyor. Mobildeki
/// `SliverAppBar` başlığının aksine, burada editoryal bir "perde açılışı"
/// var: eyebrow etiketi, büyük başlık, ince bir alt çizgi ve topluluğun
/// büyüklüğünü özetleyen istatistik rozetleri.
class TeamHeroWeb extends StatelessWidget {
  final Team team;
  final List<Show> shows;

  const TeamHeroWeb({super.key, required this.team, required this.shows});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 620,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(
              imageUrl: team.imageUrl,
              fit: BoxFit.cover,
              borderRadius: 0,
              errorBuilder: (final _, final __, final ___) =>
                  const ShimmerLoading(),
            ),
            // Çam yeşili sahne perdesi — üstten ve alttan koyulaşan degrade
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    WebColors.veryDarkBlue.withOpacity(0.55),
                    WebColors.veryDarkBlue.withOpacity(0.15),
                    WebColors.veryDarkBlue.withOpacity(0.85),
                    WebColors.veryDarkBlue,
                  ],
                  stops: const [0.0, 0.35, 0.78, 1.0],
                ),
              ),
            ),
            // Sahne spotu — üstten merkeze düşen yumuşak bir ışık huzmesi
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.1,
                  colors: [
                    WebColors.primaryGoldLight.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Eyebrow(),
                      const SizedBox(height: 22),
                      Text(
                        team.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 68,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          color: WebColors.whiteText,
                          letterSpacing: -1.5,
                          shadows: [
                            BoxShadow(
                              color: WebColors.veryDarkBlue.withOpacity(0.6),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        height: 3,
                        width: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            WebColors.primaryGold,
                            Colors.transparent,
                          ]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatBadge(
                            icon: Icons.auto_awesome_motion_rounded,
                            label: shows.isEmpty
                                ? 'Repertuar hazırlanıyor'
                                : '${shows.length} Sahnedeki Eser',
                          ),
                          if (team.photosId.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            _StatBadge(
                              icon: Icons.collections_rounded,
                              label: '${team.photosId.length} Kare',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: WebColors.primaryGold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.4)),
        ),
        child: Text(
          'PERDENİN ARKASI · SANAT TOPLULUĞU',
          style: TextStyle(
            color: WebColors.primaryGoldLight,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      );
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: WebColors.secondaryAccent.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: WebColors.secondaryAccentLight),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: WebColors.lightWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
}
