import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import '../../../../core/common/base_loadable_state.dart';
import '../../../../shared/widgets/custom_category_card.dart';
import '../../../../shared/widgets/custom_dots_indicator.dart';
import '../../../../shared/widgets/custom_floating_action_button.dart';
import '../../../../shared/widgets/custom_search.dart';
import '../../../shows/presentation/widgets/mobile/custom_show_card.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';
import '../../../../shared/widgets/custom_title.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _loadAllData();
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    // ref.read kullanmak burada doğrudur, çünkü sadece 'tetikleme' yapıyoruz.
    ref.read(campaignProvider.notifier).loadCampaigns();
    ref.read(showProvider.notifier).loadShows(true);
    ref.read(stageProvider.notifier).loadStages(true);
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(const Duration(seconds: 5), (final timer) {
      if (!_pageController.hasClients || !mounted) return;

      final campaignState = ref.read(campaignProvider);
      if (!campaignState.hasData) return;

      final campaigns = campaignState.dataList!;
      final nextPage = (_pageController.page?.round() ?? 0) + 1;

      _pageController.animateToPage(nextPage % campaigns.length,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  void _navigateToPage(final Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (final _) => page));

  /// URL'ye göre doğru detay sayfasını çözer.
  Widget _resolveDetailPage(final String url) {
    try {
      final id = url.split('/').last;
      if (id.isEmpty) throw Exception('Geçersiz URL ID: $url');

      if (url.contains('/shows')) return PlayerDetailPage(playerId: id);
      if (url.contains('/show')) return ShowDetailPage(showId: id);
      if (url.contains('/stages')) return StageDetailPage(stageId: id);

      throw Exception('Bilinmeyen URL türü: $url');
    } catch (e) {
      debugPrint('Sayfa çözümlenemedi: $e');
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Sayfa yüklenemedi.')),
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    return Scaffold(
      floatingActionButton: CustomFloatingActionButton(onPressed: _loadAllData),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Kampanya Bölümü ---
            _buildCampaignSection(campaignState),

            // --- 2. Arama Çubuğu ---
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
              child: CustomSearchBar(
                onSearchTap: () => _navigateToPage(const SearchPage()),
              ),
            ),

            // --- 3. Kategoriler Bölümü ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: CustomSectionTitle(title: 'Kategoriler'),
            ),
            const CategoryCardBuilder(),

            // --- 4. Yeni Gösteriler Bölümü ---
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: CustomSectionTitle(title: 'Yeni Gösteriler'),
            ),
            _buildShowSection(showState),

            // --- 5. Sahneler Bölümü ---
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: CustomSectionTitle(title: 'Sahneler'),
            ),
            _buildStageSection(stageState),

            // --- 6. Oyunlardan Kareler (Statik) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: CustomSectionTitle(title: 'Oyunlardan Kareler'),
            ),
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

  // --- BÖLÜM (SECTION) BUILDER'LARI ---

  Widget _buildCampaignSection(
      final LoadableState<dynamic, List<Campaign>> state) {
    if (state.isLoading)
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
            child: ShimmerLoading(
          height: MediaQuery.of(context).size.height * 0.2,
          width: MediaQuery.of(context).size.width * 0.9,
        )),
      );

    if (state.hasError)
      return _buildErrorWidget(state.errorMessage ?? 'Kampanyalar yüklenemedi');

    if (!state.hasData) return const SizedBox(height: 100);

    final campaigns = state.dataList!;
    return _buildCampaignSlider(campaigns);
  }

  Widget _buildShowSection(final LoadableState<dynamic, List<Show>> state) {
    if (state.isLoading) return _buildHorizontalShimmerList();
    if (state.hasError)
      return _buildErrorWidget(state.errorMessage ?? 'Gösteriler yüklenemedi');

    if (!state.hasData) return const SizedBox(height: 10);

    final shows = state.dataList!;
    return _buildShowList(shows);
  }

  Widget _buildStageSection(final LoadableState<dynamic, List<Stage>> state) {
    if (state.isLoading) return _buildHorizontalShimmerList();
    if (state.hasError)
      return _buildErrorWidget(state.errorMessage ?? 'Sahneler yüklenemedi');

    if (!state.hasData) return const SizedBox(height: 10);

    final stages = state.dataList!;
    return _buildStageList(stages);
  }

  // --- ORİJİNAL WIDGET BUILDER'LAR ---

  Widget _buildCampaignSlider(final List<Campaign> campaigns) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: campaigns.length,
              onPageChanged: (final index) =>
                  setState(() => _currentPage = index),
              itemBuilder: (final context, final index) {
                final campaign = campaigns[index];
                return GestureDetector(
                  onTap: () =>
                      _navigateToPage(_resolveDetailPage(campaign.url)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Card(
                      elevation: 8,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: campaign.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (final _, final __) =>
                                  const ShimmerLoading(),
                              errorWidget: (final _, final __, final ___) =>
                                  const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black87, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                              ),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              campaign.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          DotsIndicator(
            itemCount: campaigns.length,
            currentIndex: _currentPage % campaigns.length,
            onPageSelected: (final page) {
              if (!_pageController.hasClients) return;
              _pageController.animateToPage(
                page,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowList(final List<Show> shows) {
    return _buildHorizontalList(
      items: shows,
      itemBuilder: (final show) => CustomVerticalShowCard(
        imageUrl: show.imageUrl,
        gameName: show.name,
        onTap: () => _navigateToPage(ShowDetailPage(showId: show.id)),
      ),
    );
  }

  Widget _buildStageList(final List<Stage> stages) {
    return _buildHorizontalList(
      items: stages,
      itemBuilder: (final stage) => CustomStageCard(
        text: stage.name,
        imageUrl: stage.imageUrl,
        onPressed: () => _navigateToPage(StageDetailPage(stageId: stage.id)),
      ),
    );
  }

  Widget _buildHorizontalList<T>({
    required final List<T> items,
    required final Widget Function(T) itemBuilder,
  }) {
    if (items.isEmpty) return const SizedBox(height: 10);

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: items.length,
        itemBuilder: (final _, final index) => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: itemBuilder(items[index]),
        ),
      ),
    );
  }

  Widget _buildGamePhotoCard(final int index) {
    const imageUrl =
        'https://i.ytimg.com/vi/tzPpkRLf9a8/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGHIgWyg9MA8=&rs=AOn4CLCBnYXpB7USjvYDePL64AaVI7Epyw';

    return SizedBox(
      width: 160,
      height: 200,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (final _, final __) => const ShimmerLoading(),
                errorWidget: (final _, final __, final ___) =>
                    const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'Oyun $index',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI (HELPER) WIDGET'LAR ---

  Widget _buildErrorWidget(final String message) {
    return Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHorizontalShimmerList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 3,
        itemBuilder: (final _, final __) => const Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: ShimmerLoading(width: 160, height: 200),
        ),
      ),
    );
  }
}
