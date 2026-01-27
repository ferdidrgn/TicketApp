import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../providers/player_provider.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with TickerProviderStateMixin {
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollNotifier.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(playerDetailProvider(widget.playerId));
    final accentColor = context.colors.primary;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      isLoading: detailAsync.isLoading,
      shimmerSkeleton: const ArtisticPageShimmer(),
      layoutConfig: PageBackgroundLayoutConfig(
        backgroundColor: context.scaffoldBackgroundColor,
        ambientColor: accentColor.withOpacity(0.05),
        extendBody: true,
      ),
      child: detailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (final err, final stack) => Center(
          child: Text(
            "Hata: $err",
            style: TextStyle(color: context.colors.onSurface),
          ),
        ),
        data: (final state) => NotificationListener<ScrollNotification>(
          onNotification: (final notification) {
            if (notification is ScrollUpdateNotification) {
              _scrollNotifier.value = notification.metrics.pixels;
            }
            return false;
          },
          child: Stack(
            children: [
              // PARALLAX HEADER
              _buildParallaxHeader(context, state.player.imageUrl),

              // MAIN CONTENT
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Spacer for header
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: context.responsive(
                        mobile: context.screenHeight * 0.5,
                        tablet: context.screenHeight * 0.55,
                        desktop: context.screenHeight * 0.6,
                      ),
                    ),
                  ),

                  // ARTIST NAME SECTION
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildArtistNameSection(context, state.player),
                    ),
                  ),

                  // STATS CARDS
                  SliverToBoxAdapter(
                    child: _buildStatsSection(context, state),
                  ),

                  // TABS SECTION
                  SliverToBoxAdapter(
                    child: _buildContentTabs(context, state),
                  ),

                  // Bottom spacing
                  SliverToBoxAdapter(
                    child: SizedBox(height: context.spacingLarge * 2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 PARALLAX HEADER
  Widget _buildParallaxHeader(
      final BuildContext context, final String imageUrl) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollNotifier,
      builder: (final context, final offset, final child) {
        final accentColor = context.colors.primary;
        final double blur = (offset / 50).clamp(0, 15);
        final double scale = 1 + (offset / 1000).clamp(0, 0.2);
        final double opacity = (1 - (offset / 300)).clamp(0, 1);

        return Positioned(
          top: -offset * 0.4,
          left: 0,
          right: 0,
          height: context.responsive(
            mobile: context.screenHeight * 0.7,
            tablet: context.screenHeight * 0.75,
            desktop: context.screenHeight * 0.8,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Transform.scale(
                scale: scale,
                child: OptimizedCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Blur Layer
              if (blur > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    color: context.scaffoldBackgroundColor.withOpacity(0.2),
                  ),
                ),

              // Vignette Effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      context.scaffoldBackgroundColor.withOpacity(0.0),
                      // Resmin üstü tamamen ferah
                      context.scaffoldBackgroundColor.withOpacity(0.4),
                      // Yumuşak geçiş başlar
                      context.scaffoldBackgroundColor.withOpacity(0.95),
                      // İçeriğe hazırlık
                      context.scaffoldBackgroundColor,
                      // Tam siyah/arka plan uyuşması (Hatayı siler)
                    ],
                    stops: const [
                      0.0,
                      0.45,
                      0.75,
                      0.9,
                      1.0
                    ], // Geçiş noktalarını içeriğe göre optimize ettik
                  ),
                ),
              ),

              // Spotlight Pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (final context, final child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 0.8 + (_pulseController.value * 0.2),
                        colors: [
                          accentColor.withOpacity(0.15 * opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Bottom Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      context.scaffoldBackgroundColor.withOpacity(0.0),
                      // Tepeyi tamamen açtık
                      context.scaffoldBackgroundColor.withOpacity(0.4),
                      context.scaffoldBackgroundColor.withOpacity(0.8),
                      context.scaffoldBackgroundColor,
                      // İçerikle birleşen yer tam siyah
                    ],
                    stops: const [
                      0.0,
                      0.3,
                      0.6,
                      0.8,
                      1.0
                    ], // Geçişi daha aşağı çektik
                  ),
                ),
              ),

              // Decorative Corners (Desktop only)
              if (context.isDesktop) ...[
                Positioned(
                  top: 40,
                  left: 40,
                  child: _buildDecorativeCorner(context),
                ),
                Positioned(
                  top: 40,
                  right: 40,
                  child: Transform.flip(
                    flipX: true,
                    child: _buildDecorativeCorner(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDecorativeCorner(final BuildContext context) {
    return Container(
      width: context.responsive(mobile: 40.0, desktop: 60.0),
      height: context.responsive(mobile: 40.0, desktop: 60.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.primary.withOpacity(0.4),
            width: 2,
          ),
          left: BorderSide(
            color: context.colors.primary.withOpacity(0.4),
            width: 2,
          ),
        ),
      ),
    );
  }

  // 📛 ARTIST NAME SECTION
  Widget _buildArtistNameSection(
      final BuildContext context, final dynamic player) {
    return Container(
      padding: context.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Row(
            children: [
              Container(
                width: context.responsive(mobile: 30.0, desktop: 40.0),
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.spacing),
              Text(
                "SANATIN MİRASI",
                style: TextStyle(
                  color: context.colors.primary,
                  letterSpacing: context.responsive(mobile: 3.0, desktop: 5.0),
                  fontSize: context.responsive(mobile: 9.0, desktop: 11.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing),

          // Artist Name with Shadow Effect
          Stack(
            children: [
              // Outline text
              Text(
                "${player.firstName}\n${player.lastName}".toUpperCase(),
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  letterSpacing: -2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2
                    ..color = context.colors.primary.withOpacity(0.3),
                ),
              ),
              // Main text
              Text(
                "${player.firstName}\n${player.lastName}".toUpperCase(),
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  letterSpacing: -2,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 STATS SECTION
  Widget _buildStatsSection(
      final BuildContext context, final PlayerDetailState state) {
    return Padding(
      padding: context.sectionPadding,
      child: context.responsive(
        mobile: _buildMobileStats(context, state),
        desktop: _buildDesktopStats(context, state),
      ),
    );
  }

  Widget _buildMobileStats(
      final BuildContext context, final PlayerDetailState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.theater_comedy,
                value: "${state.activeShows.length}",
                label: "Aktif Oyun",
              ),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.history_edu,
                value: "${state.pastShows.length}",
                label: "Geçmiş Oyun",
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.auto_awesome,
                value: "∞",
                label: "İhtilas",
              ),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.emoji_events,
                value: "12+",
                label: "Ödül",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(
      final BuildContext context, final PlayerDetailState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.theater_comedy,
            value: "${state.activeShows.length}",
            label: "Aktif Oyun",
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.history_edu,
            value: "${state.pastShows.length}",
            label: "Geçmiş Oyun",
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.auto_awesome,
            value: "∞",
            label: "İhtilas",
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.emoji_events,
            value: "12+",
            label: "Ödül",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    final BuildContext context, {
    required final IconData icon,
    required final String value,
    required final String label,
  }) {
    return Container(
      padding: EdgeInsets.all(
        context.responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0),
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(context.borderRadius(0.75)),
        border: Border.all(
          color: context.colors.primary.withOpacity(0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: context.colors.primary.withOpacity(0.7),
            size: context.responsive(mobile: 28.0, desktop: 36.0),
          ),
          SizedBox(height: context.spacing * 0.5),
          Text(
            value,
            style: TextStyle(
              fontSize: context.responsive(mobile: 28.0, desktop: 36.0),
              fontWeight: FontWeight.w900,
              color: context.colors.onSurface,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: context.spacing * 0.25),
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsive(mobile: 11.0, desktop: 13.0),
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // 📑 CONTENT TABS
  Widget _buildContentTabs(
      final BuildContext context, final PlayerDetailState state) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          SizedBox(height: context.spacingLarge),
          // Tab Bar tasarımı...
          Padding(
            padding: context.paddingHorizontal,
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border:
                    Border.all(color: context.colors.primary.withOpacity(0.2)),
              ),
              child: TabBar(
                labelColor: context.colors.primary,
                unselectedLabelColor: context.colors.onSurface.withOpacity(0.6),
                indicator: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "BİYOGRAFİ"),
                  Tab(text: "OYUNLAR"),
                  Tab(text: "ARŞİV"),
                  Tab(text: "BAŞARILAR"),
                ],
              ),
            ),
          ),

          SizedBox(height: context.spacingLarge),

          // Tab Views
          SizedBox(
            height: context.responsive(
                mobile: 600.0, tablet: 700.0, desktop: 800.0),
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildBiographyTab(context, state),
                _buildActiveShowsTab(context, state),
                _buildArchiveTab(context, state),
                _buildAchievementsTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📖 BIOGRAPHY TAB
  Widget _buildBiographyTab(
      final BuildContext context, final PlayerDetailState state) {
    return SingleChildScrollView(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Section
          Container(
            padding: EdgeInsets.all(
              context.responsive(mobile: 20.0, desktop: 28.0),
            ),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border(
                left: BorderSide(
                  color: context.colors.primary,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: context.colors.primary.withOpacity(0.3),
                  size: context.responsive(mobile: 32.0, desktop: 40.0),
                ),
                SizedBox(width: context.spacing),
                Expanded(
                  child: Text(
                    "Sahne benim tuvalim, kelimeler fırçam, ve her gece yeni bir eser yaratırım.",
                    style: TextStyle(
                      fontSize: context.responsive(mobile: 15.0, desktop: 17.0),
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                      color: context.colors.onSurface.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.spacingLarge),

          // Bio Section
          Container(
            padding: context.cardPadding,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "BİYOGRAFİ",
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(height: context.spacing),
                Text(
                  state.player.bio,
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 15.0, desktop: 17.0),
                    height: 1.8,
                    color: context.colors.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.spacingLarge),

          // Collaborations
          _buildCollaborationsCard(context, state.player.collaborations),
        ],
      ),
    );
  }

  Widget _buildCollaborationsCard(
      final BuildContext context, final List<String> collaborations) {
    // Eğer işbirliği verisi yoksa bu bölümü hiç çizme
    if (collaborations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: context.cardPadding,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: context.colors.primary, size: 20),
              SizedBox(width: context.spacing * 0.5),
              Text(
                "TANIMLAR",
                style: TextStyle(
                  fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing),
          Wrap(
            spacing: context.spacing * 0.75,
            runSpacing: context.spacing * 0.75,
            children: collaborations.map((final name) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: context.colors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(25),
                  color: context.colors.primary.withOpacity(0.05),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: context.colors.primary.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 🎭 ACTIVE SHOWS TAB
  Widget _buildActiveShowsTab(
      final BuildContext context, final PlayerDetailState state) {
    return GridView.builder(
      padding: context.pagePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns(3),
        childAspectRatio: 0.7,
        crossAxisSpacing: context.gridSpacing,
        mainAxisSpacing: context.gridSpacing,
      ),
      itemCount: state.activeShows.length,
      itemBuilder: (final context, final index) {
        final show = state.activeShows[index];
        return _buildShowCard(context, show, isActive: true);
      },
    );
  }

  Widget _buildShowCard(final BuildContext context, final Show show,
      {final bool isActive = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final context) => ShowDetailPage(showId: show.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              OptimizedCachedImage(
                imageUrl: show.imageUrl,
                fit: BoxFit.cover,
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Badge
              if (isActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "AKTİF",
                      style: TextStyle(
                        color: context.colors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

              // Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  show.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📚 ARCHIVE TAB
  Widget _buildArchiveTab(
      final BuildContext context, final PlayerDetailState state) {
    return ListView.builder(
      padding: context.pagePadding,
      itemCount: state.pastShows.length,
      itemBuilder: (final context, final index) {
        final show = state.pastShows[index];
        return _buildArchiveItem(context, show);
      },
    );
  }

  Widget _buildArchiveItem(final BuildContext context, final Show show) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final context) => ShowDetailPage(showId: show.id),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: context.spacing),
        padding: EdgeInsets.all(
          context.responsive(mobile: 12.0, desktop: 16.0),
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(
            color: context.colors.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: context.responsive(mobile: 60.0, desktop: 80.0),
              height: context.responsive(mobile: 85.0, desktop: 110.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.borderRadius(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.borderRadius(0.5)),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: OptimizedCachedImage(
                    imageUrl: show.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacing),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.name.toUpperCase(),
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: context.spacing * 0.5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "ARŞİV",
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.responsive(mobile: 16.0, desktop: 18.0),
              color: context.colors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(
      final BuildContext context, final PlayerDetailState state) {
    if (state.player.achievements.isEmpty)
      return Center(
        child: Text(
          "Henüz başarı kaydı bulunmuyor.",
          style: TextStyle(color: context.colors.onSurface.withOpacity(0.5)),
        ),
      );

    return ListView.builder(
      padding: context.pagePadding.copyWith(top: 24),
      itemCount: state.player.achievements.length,
      itemBuilder: (final context, final index) {
        final item = state.player.achievements[index];
        final bool isLast = index == state.player.achievements.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KRONOLOJİ İSTASYONU (SOL TARAF) ---
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // İstasyon İkonu
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: context.colors.primary, width: 2),
                        shape: BoxShape.circle,
                        color: context.colors.primary.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(Icons.theater_comedy_rounded,
                            size: 14, color: context.colors.primary),
                      ),
                    ),
                    // Kesik Çizgi Tasarımı
                    if (!isLast)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: CustomPaint(
                            painter: _DashedLinePainter(
                                color: context.colors.primary.withOpacity(0.3)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // --- İÇERİK KARTI (SAĞ TARAF) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Yıl ve Dekoratif Hat
                      Row(
                        children: [
                          Text(
                            item['year'] ?? '',
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    context.colors.primary.withOpacity(0.3),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Başlık
                      Text(
                        (item['title'] ?? '').toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Detay Metni ve İkonu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12,
                              color: context.colors.primary.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['detail'] ?? '',
                              style: TextStyle(
                                color:
                                    context.colors.onSurface.withOpacity(0.6),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Kesik çizgi çizici (Fütüristik fanzin havası için)
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => false;
}
