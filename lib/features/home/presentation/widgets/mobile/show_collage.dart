import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/base/base_loadable_state.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shows/domain/entities/show.dart';

class ShowCollage extends StatelessWidget {
  final LoadableState<dynamic, List<Show>> state;
  final Function(String showId) onShowTap;

  const ShowCollage({
    super.key,
    required this.state,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ShimmerLoading(height: 400, width: double.infinity),
      );
    }

    if (!state.hasData || state.dataList!.isEmpty) {
      return const SizedBox.shrink();
    }

    final shows = state.dataList!.take(12).toList();

    return Column(
      children: [
        _HeroShowSection(shows: shows, onShowTap: onShowTap),
        const SizedBox(height: 15),
        _HorizontalShowStrip(shows: shows, onShowTap: onShowTap),
        const SizedBox(height: 20),
        _MosaicShowGrid(shows: shows, onShowTap: onShowTap),
      ],
    );
  }
}

// Hero section with overlapping cards
class _HeroShowSection extends StatelessWidget {
  final List<Show> shows;
  final Function(String) onShowTap;

  const _HeroShowSection({
    required this.shows,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 320,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (shows.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                width: screenWidth * 0.6,
                bottom: screenWidth * 0.1,
                child: Transform.rotate(
                  angle: -0.02,
                  child: ShowCard(
                    show: shows[0],
                    onTap: () => onShowTap(shows[0].id),
                    tag: "ANA",
                  ),
                ),
              ),
            if (shows.length > 1)
              Positioned(
                top: 100,
                right: 0,
                width: screenWidth * 0.5,
                height: 180,
                child: Transform.rotate(
                  angle: 0.03,
                  child: ShowCard(
                    show: shows[1],
                    onTap: () => onShowTap(shows[1].id),
                    tag: "TREND",
                    isFeatured: true,
                  ),
                ),
              ),
            if (shows.length > 2)
              Positioned(
                bottom: 0,
                left: 0,
                width: screenWidth * 0.35,
                height: 120,
                child: Transform.rotate(
                  angle: -0.05,
                  child: ShowCard(
                    show: shows[2],
                    onTap: () => onShowTap(shows[2].id),
                    tag: "YENİ",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Horizontal scrolling strip
class _HorizontalShowStrip extends StatelessWidget {
  final List<Show> shows;
  final Function(String) onShowTap;

  const _HorizontalShowStrip({
    required this.shows,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (shows.length <= 3) return const SizedBox.shrink();

    final random = math.Random(42);
    final stripShows = shows.skip(3).take(4).toList();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stripShows.length,
        itemBuilder: (final context, final index) {
          return Padding(
            padding: EdgeInsets.only(
              right: 12,
              top: random.nextDouble() * 20,
            ),
            child: Transform.rotate(
              angle: random.nextDouble() * 0.1 - 0.05,
              child: SizedBox(
                width: 100,
                child: ShowCard(
                  show: stripShows[index],
                  onTap: () => onShowTap(stripShows[index].id),
                  tag: index == 0 ? "ÖZEL" : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Mosaic grid layout
class _MosaicShowGrid extends StatelessWidget {
  final List<Show> shows;
  final Function(String) onShowTap;

  const _MosaicShowGrid({
    required this.shows,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (shows.length <= 7) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 220,
                  child: Transform.rotate(
                    angle: 0.02,
                    child: ShowCard(
                      show: shows[7],
                      onTap: () => onShowTap(shows[7].id),
                      tag: "POPÜLER",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (shows.length > 8)
                      SizedBox(
                        height: 105,
                        child: Transform.rotate(
                          angle: -0.03,
                          child: ShowCard(
                            show: shows[8],
                            onTap: () => onShowTap(shows[8].id),
                            tag: "SÜRPRİZ",
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (shows.length > 9)
                      SizedBox(
                        height: 105,
                        child: ShowCard(
                          show: shows[9],
                          onTap: () => onShowTap(shows[9].id),
                          tag: "VİP",
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (shows.length > 10) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: Transform.rotate(
                angle: -0.01,
                child: ShowCard(
                  show: shows[10],
                  onTap: () => onShowTap(shows[10].id),
                  tag: "SON ŞANS",
                  isWide: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Reusable show card component
class ShowCard extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;
  final String? tag;
  final bool isFeatured;
  final bool isWide;

  const ShowCard({
    super.key,
    required this.show,
    required this.onTap,
    this.tag,
    this.isFeatured = false,
    this.isWide = false,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(show.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isFeatured ? 0.3 : 0.2),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(isWide ? 0.7 : 0.8),
                  ],
                  begin: isWide ? Alignment.centerRight : Alignment.topCenter,
                  end: isWide ? Alignment.centerLeft : Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (tag != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: _TagLabel(
                        label: tag!,
                        isFeatured: isFeatured,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    show.name,
                    maxLines: isWide ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: isWide ? 22 : 16,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isWide)
                    Opacity(
                      opacity: 0.7,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              "Yakında",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagLabel extends StatelessWidget {
  final String label;
  final bool isFeatured;

  const _TagLabel({
    required this.label,
    this.isFeatured = false,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFeatured
            ? Colors.white.withOpacity(0.9)
            : context.primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isFeatured ? context.primaryColor : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}