import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../domain/entities/show.dart';
import '../../providers/show_provider.dart';

class ShowsSection extends ConsumerStatefulWidget {
  const ShowsSection({super.key});

  @override
  ConsumerState<ShowsSection> createState() => _ShowsSectionState();
}

class _ShowsSectionState extends ConsumerState<ShowsSection>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _scroll(final bool left) {
    if (!_scrollController.hasClients) return;
    final offset = left ? -300.0 : 300.0;
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showsProvider(isLimit: false));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            WebColors.darkBlueBackground,
            WebColors.darkBlueSurface.withOpacity(0.5),
            WebColors.darkBlueBackground,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header Animasyonları
          FadeTransition(
            opacity: _headerFadeAnimation,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: _buildHeader(context),
            ),
          ),
          SizedBox(height: context.responsive(mobile: 30.0, desktop: 60.0)),

          // State bazlı UI yönetimi
          showState.when(
            loading: () => _buildLoadingState(context),
            error: (final err, final stack) => _buildErrorState(err.toString()),
            data: (final shows) => shows.isEmpty
                ? _buildEmptyState()
                : _buildShowsCarousel(context, shows),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(final BuildContext context) => SizedBox(
        height:
            context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(mobile: 16.0, desktop: 80.0),
          ),
          itemCount: context.isMobile ? 2 : 4,
          itemBuilder: (final context, final index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: context.responsive(
                  mobile: 170.0, tablet: 220.0, desktop: 280.0),
              // Artik kendi Shimmer yapını kullanıyoruz
              child: const ShimmerLoading(borderRadius: 24),
            ),
          ),
        ),
      );

  Widget _buildHeader(final BuildContext context) => Column(
        children: [
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'OYUNLARIMIZ',
              style: TextStyle(
                fontSize: context.responsive(
                    mobile: 28.0, tablet: 40.0, desktop: 52.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: context.isMobile ? 1.5 : 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: context.responsive(mobile: 60.0, desktop: 120.0),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Sahnelediğimiz unutulmaz yapımlar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.captionSize + 2,
                color: WebColors.primaryGoldLight,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );

  Widget _buildErrorState(final String? message) => Center(
      child: Text(message ?? 'Hata',
          style: const TextStyle(color: WebColors.error)));

  Widget _buildEmptyState() => const Center(
      child: Text('Oyun yok', style: TextStyle(color: Colors.white70)));

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: WebColors.primaryGold,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
          child: Icon(icon, color: WebColors.darkBlueBackground, size: 20),
        ),
      );

  Widget _buildShowsCarousel(
      final BuildContext context, final List<Show> shows) {
    final cardHeight =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    return SizedBox(
      height: cardHeight + 60,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: context.responsive(mobile: 16.0, desktop: 80.0),
            ),
            itemCount: shows.length,
            itemBuilder: (final context, final index) => Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: context.isMobile ? 8 : 12),
              child: _ShowCard(
                imageUrl: shows[index].imageUrl,
                gameName: shows[index].name,
                index: index,
                showId: shows[index].id,
              ),
            ),
          ),
          if (!context.isMobile) ...[
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _buildNavButton(
                      Icons.arrow_back_ios, () => _scroll(true))),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _buildNavButton(
                      Icons.arrow_forward_ios, () => _scroll(false))),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHOW CARD OPTIMIZED (ValueNotifier & OptimizedImage)
// -----------------------------------------------------------------------------

class _ShowCard extends StatefulWidget {
  final String showId;
  final String imageUrl;
  final String gameName;
  final int index;

  const _ShowCard({
    required this.showId,
    required this.imageUrl,
    required this.gameName,
    required this.index,
  });

  @override
  State<_ShowCard> createState() => _ShowCardState();
}

class _ShowCardState extends State<_ShowCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _isHovered.dispose();
    super.dispose();
  }

  void _navigateToDetails() =>
      NavigationHandler.goToShow(context, widget.showId, widget.gameName);

  @override
  Widget build(final BuildContext context) {
    // Sabit İçerik (Hover sırasında rebuild olmaz)
    final Widget staticCardContent = _buildStaticContent(context);

    // Hover/Active Wrapper
    final Widget interactiveWidget = context.isMobile
        ? Listener(
            onPointerDown: (final _) => _isHovered.value = true,
            onPointerUp: (final _) => _isHovered.value = false,
            onPointerCancel: (final _) => _isHovered.value = false,
            child: _buildAnimatedContainer(context, staticCardContent),
          )
        : MouseRegion(
            onEnter: (final _) => _isHovered.value = true,
            onExit: (final _) => _isHovered.value = false,
            cursor: SystemMouseCursors.click,
            child: _buildAnimatedContainer(context, staticCardContent),
          );

    return GestureDetector(
      onTap: _navigateToDetails,
      child: AnimatedBuilder(
        animation: _entryAnimation,
        builder: (final context, final child) {
          final safeValue = _entryAnimation.value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: safeValue,
            child: Opacity(opacity: safeValue, child: child),
          );
        },
        child: interactiveWidget,
      ),
    );
  }

  Widget _buildAnimatedContainer(
      final BuildContext context, final Widget child) {
    final width =
        context.responsive(mobile: 170.0, tablet: 220.0, desktop: 280.0);
    final height =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    return ValueListenableBuilder<bool>(
      valueListenable: _isHovered,
      builder: (final context, final isActive, final staticChild) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          transform: Matrix4.identity()
            ..translate(0.0, isActive ? -10.0 : 0.0)
            ..scale(isActive ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.isMobile ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? WebColors.primaryGold.withOpacity(0.5)
                    : Colors.black.withOpacity(0.4),
                blurRadius: isActive ? 25 : 15,
                spreadRadius: isActive ? 2 : 0,
                offset: Offset(0, isActive ? 12 : 8),
              ),
            ],
          ),
          child: staticChild,
        );
      },
      child: child,
    );
  }

  Widget _buildStaticContent(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(context.isMobile ? 16 : 24),
        child: Stack(
          children: [
            // 1. GÖRSEL (Optimized)
            Positioned.fill(
              child: OptimizedCachedImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                width: 300, // Yaklaşık max genişlik
                height: 400,
              ),
            ),

            // 2. GRADIENT & BORDER (ValueListenableBuilder ile güncellenir)
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovered,
                builder: (final context, final isActive, final _) =>
                    AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isActive
                          ? WebColors.primaryGold
                          : WebColors.primaryGold.withOpacity(0.3),
                      width: isActive ? 3 : 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(isActive ? 0.9 : 0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. METİN VE DETAY BUTONU
            Positioned(
              left: context.responsive(mobile: 10.0, desktop: 16.0),
              right: context.responsive(mobile: 10.0, desktop: 16.0),
              bottom: context.responsive(mobile: 12.0, desktop: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          context.responsive(mobile: 6.0, desktop: 10.0),
                      vertical: context.responsive(mobile: 3.0, desktop: 5.0),
                    ),
                    decoration: BoxDecoration(
                      gradient: WebColors.goldGradient,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: WebColors.primaryGold.withOpacity(0.4),
                            blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      'OYUN',
                      style: TextStyle(
                        fontSize:
                            context.responsive(mobile: 9.0, desktop: 11.0),
                        fontWeight: FontWeight.w900,
                        color: WebColors.darkBlueBackground,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: context.responsive(mobile: 6.0, desktop: 10.0)),
                  Text(
                    widget.gameName,
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 15.0, tablet: 18.0, desktop: 22.0),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8)
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Detay butonu sadece hover olunca görünür
                  ValueListenableBuilder<bool>(
                    valueListenable: _isHovered,
                    builder: (final context, final isActive, final _) =>
                        AnimatedCrossFade(
                      firstChild:
                          const SizedBox(height: 0, width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'Detayları Gör',
                              style: TextStyle(
                                fontSize: context.captionSize,
                                color: WebColors.primaryGoldLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                color: WebColors.primaryGold,
                                size: context.iconSmall),
                          ],
                        ),
                      ),
                      crossFadeState: isActive
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
