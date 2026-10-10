import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/motion/stage_entrance.dart';
import '../../../../../shared/widgets/rive/tiyatrol_rive.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';

/// Smart_home şablonlarının TiyatRol uyarlaması:
/// - nabız özet kartı (electricity card şekli)
/// - 2×2 toggle/aksiyon ızgarası (device card şekli)
/// - liquid Rive aksiyon butonu
///
/// Renkler yalnızca [ColorScheme] / temadan — sabit palet yok.
/// Takvim / seans programına dokunmaz.
class HomeInteractiveDeck extends StatelessWidget {
  final int tonight;
  final int week;
  final VoidCallback onScrollToProgramme;
  final double gutter;

  const HomeInteractiveDeck({
    super.key,
    required this.tonight,
    required this.week,
    required this.onScrollToProgramme,
    required this.gutter,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StageEntrance.bounce(
            delay: 1,
            child: _PulseCard(
              tonight: tonight,
              week: week,
              onTap: () {
                HapticFeedback.mediumImpact();
                onScrollToProgramme();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StageEntrance.bounce(
            delay: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sahne paneli',
                    style: Sk.display(context, size: 20, height: 1.1),
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationHandler.goToDiscover(context),
                  child: Text(
                    'Tümü',
                    style: Sk.ui(context,
                        size: 13,
                        color: cs.primary,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(builder: (final context, final box) {
            final bool wide = box.maxWidth >= 640;
            final List<_DeckTileData> tiles = [
              _DeckTileData(
                title: 'Keşfet',
                subtitle: 'Türlere göz at',
                icon: Icons.explore_rounded,
                onTap: () => NavigationHandler.goToDiscover(context),
              ),
              _DeckTileData(
                title: 'Yakınımda',
                subtitle: 'Haritada seanslar',
                icon: Icons.near_me_rounded,
                onTap: () => NavigationHandler.goToNearby(context),
              ),
              _DeckTileData(
                title: 'Favoriler',
                subtitle: 'Kayıtlı oyunlar',
                icon: Icons.favorite_rounded,
                onTap: () => NavigationHandler.goToFavorites(context),
              ),
              _DeckTileData(
                title: 'Enstrüman',
                subtitle: 'Oyna & dinle',
                icon: Icons.piano_rounded,
                onTap: () => NavigationHandler.goToInstrumentStage(context),
                liquid: true,
              ),
            ];
            if (wide) {
              return Row(
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StageEntrance.scaleFade(
                        delay: 2.0 + i * 0.4,
                        child: _DeckTile(data: tiles[i]),
                      ),
                    ),
                  ],
                ],
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (final context, final i) => StageEntrance.scaleFade(
                delay: 2.0 + i * 0.45,
                child: _DeckTile(data: tiles[i]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final int tonight;
  final int week;
  final VoidCallback onTap;

  const _PulseCard({
    required this.tonight,
    required this.week,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String headline = tonight > 0
        ? '$tonight seans bu akşam'
        : (week > 0 ? '$week seans bu hafta' : 'Program yükleniyor');
    final String sub = tonight > 0
        ? 'Takvime inip seansını seç'
        : 'Yaklaşan perdelere göz at';

    return PressScale(
      onTap: onTap,
      semanticLabel: headline,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary, cs.tertiary],
                ),
              ),
              child: Icon(Icons.theater_comedy_rounded,
                  color: cs.onPrimary, size: 26),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context, size: 18, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 12,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool liquid;

  const _DeckTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.liquid = false,
  });
}

/// Smart_home CustomCard şekli: yuvarlak ikon + başlık + "switch" hissi.
class _DeckTile extends StatefulWidget {
  final _DeckTileData data;
  const _DeckTile({required this.data});

  @override
  State<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<_DeckTile> {
  bool _on = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _DeckTileData d = widget.data;

    return PressScale(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _on = !_on);
        d.onTap();
      },
      semanticLabel: d.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
        decoration: BoxDecoration(
          color: _on ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _on
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (d.liquid)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: LiquidRiveButton(
                      label: d.title,
                      icon: d.icon,
                      size: 48,
                      onTap: () {
                        setState(() => _on = true);
                        d.onTap();
                      },
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _on ? cs.surface : cs.surface,
                    ),
                    child: Icon(
                      d.icon,
                      color: _on ? cs.primary : cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                const Spacer(),
                Icon(
                  _on
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_outlined,
                  size: 34,
                  color: _on ? cs.primary : cs.outline,
                ),
              ],
            ),
            const Spacer(),
            Text(
              d.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context,
                  size: 11,
                  color: _on
                      ? cs.onPrimaryContainer.withValues(alpha: 0.75)
                      : cs.onSurfaceVariant,
                  weight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              d.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Sk.display(context,
                  size: 17,
                  height: 1.1,
                  color: _on ? cs.onPrimaryContainer : null),
            ),
          ],
        ),
      ),
    );
  }
}
