import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Geçici kampanya verileri
  final List<String> _campaigns = [
    "Kampanya 1: %50 indirim!",
    "Kampanya 2: Üç al, bir bedava!",
    "Kampanya 3: Ücretsiz kargo fırsatı!",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 15)).then((_) {
      _currentPage = (_currentPage < _campaigns.length - 1) ? _currentPage + 1 : 0;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(seconds: 15),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _campaigns.length,
                      itemBuilder: (context, index) {
                        return CampaignPage(campaignText: _campaigns[index]);
                      },
                    ),
                  ),
                  DotsIndicator(
                    controller: _pageController,
                    itemCount: _campaigns.length,
                    onPageSelected: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  ),
                ],
              ),
            ),
            const DiscoverPage(), // Add the DiscoverPage here
          ],
        ),
      ),
    );
  }
}

class CampaignPage extends StatelessWidget {
  final String campaignText;

  const CampaignPage({super.key, required this.campaignText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Stack(
        children: [
          Center(
            child: Image.network(
              "https://pc-4you.ru/wp-content/uploads/2022/11/1870e2d0-d37f-4abe-82eb-dff15da4d6df-1068x801.webp",
              width: 200,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Text(
              campaignText,
              style: const TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageSelected;

  const DotsIndicator({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return GestureDetector(
          onTap: () {
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            onPageSelected(index);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.page?.round() == index ? Colors.red : Colors.grey,
            ),
          ),
        );
      }),
    );
  }
}

// DiscoverPage widget starts here
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Kategoriler',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildCategoryCards(context),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Yeni Gösteriler',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildNewShows(),
        const SizedBox(height: 20)
      ],
    );
  }

  Widget _buildCategoryCards(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildCategoryCard(context, 'Tümünü Keşfet', Icons.explore),
          _buildCategoryCard(context, 'Trendler', Icons.trending_up),
          _buildCategoryCard(context, 'Tiyatro', Icons.theater_comedy),
          _buildCategoryCard(context, 'Konser/Müzik', Icons.library_music),
          _buildCategoryCard(context, 'Stand Up', Icons.event_seat_rounded),
          _buildCategoryCard(context, 'Festival', Icons.festival_rounded),
          _buildCategoryCard(context, 'Sinema', Icons.movie_filter_rounded),
          _buildCategoryCard(context, 'Çocuk', Icons.family_restroom),
          _buildCategoryCard(context, 'Spor', Icons.sports_baseball),
          _buildCategoryCard(context, 'Etkinlik', Icons.event),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        )
      ),
    );
  }

  Widget _buildNewShows() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildShowCard(index);
        },
      ),
    );
  }

  Widget _buildShowCard(int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://via.placeholder.com/150',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'Show $index', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
