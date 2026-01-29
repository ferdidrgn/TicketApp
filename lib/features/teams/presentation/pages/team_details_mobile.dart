import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_description_card.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../providers/team_provider.dart';

class TeamDetailsPage extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends ConsumerState<TeamDetailsPage>
    with GlobalScrollMixin {
  @override
  void onLoadMore() {} // Mixin gerekliliği

  @override
  Widget build(final BuildContext context) {
    final teamDetailAsync = ref.watch(teamDetailProvider(widget.teamId));

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      customScrollController: scrollController,
      isLoading: teamDetailAsync.isLoading,
      layoutConfig: PageBackgroundLayoutConfig(
        ambientColor: context.colors.primary,
        safeAreaTop: false,
      ),
      child: teamDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final _) => Center(child: Text("Hata: $err")),
        data: (final state) => CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(context, state),

            // 1. BÖLÜM: ÜST BİLGİLER (SliverToBoxAdapter içinde)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildDragHandle(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildTeamHeadline(context, state.team.name),
                          const SizedBox(height: 32),
                          _buildSectionHeader(context, "EKİP HİKAYESİ", Icons.auto_stories_rounded),
                          const SizedBox(height: 12),
                          CustomDescriptionCard(
                            description: state.team.description.replaceAll('\\n', '\n'),
                          ),
                          const SizedBox(height: 40),
                          if (state.shows.isNotEmpty)
                            _buildSectionHeader(context, "SAHNEDEKİ ESERLER", Icons.auto_awesome_motion_rounded),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 KRİTİK DÜZELTME: ShowMosaicGallery zaten sliver'dır!
            // Bu yüzden Column dışına, doğrudan CustomScrollView içine alıyoruz.
            if (state.shows.isNotEmpty)
              ShowMosaicGallery(shows: state.shows, direction: Axis.vertical),

            // 2. BÖLÜM: ALT GALERİ (Tekrar SliverToBoxAdapter açıyoruz)
            SliverToBoxAdapter(
              child: Container(
                color: context.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    if (state.team.photosId.isNotEmpty) ...[
                      _buildSectionHeader(context, "TAKIM GALERİSİ", Icons.collections_rounded),
                      const SizedBox(height: 20),
                      _buildArtisticGallery(state.team.photosId),
                      const SizedBox(height: 120),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODERN UI BİLEŞENLERİ ---

  Widget _buildSliverHeader(
      final BuildContext context, final TeamDetailState state) {
    return SliverAppBar(
      expandedHeight: 350,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: state.team.imageUrl,
              fit: BoxFit.cover,
              placeholder: (final _, final __) => const ShimmerLoading(),
            ),
            // Sanatsal Karartma ve Gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.1, 0.6],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeadline(final BuildContext context, final String name) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.primary.withOpacity(0.2)),
          ),
          child: Text(
            "PROFESYONEL EKİP",
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      final BuildContext context, final String title, final IconData icon) {
    return Row(
      children: [
        Icon(icon, color: context.colors.primary, size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildArtisticGallery(final List<String> photos) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: photos.length,
        itemBuilder: (final context, final index) => Container(
          width: 180,
          margin: const EdgeInsets.only(right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  placeholder: (final _, final __) => const ShimmerLoading(),
                ),
                // Cam efekti şeridi
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 40,
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.fullscreen_rounded,
                            color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() => Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2)),
      );
}
