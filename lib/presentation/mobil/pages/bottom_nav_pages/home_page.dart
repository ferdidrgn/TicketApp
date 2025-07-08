import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/providers/campaign/campaign_provider.dart';
import 'package:ticketapp/data/providers/show/show_provider.dart';
import 'package:ticketapp/data/providers/stage/stage_provider.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import '../../../../core/widgets/custom_category_card.dart';
import '../../../../core/widgets/custom_dots_indicator.dart';
import '../../../../core/widgets/custom_search.dart';
import '../../../../core/widgets/custom_show_card.dart';
import '../../../../core/widgets/custom_stage_card.dart';
import '../../../../core/widgets/custom_title.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../domain/entities/campaign.dart';
import '../../../../domain/entities/show.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import '../search_page/search_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _loadAllData();
      _setupAutoScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    ref.read(campaignProvider.notifier).loadCampaigns();
    ref.read(showProvider.notifier).loadShows(true);
    ref.read(stageProvider.notifier).loadStages(true);
  }

  void _setupAutoScroll() {
    final campaigns = ref.read(campaignProvider).dataList;
    if (campaigns == null || campaigns.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 10), (final _) {
      _currentPage = (_currentPage + 1) % campaigns.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _resolveDetailPage(final String url) {
    final id = url.split('/').last;
    if (url.contains('shows')) return PlayerDetailPage(playerId: id);
    if (url.contains('stage')) return StageDetailPage(stageId: id);
    if (url.contains('show')) return ShowDetailPage(showId: id);
    throw Exception('Unknown URL: $url');
  }

  void _navigateTo(final Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (final _) => page));

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    if ([campaignState, showState, stageState].any((final s) => s.isLoading))
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (showState.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showState.errorMessage ?? 'Bir hata oluştu',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _loadAllData, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            if (campaignState.dataList != null)
              _buildCampaignSlider(campaignState.dataList),
            CustomSearchBar(onSearchTap: () => _navigateTo(const SearchPage())),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Kategoriler'),
            const CategoryCardBuilder(),
            const CustomSectionTitle(title: 'Yeni Gösteriler'),
            _showList(items: showState.dataList!.cast<Show>()),
            const CustomSectionTitle(title: 'Sahneler'),
            _stageList(items: stageState.dataList!.cast<Stage>()),
            const CustomSectionTitle(title: 'Oyunlardan Kareler'),
            _buildHorizontalList(
              items: List.generate(6, (final index) => index),
              itemBuilder: _buildGamePhotoCard,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _showList({required final List<Show?> items}) {
    return _buildHorizontalList(
      items: items,
      itemBuilder: (final show) => CustomVerticalShowCard(
        imageUrl: show?.imageUrl ?? "",
        gameName: show?.name ?? "",
        onTap: () {
          if (show?.id != null) _navigateTo(ShowDetailPage(showId: show!.id));
        },
      ),
    );
  }

  Widget _stageList({required final List<Stage?> items}) {
    return _buildHorizontalList(
      items: items,
      itemBuilder: (final stage) => CustomStageCard(
        text: stage?.name ?? "",
        imageUrl: stage?.imageUrl ?? "",
        onPressed: () {
          if (stage?.id != null)
            _navigateTo(StageDetailPage(stageId: stage!.id));
        },
      ),
    );
  }

  Widget _buildCampaignSlider(final List<Campaign>? campaigns) {
    if (campaigns == null || campaigns.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: campaigns.length,
              itemBuilder: (final _, final index) => GestureDetector(
                onTap: () =>
                    _navigateTo(_resolveDetailPage(campaigns[index].url)),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CachedNetworkImage(
                        imageUrl: campaigns[index].imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (final _, final __) => ShimmerLoading(),
                        errorWidget: (final _, final __, final ___) =>
                            const Icon(Icons.error),
                      ),
                      Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          campaigns[index].title,
                          style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.onPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DotsIndicator(
            controller: _pageController,
            itemCount: campaigns.length,
            onPageSelected: (final page) => setState(() => _currentPage = page),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList<T>({
    required final List<T> items,
    required final Widget Function(T) itemBuilder,
  }) =>
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: items.length,
          itemBuilder: (final _, final i) => itemBuilder(items[i]),
        ),
      );

  Widget _buildGamePhotoCard(final int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
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
                placeholder: (final context, final url) => ShimmerLoading(),
                errorWidget: (final context, final url, final error) =>
                    const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('Oyun $index', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
