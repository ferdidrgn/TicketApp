import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shows/domain/entities/show.dart';
import 'landing_palette.dart';

/// 🎭 "Perde Arkası" — merak uyandıran, 3D çevirmeli sürpriz kartlar.
/// Ön yüz gösteriyi bilerek gizler (bulanık afiş + "?"), arkası GERÇEK
/// gösteri bilgisiyle (özet, kategori, süre, yaş sınırı) ve bir fragman
/// oynatma düğmesiyle açılır.
///
/// ⚠️ Önceki sürümde arka yüz HEM dış Transform'da (angle - pi) ile hem de
/// içeride ayrıca rotateY(pi) ile iki kez çevriliyordu — bu da metnin ayna
/// görüntüsü gibi ters/okunaksız görünmesine sebep oluyordu. Doğru teknik:
/// SADECE dış açı (angle - pi) ile telafi edilir, iç içerik hiç
/// döndürülmeden normal şekilde çizilir.
class LandingMysterySection extends StatelessWidget {
  final List<Show> shows;
  const LandingMysterySection({super.key, required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) return const SizedBox.shrink();
    final preview = shows.take(6).toList();

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: preview.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 20),
        itemBuilder: (final context, final i) =>
            _MysteryFlipCard(show: preview[i]),
      ),
    );
  }
}

class _MysteryFlipCard extends StatefulWidget {
  final Show show;
  const _MysteryFlipCard({required this.show});

  @override
  State<_MysteryFlipCard> createState() => _MysteryFlipCardState();
}

class _MysteryFlipCardState extends State<_MysteryFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _revealed = false;

  void _toggle() {
    setState(() => _revealed = !_revealed);
    if (_revealed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _openTrailer() {
    final id = widget.show.trailerYoutubeId;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (final context) => _TrailerPopup(
        show: widget.show,
        youtubeId: id != null && id.trim().isNotEmpty ? id.trim() : null,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) {
            final angle = _controller.value * math.pi;
            final showBack = angle > math.pi / 2;
            final displayAngle = showBack ? angle - math.pi : angle;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(displayAngle),
              child: SizedBox(
                width: 190,
                height: 260,
                child: showBack ? _buildBack() : _buildFront(),
              ),
            );
          },
        ),
      );

  Widget _buildFront() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: widget.show.imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: LandingPalette.emberGlow),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: LandingPalette.crimsonLight),
                    ),
                    child: const Text('?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Perdeyi Arala',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBack() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [LandingPalette.surfaceAlt, LandingPalette.surface],
          ),
          border: Border.all(color: LandingPalette.crimson.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.show.category.toUpperCase(),
                style: const TextStyle(
                    color: LandingPalette.crimsonLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(widget.show.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2)),
            if (widget.show.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.show.description.trim(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 11.5,
                      height: 1.4),
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (widget.show.duration.isNotEmpty)
                  _miniChip(Icons.timer_outlined, widget.show.duration),
                if (widget.show.ageLimit.isNotEmpty)
                  _miniChip(Icons.shield_outlined, widget.show.ageLimit),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openTrailer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LandingPalette.crimsonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('İzle',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => NavigationHandler.goToApp(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: LandingPalette.microBorderStrong),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _miniChip(final IconData icon, final String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white54),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10.5)),
          ],
        ),
      );
}

/// Fragman oynatma penceresi. Gösterinin gerçek `trailerYoutubeId`'si yoksa
/// uydurma bir video AÇMAK yerine (bu projede baştan beri sadece gerçek
/// veri gösterilir) zarif bir "yakında" durumu gösterilir.
class _TrailerPopup extends StatefulWidget {
  final Show show;
  final String? youtubeId;
  const _TrailerPopup({required this.show, required this.youtubeId});

  @override
  State<_TrailerPopup> createState() => _TrailerPopupState();
}

class _TrailerPopupState extends State<_TrailerPopup> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = widget.youtubeId;
    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Dialog(
        backgroundColor: LandingPalette.surface,
        insetPadding: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.show.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _controller != null
                        ? YoutubePlayer(controller: _controller!)
                        : Container(
                            color: LandingPalette.bgAlt,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.movie_creation_outlined,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 36),
                                const SizedBox(height: 10),
                                Text('Bu gösterinin fragmanı yakında eklenecek.',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12.5)),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
