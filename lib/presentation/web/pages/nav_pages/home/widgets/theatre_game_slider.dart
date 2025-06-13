import 'package:flutter/material.dart';

class TheaterGamesSlider extends StatefulWidget {
  const TheaterGamesSlider({super.key});

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
            itemBuilder: (final _, final index) => _buildGameCard(index),
            separatorBuilder: (final _, final __) => const SizedBox(width: 20),
            itemCount: 5,
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

  Widget _buildGameCard(final int index) {
    final titles = [
      'Romeo ve Juliet',
      'Bir Yaz Gecesi Rüyası',
      'Martı',
      'Kral Lear',
      'Ay Işığında Şamata',
    ];
    final images = [
      'assets/images/play1.jpg',
      'assets/images/play2.jpg',
      'assets/images/play3.jpg',
      'assets/images/play4.jpg',
      'assets/images/play5.jpg',
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(images[index]),
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
          titles[index],
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
