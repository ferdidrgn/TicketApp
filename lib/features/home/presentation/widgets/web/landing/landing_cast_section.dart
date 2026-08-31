import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../players/domain/entities/player.dart';
import '../../../../../players/presentation/providers/player_provider.dart';

/// 🎭 "Sahnenin Yüzleri" — gerçek oyuncu kadrosunu (Firestore'daki Player
/// koleksiyonu) tanıtan bölüm. Veri yoksa/hata varsa bölüm sessizce
/// gizlenir; uydurma isim/görsel gösterilmez.
class LandingCastSection extends ConsumerWidget {
  const LandingCastSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider(isLimit: true));
    final players = playersAsync.value ?? const <Player>[];
    if (players.isEmpty) return const SizedBox.shrink();

    final preview = players.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebColors.primaryGold.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_2_rounded,
                  color: WebColors.primaryGoldLight, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Sahnenin Yüzleri',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Her performansın arkasındaki emeği tanı.',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5)),
        const SizedBox(height: 24),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 18),
            itemBuilder: (final context, final i) =>
                _CastTile(player: preview[i]),
          ),
        ),
      ],
    );
  }
}

class _CastTile extends StatefulWidget {
  final Player player;
  const _CastTile({required this.player});

  @override
  State<_CastTile> createState() => _CastTileState();
}

class _CastTileState extends State<_CastTile> {
  bool _hovering = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onEnter: (final _) => setState(() => _hovering = true),
        onExit: (final _) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () => NavigationHandler.goToApp(context),
          child: AnimatedScale(
            scale: _hovering ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 108,
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _hovering
                          ? const LinearGradient(colors: [
                              WebColors.primaryGoldLight,
                              WebColors.primaryGold,
                            ])
                          : null,
                      border: _hovering
                          ? null
                          : Border.all(color: WebColors.microBorder),
                    ),
                    child: ClipOval(
                      child: widget.player.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.player.imageUrl,
                              fit: BoxFit.cover)
                          : Container(
                              color: WebColors.darkBlueAccent,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white38, size: 30),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.player.firstName} ${widget.player.lastName}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
