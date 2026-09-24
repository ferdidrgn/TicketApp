import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/custom_description_card.dart';
import '../../../../shared/widgets/footers/footer.dart';
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
    // 🖥️ MASAÜSTÜ: BasePageWrapper'ın mobil "app chrome"undan (header bar,
    // FAB, particles) tamamen bağımsız, kendi web kabuğuna sahip ayrı yol.
    if (context.isDesktop)
      return _TeamDetailDesktopPage(teamId: widget.teamId);

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
      // NOT: Buraya ulaşıldığında zaten mobil/tablet dalındayız (masaüstü
      // yukarıdaki erken dönüşle _TeamDetailDesktopPage'e gidiyor) — bu
      // yüzden içerik doğrudan mobil gövde, ayrıca context.isDesktop dalı
      // gerekmiyor (eskiden burada artık var olmayan _buildDesktopContent'e
      // çağrı yapan ölü bir dal vardı).
      child: teamDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final _) => Center(child: Text("Hata: $err")),
        data: (final state) => _buildMobileContent(context, state),
      ),
    );
  }

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xxl),

                        // 📖 EKİP HİKAYESİ
                        _buildSectionHeader(context, "EKİP HİKAYESİ",
                            Icons.auto_stories_rounded),
                        const SizedBox(height: AppSpacing.md),
                        CustomDescriptionCard(
                          description:
                              state.team.description.replaceAll('\\n', '\n'),
                        ),
                        const SizedBox(height: AppSpacing.huge),

                        // 🎬 SAHNEDEKİ ESERLER Başlığı
                        if (state.shows.isNotEmpty) ...[
                          _buildSectionHeader(context, "SAHNEDEKİ ESERLER",
                              Icons.auto_awesome_motion_rounded),
                          const SizedBox(height: AppSpacing.xl),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.huge),
                  if (state.team.photosId.isNotEmpty) ...[
                    _buildSectionHeader(
                        context, "TAKIM GALERİSİ", Icons.collections_rounded),
                    const SizedBox(height: AppSpacing.xl),
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(width: AppSpacing.md),
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
        margin: const EdgeInsets.only(top: AppSpacing.md),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: context.colors.onSurfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2)),
      );
}

// ============================================================
// 🖥️ MASAÜSTÜ (DESKTOP) SAYFASI
// ------------------------------------------------------------
// BasePageWrapper'ın mobil kabuğundan (TopHeaderWithBackButton,
// scroll-to-top FAB, pull-to-refresh, CustomAppBackground'ın
// FloatingParticles/AmbientLightEffect'i) tamamen bağımsız, kendi
// web görünümüne sahip ayrı bir kök widget. Sadece WebColors
// paletini kullanır.
//
// 🔥 DÜZELTME: Bu sayfa önceden `_TeamDetailDesktopBody` adında, dar
// (max 1200px), yuvarlatılmış-köşeli "büyütülmüş mobil kart" hissi veren,
// geri butonu ve site footer'ı OLMAYAN bir gövde kullanıyordu — hâlbuki
// `TeamHeroWeb`/`TeamStorySectionWeb`/`TeamShowsSectionWeb`/
// `TeamGallerySpotlightWeb` (tam ekran "perde açılışı" hero, sinematik
// spot ışığı, dergi düzeni) ZATEN yazılmıştı ama `_TeamDetailsPageState.
// build()`'daki `if (context.isDesktop) return _TeamDetailDesktopPage(...)`
// erken dönüşü yüzünden hiçbir zaman ÇALIŞMIYORDU (ölü kod). Artık
// masaüstü gerçekten bu zengin, tam genişlikte deneyimi kullanıyor;
// diğer web detay sayfalarıyla (show/player) tutarlı olacak şekilde sol
// üstte cam efektli geri butonu, sağ üstte paylaş butonu ve en altta
// site geneli `Footer` eklendi.
// ============================================================
class _TeamDetailDesktopPage extends ConsumerWidget {
  final String teamId;

  const _TeamDetailDesktopPage({required this.teamId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final teamDetailAsync = ref.watch(teamDetailProvider(teamId));

    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: teamDetailAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(120),
            child: CircularProgressIndicator(color: WebColors.primaryGold),
          ),
        ),
        error: (final err, final _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(120),
            child: Text(
              "Hata: $err",
              style: const TextStyle(color: WebColors.whiteText),
            ),
          ),
        ),
        data: (final state) => _TeamDetailDesktopBody(state: state),
      ),
    );
  }
}

class _TeamDetailDesktopBody extends StatefulWidget {
  final TeamDetailState state;

  const _TeamDetailDesktopBody({required this.state});

  @override
  State<_TeamDetailDesktopBody> createState() =>
      _TeamDetailDesktopBodyState();
}

class _TeamDetailDesktopBodyState extends State<_TeamDetailDesktopBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final team = widget.state.team;
    final shows = widget.state.shows;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: TeamHeroWeb(team: team, shows: shows)),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: WebColors.darkBlueBackground,
                padding: const EdgeInsets.symmetric(vertical: 90),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TeamStorySectionWeb(description: team.description),
                          if (shows.isNotEmpty) ...[
                            const SizedBox(height: 100),
                            TeamShowsSectionWeb(shows: shows),
                          ],
                          if (team.photosId.isNotEmpty) ...[
                            const SizedBox(height: 100),
                            TeamGallerySpotlightWeb(photos: team.photosId),
                          ],
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Footer()),
          ],
        ),
        Positioned(
          top: 40,
          left: 20,
          child: GlassmorphismBackButton(backgroundColor: WebColors.primaryGold),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: WebColors.darkBlueSurface,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Paylaş',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined,
                  size: 22, color: WebColors.whiteText),
              onPressed: () =>
                  TiyatrolDeeplinkService.shareTeam(id: team.id, name: team.name),
            ),
          ),
        ),
      ],
    );
  }
}
