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

/// 🎭 PLAYER DETAIL PAGE
///
/// Hybrid system ile:
/// - Dinamik achievements
/// - Dinamik collaborations
/// - Smooth scroll

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(playerDetailProvider(widget.playerId));
    final accentColor = context.colors.primary;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      customScrollController: _scrollController,
      isLoading: detailAsync.isLoading && !detailAsync.hasValue,
      shimmerSkeleton: const ArtisticPageShimmer(),
      layoutConfig: PageBackgroundLayoutConfig(
        backgroundColor: context.scaffoldBackgroundColor,
        ambientColor: accentColor.withOpacity(0.05),
        extendBody: true,
      ),
      child: detailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => _buildError(context, err.toString()),
        data: (state) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(context, state.player.imageUrl,
                "${state.player.firstName} ${state.player.lastName}"),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: context.spacingLarge),
                    _buildStatsSection(context, state),
                    SizedBox(height: context.spacingLarge * 2),
                    _buildContentTabs(context, state),
                    SizedBox(height: context.spacingLarge * 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(
      BuildContext context, String imageUrl, String name) {
    return SliverAppBar(
      expandedHeight: context.responsive(
        mobile: context.screenHeight * 0.5,
        tablet: context.screenHeight * 0.55,
        desktop: context.screenHeight * 0.6,
      ),
      pinned: false,
      stretch: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (context, offset, child) {
            final blur = (offset / 50).clamp(0.0, 15.0);
            final opacity = (1 - (offset / 300)).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
                if (blur > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.scaffoldBackgroundColor.withOpacity(0.0),
                        context.scaffoldBackgroundColor.withOpacity(0.5),
                        context.scaffoldBackgroundColor.withOpacity(0.9),
                        context.scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.4, 0.7, 0.85, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: context.spacingLarge,
                  left: context.pagePadding.left,
                  right: context.pagePadding.right,
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: context.colors.primary.withOpacity(0.5)),
                          ),
                          child: Text(
                            "SANATIN MİRASI",
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: context.spacing),
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            fontSize: context.responsive(
                                mobile: 32.0, tablet: 40.0, desktop: 48.0),
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -1,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, PlayerDetailState state) {
    return Padding(
      padding: context.pagePadding,
      child: context.responsive(
        mobile: _buildMobileStats(context, state),
        desktop: _buildDesktopStats(context, state),
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context, PlayerDetailState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(context,
                  icon: Icons.theater_comedy,
                  value: "${state.activeShows.length}",
                  label: "Aktif Oyun"),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildStatCard(context,
                  icon: Icons.history_edu,
                  value: "${state.pastShows.length}",
                  label: "Geçmiş"),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(context,
                  icon: Icons.people_outline,
                  value: "${state.player.collaborations.length}",
                  label: "İşbirliği"),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildStatCard(context,
                  icon: Icons.emoji_events,
                  value: "${state.player.achievements.length}",
                  label: "Başarı"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context, PlayerDetailState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context,
              icon: Icons.theater_comedy,
              value: "${state.activeShows.length}",
              label: "Aktif"),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(context,
              icon: Icons.history_edu,
              value: "${state.pastShows.length}",
              label: "Geçmiş"),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(context,
              icon: Icons.people_outline,
              value: "${state.player.collaborations.length}",
              label: "İşbirliği"),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: _buildStatCard(context,
              icon: Icons.emoji_events,
              value: "${state.player.achievements.length}",
              label: "Başarı"),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(
        context.responsive(mobile: 16.0, tablet: 20.0, desktop: 24.0),
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(context.borderRadius(0.75)),
        border: Border.all(color: context.colors.primary.withOpacity(0.2)),
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
          Icon(icon,
              color: context.colors.primary.withOpacity(0.7),
              size: context.responsive(mobile: 28.0, desktop: 36.0)),
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

  Widget _buildContentTabs(BuildContext context, PlayerDetailState state) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
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

  Widget _buildBiographyTab(BuildContext context, PlayerDetailState state) {
    return SingleChildScrollView(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (state.player.collaborations.isNotEmpty)
            _buildCollaborationsCard(context, state.player.collaborations),
        ],
      ),
    );
  }

  Widget _buildCollaborationsCard(
      BuildContext context, List<String> collaborations) {
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
                "İŞBİRLİKLERİ",
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
            children: collaborations.map((name) {
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

  Widget _buildActiveShowsTab(BuildContext context, PlayerDetailState state) {
    if (state.activeShows.isEmpty) {
      return Center(
        child: Text(
          "Aktif oyun bulunmuyor",
          style: TextStyle(color: context.colors.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return GridView.builder(
      padding: context.pagePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns(3),
        childAspectRatio: 0.7,
        crossAxisSpacing: context.gridSpacing,
        mainAxisSpacing: context.gridSpacing,
      ),
      itemCount: state.activeShows.length,
      itemBuilder: (context, index) {
        return _buildShowCard(context, state.activeShows[index], true);
      },
    );
  }

  Widget _buildShowCard(BuildContext context, Show show, bool isActive) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShowDetailPage(showId: show.id)),
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
              OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
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
              if (isActive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildArchiveTab(BuildContext context, PlayerDetailState state) {
    if (state.pastShows.isEmpty) {
      return Center(
        child: Text(
          "Arşiv bulunmuyor",
          style: TextStyle(color: context.colors.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: context.pagePadding,
      itemCount: state.pastShows.length,
      itemBuilder: (context, index) {
        return _buildArchiveItem(context, state.pastShows[index]);
      },
    );
  }

  Widget _buildArchiveItem(BuildContext context, Show show) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShowDetailPage(showId: show.id)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: context.spacing),
        padding:
            EdgeInsets.all(context.responsive(mobile: 12.0, desktop: 16.0)),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(color: context.colors.onSurface.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: context.responsive(mobile: 60.0, desktop: 80.0),
              height: context.responsive(mobile: 85.0, desktop: 110.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.borderRadius(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.borderRadius(0.5)),
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  child: OptimizedCachedImage(
                      imageUrl: show.imageUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(width: context.spacing),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            Icon(Icons.arrow_forward_ios_rounded,
                size: context.responsive(mobile: 16.0, desktop: 18.0),
                color: context.colors.primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, PlayerDetailState state) {
    if (state.player.achievements.isEmpty) {
      return Center(
        child: Text(
          "Henüz başarı kaydı bulunmuyor",
          style: TextStyle(color: context.colors.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: context.pagePadding.copyWith(top: 24),
      itemCount: state.player.achievements.length,
      itemBuilder: (context, index) {
        final item = state.player.achievements[index];
        final isLast = index == state.player.achievements.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: context.colors.error),
          SizedBox(height: context.spacing * 2),
          Text("Hata oluştu", style: context.textTheme.titleLarge),
          SizedBox(height: context.spacing),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
