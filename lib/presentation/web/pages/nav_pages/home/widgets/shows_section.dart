import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import '../../../../../../data/providers/show/show_provider.dart';
import '../../../../../../domain/entities/show.dart';

class ShowsSection extends ConsumerStatefulWidget {
  const ShowsSection({super.key});

  @override
  ConsumerState<ShowsSection> createState() => _WebTheaterGamesSectionState();
}

class _WebTheaterGamesSectionState extends ConsumerState<ShowsSection> {
  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      final state = ref.read(showProvider);
      if (!state.isLoading && state.dataList == null) {
        ref.read(showProvider.notifier).loadShows(false);
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);

    if (showState.isLoading) {
      return SizedBox(
        height: 320,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (final index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const SizedBox(
                width: 240,
                child: ShimmerLoading(),
              ),
            ),
          ),
        ),
      );
    } else if (showState.hasError) {
      return Center(
        child: Text(
          showState.errorMessage ?? 'Bir hata oluştu',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    } else if (showState.isListNullOrEmpty)
      return const Center(
        child: Text('Gösteri verisi bulunamadı.'),
      );

    final shows = showState.dataList!.cast<Show>();

    return Stack(
      children: [
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...shows.map((final show) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _ShowCard(
                        imageUrl: show.imageUrl ?? '',
                        gameName: show.name ?? '',
                      ),
                    )),
              ],
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 120,
          child: IconButton(
            onPressed: _scrollLeft,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
        Positioned(
          right: 10,
          top: 120,
          child: IconButton(
            onPressed: _scrollRight,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ShowCard extends StatelessWidget {
  final String imageUrl;
  final String gameName;

  const _ShowCard({
    required this.imageUrl,
    required this.gameName,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Text(
          gameName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
