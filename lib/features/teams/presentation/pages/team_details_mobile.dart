import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_description_card.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../providers/team_provider.dart';
import '../widgets/web/team_gallery_spotlight_web.dart';
import '../widgets/web/team_hero_web.dart';
import '../widgets/web/team_shows_section_web.dart';
import '../widgets/web/team_story_section_web.dart';

class TeamDetailsPage extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends ConsumerState<TeamDetailsPage>
    with GlobalScrollMixin {
  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final teamDetailAsync = ref.watch(teamDetailProvider(widget.teamId));

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      title: teamDetailAsync.value?.team.name.toUpperCase() ?? 'EKİP DETAYI',
      subtitle: 'Sanat Topluluğu',
      rightIcon: Icons.groups_2_rounded,
      customScrollController: scrollController,
      isLoading: teamDetailAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
          ambientColor: context.colors.primary.withOpacity(0.05),
          safeAreaTop: true),
      child: teamDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final _) => Center(child: Text("Hata: $err")),
        data: (final state) => context.isDesktop
            ? _buildDesktopContent(context, state)
            : _buildMobileContent(context, state),
      ),
    );
  }

  // --- MASAÜSTÜ (WEB) İÇERİK ---
  //
  // Mobil deneyim tamamen korunuyor (bkz. _buildMobileContent); masaüstünde
  // bunun yerine "Çam & Mercan" kimliğine uygun, sinematik/editoryal bir
  // sayfa kuruluyor: tam genişlikte bir sahne perdesi hero, asimetrik bir
  // hikaye bölümü, dergi düzeninde bir eserler ızgarası ve son olarak
  // "sahneye çıkış" (spotlight reveal) efektiyle beliren bir takım galerisi.
  Widget _buildDesktopContent(
          final BuildContext context, final TeamDetailState state) =>
      CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: TeamHeroWeb(team: state.team, shows: state.shows),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: WebColors.darkBlueBackground,
              padding: const EdgeInsets.symmetric(vertical: 90),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TeamStorySectionWeb(
                            description: state.team.description),
                        if (state.shows.isNotEmpty) ...[
                          const SizedBox(height: 100),
                          TeamShowsSectionWeb(shows: state.shows),
                        ],
                        if (state.team.photosId.isNotEmpty) ...[
                          const SizedBox(height: 100),
                          TeamGallerySpotlightWeb(
                              photos: state.team.photosId),
                        ],
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // --- MOBİL İÇERİK (DEĞİŞTİRİLMEDİ) ---
  Widget _buildMobileContent(
          final BuildContext context, final TeamDetailState state) =>
      CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 1. SANATSAL PARALLAX HEADER
          _buildSliverHeader(context, state),

          // 🎭 2. ANA İÇERİK PANELİ
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  _buildDragHandle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // 📖 EKİP HİKAYESİ
                        _buildSectionHeader(context, "EKİP HİKAYESİ",
                            Icons.auto_stories_rounded),
                        const SizedBox(height: 12),
                        CustomDescriptionCard(
                          description:
                              state.team.description.replaceAll('\\n', '\n'),
                        ),
                        const SizedBox(height: 40),

                        // 🎬 SAHNEDEKİ ESERLER Başlığı
                        if (state.shows.isNotEmpty) ...[
                          _buildSectionHeader(context, "SAHNEDEKİ ESERLER",
                              Icons.auto_awesome_motion_rounded),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 MOZAİK GALERİ
          if (state.shows.isNotEmpty)
            ShowMosaicGallery(shows: state.shows, direction: Axis.vertical),

          // 📸 TAKIM GALERİSİ
          SliverToBoxAdapter(
            child: Container(
              color: context.scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  if (state.team.photosId.isNotEmpty) ...[
                    _buildSectionHeader(
                        context, "TAKIM GALERİSİ", Icons.collections_rounded),
                    const SizedBox(height: 20),
                    GallerySection(photos: state.team.photosId),
                    const SizedBox(height: 120),
                  ],
                ],
              ),
            ),
          ),
        ],
      );

  // --- MODERN UI BİLEŞENLERİ ---

  Widget _buildSliverHeader(
          final BuildContext context, final TeamDetailState state) =>
      SliverAppBar(
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

  Widget _buildTeamHeadline(final BuildContext context, final String name) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: context.colors.primary.withOpacity(0.2)),
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

  Widget _buildSectionHeader(final BuildContext context, final String title,
          final IconData icon) =>
      Row(
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

  Widget _buildDragHandle() => Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2)),
      );
}
