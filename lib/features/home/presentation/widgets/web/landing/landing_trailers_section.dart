import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../../shows/domain/entities/show.dart';
import 'landing_palette.dart';

/// 🎬 "Fragmanlar" bölümü — küratörün Firestore'da `Show.trailerYoutubeId`
/// alanına elle eklediği YouTube video ID'lerini oynatır. Hiçbir gösterinin
/// fragmanı yoksa, bölümü tamamen gizlemek yerine küratörü yönlendiren bir
/// "yakında" kartı gösterilir (Sponsors bölümündeki ilkeyle aynı: ziyaretçi
/// bu bölümün var olduğunu her zaman görsün).
class LandingTrailersSection extends StatefulWidget {
  final List<Show> shows;
  const LandingTrailersSection({super.key, required this.shows});

  @override
  State<LandingTrailersSection> createState() => _LandingTrailersSectionState();
}

class _LandingTrailersSectionState extends State<LandingTrailersSection> {
  late final List<Show> _trailerShows;
  YoutubePlayerController? _controller;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _trailerShows = widget.shows
        .where((final s) =>
            s.trailerYoutubeId != null && s.trailerYoutubeId!.trim().isNotEmpty)
        .toList();
    if (_trailerShows.isNotEmpty) {
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      )..cueVideoById(videoId: _trailerShows.first.trailerYoutubeId!);
    }
  }

  void _select(final int index) {
    setState(() => _activeIndex = index);
    _controller?.loadVideoById(videoId: _trailerShows[index].trailerYoutubeId!);
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (_trailerShows.isEmpty) {
      return const LandingComingSoonCard(
        icon: Icons.movie_creation_outlined,
        message: 'Fragmanlar yakında burada — küratör her gösteri için bir '
            'YouTube video bağlantısı ekledikçe bu bölüm otomatik dolacak.',
      );
    }

    final width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 900;

    final player = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _controller!),
      ),
    );

    final rail = SizedBox(
      height: isLarge ? null : 110,
      width: isLarge ? 260 : null,
      child: isLarge
          ? Column(
              children: [
                for (var i = 0; i < _trailerShows.length; i++) ...[
                  _TrailerThumb(
                    show: _trailerShows[i],
                    active: i == _activeIndex,
                    onTap: () => _select(i),
                  ),
                  if (i != _trailerShows.length - 1) const SizedBox(height: 14),
                ],
              ],
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trailerShows.length,
              separatorBuilder: (final _, final __) => const SizedBox(width: 12),
              itemBuilder: (final context, final i) => SizedBox(
                width: 160,
                child: _TrailerThumb(
                  show: _trailerShows[i],
                  active: i == _activeIndex,
                  onTap: () => _select(i),
                ),
              ),
            ),
    );

    return isLarge
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: player),
              const SizedBox(width: 20),
              rail,
            ],
          )
        : Column(
            children: [
              player,
              const SizedBox(height: 16),
              rail,
            ],
          );
  }
}

class _TrailerThumb extends StatelessWidget {
  final Show show;
  final bool active;
  final VoidCallback onTap;
  const _TrailerThumb(
      {required this.show, required this.active, required this.onTap});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? LandingPalette.crimson : LandingPalette.microBorder,
              width: active ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.black.withOpacity(0.15)
                        : Colors.black.withOpacity(0.45),
                  ),
                ),
                if (!active)
                  const Center(
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 26),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Text(show.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}
