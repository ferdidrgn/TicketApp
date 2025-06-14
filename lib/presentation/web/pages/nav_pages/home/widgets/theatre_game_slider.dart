import 'package:flutter/material.dart';
import '../../../../../../domain/entities/show.dart';

class TheaterGamesSlider extends StatefulWidget {
  final List<Show> shows;

  const TheaterGamesSlider({super.key, required this.shows});

  @override
  State<TheaterGamesSlider> createState() => _TheaterGamesSliderState();
}

class _TheaterGamesSliderState extends State<TheaterGamesSlider> {
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
  Widget build(final BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 320,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            itemCount: widget.shows.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 20),
            itemBuilder: (final _, final index) {
              final show = widget.shows[index];
              return tasarimWeb(
                show.imageUrl ?? '',
                show.name ?? '',
                show.description ?? '',
              );
            },
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


  Widget tasarimWeb(final String imageUrl,final String gameName, final String desc){
    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
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
        ),
      ),
    );
  }
}
