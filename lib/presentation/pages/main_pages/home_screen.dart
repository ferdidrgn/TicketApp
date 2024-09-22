import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ticketapp/data/model/campaing.dart';
import 'package:ticketapp/data/repository/campaign_service.dart';
import '../../../core/custom_views/custom_category_card.dart';
import '../../../core/custom_views/custom_search.dart';
import '../../../core/custom_views/custom_show_card.dart';
import '../../../core/custom_views/custom_stage_card.dart';
import '../../../core/custom_views/custom_title.dart';
import '../../../data/model/show.dart';
import '../../../data/model/stage.dart';
import '../../../data/repository/show_service.dart';
import '../../../data/repository/stage_service.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import 'search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final ShowService _showService = ShowService();
  final StageService _stageService = StageService();
  final CampaignService _campaignService = CampaignService();

  List<Show?> _shows = [];
  List<Stage?> _stages = [];
  List<Campaign?> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startAutoScroll();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
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

  Future<void> _fetchData() async {
    try {
      final fetchedShows = await _showService.getShows(true);
      final fetchedStages = await _stageService.getStages(true);
      final fetchedCampaigns = await _campaignService.getCampaigns();

      setState(() {
        _shows = fetchedShows;
        _stages = fetchedStages;
        _campaigns = fetchedCampaigns;
      });
    } catch (e) {
      throw Exception('Veriler getirilemedi: $e');
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _navigateToDetailPage(String url) {
    if (url.contains('player')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PlayerDetailPage(playerId: _extractIdFromUrl(url))),
      );
    } else if (url.contains('stage')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                StageDetailPage(stageId: _extractIdFromUrl(url))),
      );
    } else if (url.contains('show')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ShowDetailPage(showId: _extractIdFromUrl(url))),
      );
    } else {
      throw Exception('Unknown URL: $url');
    }
  }

  String _extractIdFromUrl(String url) {
    // Extract the ID from the URL
    // This is a placeholder implementation, adjust according to your URL structure
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildCampaignSlider(),
              CustomSearchBar(onSearchTap: _navigateToSearch),
              const SizedBox(height: 20),
              const CustomSectionTitle(title: 'Kategoriler'),
              const CategoryCardBuilder(),
              const CustomSectionTitle(title: 'Yeni Gösteriler'),
              _buildNewShows(),
              const CustomSectionTitle(title: 'Sahneler'),
              _buildStageSection(),
              const CustomSectionTitle(title: 'Oyunlardan Kareler'),
              _buildGamesPhotoSection(),
              const SizedBox(height: 50)
            ])));
  }

  Widget _buildCampaignSlider() {
    return Container(
        padding: const EdgeInsets.all(20.0),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                return _buildCampaignPage(_campaigns[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildDotsIndicator()
        ]));
  }

  Widget _buildCampaignPage(Campaign? campaign) {
    if (campaign == null) return const SizedBox();

    return GestureDetector(
        onTap: () {
          _navigateToDetailPage(campaign.url);
        },
        child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(alignment: Alignment.bottomCenter, children: [
              CachedNetworkImage(
                imageUrl: campaign.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(8),
                  child: Text(campaign.title,
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center))
            ])));
  }

  Widget _buildDotsIndicator() {
    return DotsIndicator(
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
        });
  }

  Widget _buildNewShows() {
    return SizedBox(
        height: 200,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _shows.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                  child: CustomVerticalShowCard(
                      imageUrl: _shows[index]?.imageUrl ?? '',
                      gameName: _shows[index]?.name ?? '',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ShowDetailPage(
                                  showId: _shows[index]?.id ?? '')),
                        );
                      }));
            }));
  }

  Widget _buildStageSection() {
    return SizedBox(
        height: 200,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stages.length,
            itemBuilder: (context, index) {
              return CustomStageCard(
                  text: _stages[index]?.name ?? '',
                  imageUrl: _stages[index]?.imageUrl ?? '',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StageDetailPage(
                                stageId: _stages[index]?.id ?? '')));
                  });
            }));
  }

  Widget _buildGamesPhotoSection() {
    return SizedBox(
        height: 210,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildGamePhotoCard(index);
            }));
  }

  Widget _buildGamePhotoCard(int index) {
    return Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
            elevation: 8,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                  padding: const EdgeInsets.all(8),
                  child:
                      Text('Oyun $index', style: const TextStyle(fontSize: 16)))
            ])));
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
        }));
  }

  Widget _buildDot(int index) {
    return GestureDetector(
        onTap: () => onPageSelected(index),
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.page?.round() == index
                    ? Colors.red
                    : Colors.grey)));
  }
}
