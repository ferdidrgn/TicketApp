import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../data/providers/show/show_provider.dart';
import '../../../../../../domain/entities/show.dart';

class ShowsSection extends ConsumerStatefulWidget {
  const ShowsSection({super.key});

  @override
  ConsumerState<ShowsSection> createState() => _ShowsSectionState();
}

class _ShowsSectionState extends ConsumerState<ShowsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      final state = ref.read(showProvider);
      if (!state.isLoading && state.dataList == null) {
        ref.read(showProvider.notifier).loadShows(false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(final bool left) {
    final offset = left ? -300.0 : 300.0;
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);

    return Container(
      width: double.infinity,
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(vertical: 40),
        desktop: const EdgeInsets.symmetric(vertical: 60),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            WebColors.darkBlueBackground,
            WebColors.darkBlueSurface,
            WebColors.darkBlueBackground,
          ],
        ),
      ),
      child: Column(
        children: [
          // Başlık
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'OYUNLARIMIZ',
              style: TextStyle(
                fontSize: context.responsive(mobile: 32.0, desktop: 48.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Sahnelediğimiz unutulmaz yapımlar',
            style: TextStyle(
              fontSize: context.bodySize,
              color: WebColors.primaryGoldLight,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 40),

          // Shows Content
          if (showState.isLoading)
            _buildLoadingState(context)
          else if (showState.hasError)
            _buildErrorState(showState.errorMessage)
          else if (showState.isListNullOrEmpty)
            _buildEmptyState()
          else
            _buildShowsCarousel(context, showState.dataList!.cast<Show>()),
        ],
      ),
    );
  }

  Widget _buildLoadingState(final BuildContext context) {
    return SizedBox(
      height: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          context.isMobile ? 2 : 4,
          (final index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: context.responsive(mobile: 200.0, desktop: 240.0),
              height: 300,
              child: const ShimmerLoading(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(final String? message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: WebColors.error, size: 64),
          const SizedBox(height: 16),
          Text(
            message ?? 'Bir hata oluştu',
            style: const TextStyle(color: WebColors.error, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.theater_comedy,
              color: WebColors.textSecondary, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Henüz oyun eklenmemiş',
            style: TextStyle(color: WebColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShowsCarousel(
      final BuildContext context, final List<Show> shows) {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          // Carousel
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(mobile: 16.0, desktop: 80.0),
            ),
            itemCount: shows.length,
            itemBuilder: (final context, final index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _ShowCard(
                  imageUrl: shows[index].imageUrl ?? '',
                  gameName: shows[index].name ?? '',
                  index: index,
                ),
              );
            },
          ),

          // Navigation Buttons
          if (!context.isMobile) ...[
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child:
                    _buildNavButton(Icons.arrow_back_ios, () => _scroll(true)),
              ),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                    Icons.arrow_forward_ios, () => _scroll(false)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: WebColors.goldGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: WebColors.darkBlueBackground),
        iconSize: 24,
      ),
    );
  }
}

class _ShowCard extends StatefulWidget {
  final String imageUrl;
  final String gameName;
  final int index;

  const _ShowCard({
    required this.imageUrl,
    required this.gameName,
    required this.index,
  });

  @override
  State<_ShowCard> createState() => _ShowCardState();
}

class _ShowCardState extends State<_ShowCard> {
  bool _isHovered = false;

  @override
  Widget build(final BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (final context, final value, final child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: MouseRegion(
              onEnter: (final _) => setState(() => _isHovered = true),
              onExit: (final _) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: context.responsive(mobile: 200.0, desktop: 240.0),
                height: 320,
                transform: Matrix4.identity()
                  ..translate(0.0, _isHovered ? -10.0 : 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isHovered
                        ? WebColors.primaryGold
                        : WebColors.primaryGold.withOpacity(0.3),
                    width: _isHovered ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? WebColors.primaryGold.withOpacity(0.5)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: _isHovered ? 25 : 15,
                      spreadRadius: _isHovered ? 5 : 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Image
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (final context, final url) => Container(
                            color: WebColors.darkBlueSurface,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: WebColors.primaryGold,
                              ),
                            ),
                          ),
                          errorWidget:
                              (final context, final url, final error) =>
                                  Container(
                            color: WebColors.darkBlueSurface,
                            child: const Icon(
                              Icons.theater_comedy,
                              size: 64,
                              color: WebColors.primaryGold,
                            ),
                          ),
                        ),
                      ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black
                                    .withOpacity(_isHovered ? 0.9 : 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Title
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: WebColors.goldGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OYUN',
                                style: TextStyle(
                                  fontSize: context.captionSize - 2,
                                  fontWeight: FontWeight.w900,
                                  color: WebColors.darkBlueBackground,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.gameName,
                              style: TextStyle(
                                fontSize: context.bodySize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 8),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
