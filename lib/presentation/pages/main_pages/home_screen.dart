import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/model/campaing_model.dart';
import 'package:ticketapp/data/model/show_model.dart';
import 'package:ticketapp/data/model/stage_model.dart';
import 'package:ticketapp/data/providers/campaign/campaign_provider.dart';
import 'package:ticketapp/data/providers/show/show_provider.dart';
import 'package:ticketapp/data/providers/stage/stage_provider.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/custom_category_card.dart';
import '../../../core/widgets/custom_dots_indicator.dart';
import '../../../core/widgets/custom_search.dart';
import '../../../core/widgets/custom_show_card.dart';
import '../../../core/widgets/custom_stage_card.dart';
import '../../../core/widgets/custom_title.dart';
import '../../../domain/entities/campaign.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import 'search_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
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
    _timer = Timer.periodic(const Duration(seconds: 10), (final timer) {
      setState(() {
        _currentPage = (_currentPage + 1) % ref.read(campaignProvider).campaigns.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    });
  }

  void _navigateToSearch() {
    Navigator.push(context,
        MaterialPageRoute(builder: (final context) => const SearchPage()));
  }

  void _navigateToDetailPage(final String url) {
    final id = _extractIdFromUrl(url);
    Widget detailPage;

    if (url.contains('player')) detailPage = PlayerDetailPage(playerId: id);
    else if (url.contains('stage')) detailPage = StageDetailPage(stageId: id);
    else if (url.contains('show')) detailPage = ShowDetailPage(showId: id);
    else throw Exception('Unknown URL: $url');


    Navigator.push(context, MaterialPageRoute(builder: (final context) => detailPage));
  }

  String _extractIdFromUrl(final String url) {
    return url.split('/').last;
  }

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    if (campaignState.isLoading || showState.isLoading || stageState.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    _loadInitialDataIfNeeded(campaignState, showState, stageState);

    if (_hasError(campaignState, showState, stageState))
      return Scaffold(body: Center(child: Text(campaignState.errorMessage!)));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCampaignSlider(campaignState.campaigns),
            CustomSearchBar(onSearchTap: _navigateToSearch),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Kategoriler'),
            const CategoryCardBuilder(),
            const CustomSectionTitle(title: 'Yeni Gösteriler'),
            _buildNewShows(showState.shows),
            const CustomSectionTitle(title: 'Sahneler'),
            _buildStageSection(stageState.stages),
            const CustomSectionTitle(title: 'Oyunlardan Kareler'),
            _buildGamesPhotoSection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _loadInitialDataIfNeeded(
      final campaignState, final showState, final stageState) {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!campaignState.isLoading && campaignState.campaigns.isEmpty)
        ref.read(campaignProvider.notifier).loadCampaigns();
      if (!showState.isLoading && showState.shows.isEmpty)
        ref.read(showProvider.notifier).loadShows(true);
      if (!stageState.isLoading && stageState.stages.isEmpty)
        ref.read(stageProvider.notifier).loadStages(true);
    });
  }

  bool _hasError(final campaignState, final showState, final stageState) {
    return campaignState.errorMessage != null ||
        showState.errorMessage != null ||
        stageState.errorMessage != null;
  }

  Widget _buildCampaignSlider(final List<CampaignModel?> campaigns) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: campaigns.length,
              itemBuilder: (final context, final index) {
                return _buildCampaignPage(campaigns[index]?.toEntity());
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildDotsIndicator(campaigns.length),
        ],
      ),
    );
  }

  Widget _buildCampaignPage(final Campaign? campaign) {
    if (campaign == null) return const SizedBox();

    return GestureDetector(
      onTap: () => _navigateToDetailPage(campaign.url),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.network(
              campaign.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (final context, final child, final loadingProgress) {
                if (loadingProgress == null) return child;
                return const ShimmerLoading();
              },
              errorBuilder: (final context, final error, final stackTrace) {
                return const Center(child: Icon(Icons.error));
              },
            ),
            Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.all(8),
              child: Text(
                campaign.title,
                style: const TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(final int itemCount) {
    return DotsIndicator(
      controller: _pageController,
      itemCount: itemCount,
      onPageSelected: (final page) {
        setState(() {
          _currentPage = page;
        });
        _pageController.animateToPage(
          page,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget _buildNewShows(final List<ShowModel?> shows) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shows.length,
        itemBuilder: (final context, final index) {
          return GestureDetector(
            child: CustomVerticalShowCard(
              imageUrl: shows[index]?.imageUrl ?? '',
              gameName: shows[index]?.name ?? '',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final context) =>
                        ShowDetailPage(showId: shows[index]?.id ?? ''),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageSection(final List<StageModel?> stages) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stages.length,
        itemBuilder: (final context, final index) {
          return CustomStageCard(
            text: stages[index]?.name ?? '',
            imageUrl: stages[index]?.imageUrl ?? '',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final context) =>
                      StageDetailPage(stageId: stages[index]?.id ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGamesPhotoSection() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (final context, final index) {
          return _buildGamePhotoCard(index);
        },
      ),
    );
  }

  Widget _buildGamePhotoCard(final int index) {
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
              child: Image.network(
               'https://i.ytimg.com/vi/tzPpkRLf9a8/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGHIgWyg9MA8=&rs=AOn4CLCBnYXpB7USjvYDePL64AaVI7Epyw',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (final context, final child, final loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const ShimmerLoading();
                },
                errorBuilder: (final context, final error, final stackTrace) {
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Oyun $index', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
