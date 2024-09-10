import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/custom_views/custom_category_card.dart';
import '../../../core/custom_views/custom_show_card.dart';
import '../../../core/custom_views/custom_stage_card.dart';
import '../../../core/custom_views/custom_title.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import 'search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _campaigns = [
    "Kampanya 1: %50 indirim!",
    "Kampanya 2: Üç al, bir bedava!",
    "Kampanya 3: Ücretsiz kargo fırsatı!",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _currentPage = (_currentPage + 1) % _campaigns.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    });
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCampaignSlider(),
            const SizedBox(height: 20),
            const BodySideScreen(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Etkinlikleri Ara...',
              ),
              onTap: _navigateToSearch,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSlider() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
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
          const SizedBox(height: 10),
          DotsIndicator(
            controller: _pageController,
            itemCount: _campaigns.length,
            onPageSelected: (page) {
              setState(() {
                _currentPage = page;
              });
              _pageController.animateToPage(
                page,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
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
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl:
                "https://pc-4you.ru/wp-content/uploads/2022/11/1870e2d0-d37f-4abe-82eb-dff15da4d6df-1068x801.webp",
            width: 200,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          Text(
            campaignText,
            style: const TextStyle(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
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
        return _buildDot(index);
      }),
    );
  }

  Widget _buildDot(int index) {
    return GestureDetector(
      onTap: () {
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
  }
}

class BodySideScreen extends StatelessWidget {
  const BodySideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomSectionTitle(title: 'Kategoriler'),
        const CategoryCardBuilder(),
        const CustomSectionTitle(title: 'Yeni Gösteriler'),
        _buildNewShows(),
        const CustomSectionTitle(title: 'Sahneler'),
        _buildStageSection(),
        const CustomSectionTitle(title: 'Oyunlardan Kareler'),
        _buildGamesPhotoSection(),
        const SizedBox(height: 20)
      ],
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
            return GestureDetector(
              child: CustomVerticalShowCard(
                imageUrl: 'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
                gameName: 'Gözlerimi Kaparım Vazifemi Yaparım',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShowDetailPage(showId: '0')
                    ),
                  );
                },
              ),
            );
          }),
    );
  }

  Widget _buildStageSection() {
    final List<String> venues = [
      'Halit Akçatepe Sahnesi',
      'Sahne 2',
      'Sahne 3',
      'Sahne 4',
      'Sahne 5',
      'Sahne 6',
      'Sahne 7',
      'Sahne 8',
      'Sahne 9',
      'Sahne 10',
      'Sahne 11',
      'Sahne 12',
      'Sahne 13',
      'Sahne 14',
      'Sahne 15'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              return CustomStageCard(
                text: venues[index],
                imageUrl:
                    'https://enstitu.ibb.istanbul/files/ismekOrg/Image/img_brans/brans_yenisitegaleri/drama/1-600.jpg',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StageDetailPage(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamesPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildGameCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://i.ytimg.com/vi/tzPpkRLf9a8/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGHIgWyg9MA8=&rs=AOn4CLCBnYXpB7USjvYDePL64AaVI7Epyw',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Oyun $index',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
