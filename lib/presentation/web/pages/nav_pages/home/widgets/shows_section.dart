import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../data/providers/show/show_provider.dart';
import '../../../../../../domain/entities/show.dart';
import 'dart:math' as math;

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

    // Header animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      final state = ref.read(showProvider);
      if (!state.isLoading && state.dataList == null) {
        ref.read(showProvider.notifier).loadShows(false);
      }
      _headerController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _scroll(final bool left) {
    final offset = left ? -350.0 : 350.0;
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);

    return Container(
      width: double.infinity,
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(vertical: 60),
        desktop: const EdgeInsets.symmetric(vertical: 100),
      ),
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
          // Animated Header
          FadeTransition(
            opacity: _headerFadeAnimation,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: _buildHeader(context),
            ),
          ),

          SizedBox(height: context.responsive(mobile: 40, desktop: 60)),

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

  Widget _buildHeader(final BuildContext context) {
    return Column(
      children: [
        // Main Title
        ShaderMask(
          shaderCallback: (final bounds) =>
              WebColors.goldGradient.createShader(bounds),
          child: Text(
            'OYUNLARIMIZ',
            style: TextStyle(
              fontSize: context.responsive(mobile: 36.0, desktop: 56.0),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Decorative line
        Container(
          height: 4,
          width: 100,
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

        const SizedBox(height: 20),

        // Subtitle
        Text(
          'Sahnelediğimiz unutulmaz yapımlar',
          style: TextStyle(
            fontSize: context.bodySize + 2,
            color: WebColors.primaryGoldLight,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(final BuildContext context) {
    return SizedBox(
      height: 380,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 16.0, desktop: 80.0),
        ),
        itemCount: context.isMobile ? 2 : 4,
        itemBuilder: (final context, final index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: context.responsive(mobile: 220.0, desktop: 260.0),
            height: 360,
            child: const ShimmerLoading(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(final String? message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: WebColors.error, width: 2),
            ),
            child: const Icon(
              Icons.error_outline,
              color: WebColors.error,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message ?? 'Bir hata oluştu',
            style: TextStyle(
              color: WebColors.error,
              fontSize: context.bodySize,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient.scale(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.theater_comedy,
              color: WebColors.darkBlueBackground,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz oyun eklenmemiş',
            style: TextStyle(
              color: WebColors.textSecondary,
              fontSize: context.bodySize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowsCarousel(
      final BuildContext context, final List<Show> shows) {
    return SizedBox(
      height: 420,
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
                child: _ShowCard3D(
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
                  Icons.arrow_forward_ios,
                  () => _scroll(false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: WebColors.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: WebColors.darkBlueBackground,
            size: 24,
          ),
        ),
      ),
    );
  }
}
// ... (Diğer importlar ve kodlar)

/// 3D Show Card with perspective transform and hover effects
class _ShowCard3D extends StatefulWidget {
  final String imageUrl;
  final String gameName;
  final int index;

  const _ShowCard3D({
    required this.imageUrl,
    required this.gameName,
    required this.index,
  });

  @override
  State<_ShowCard3D> createState() => _ShowCard3DState();
}

class _ShowCard3DState extends State<_ShowCard3D>
    with SingleTickerProviderStateMixin {
  bool _isActive = false; // Hover veya Dokunma durumu
  Offset _touchPosition = Offset.zero; // Pozisyonu tutar
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    // ... (Animasyon başlatma kısmı aynı)
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
    super.dispose();
  }

  // Pozisyon güncelleme metodu aynı
  void _updatePosition(final Offset localPosition) {
    // Mobil/Masaüstü ayrımı yapmadan boyutları dinamik alıyoruz
    final Size size = Size(
      context.responsive(mobile: 220.0, desktop: 260.0),
      360,
    );

    setState(() {
      _touchPosition = Offset(
        (localPosition.dx - size.width / 2) / size.width,
        (localPosition.dy - size.height / 2) / size.height,
      );
    });
  }

  // **YENİ:** Dokunmatik (Pointer) başlangıcı (Kaydırma başlasa bile aktif kalır)
  void _handlePointerDown(final PointerEvent event) {
    if (event is PointerDownEvent) {
      setState(() {
        _isActive = true;
        _updatePosition(event.localPosition);
      });
    }
    // Mobil cihazda kaydırırken 3D dönme efektini devam ettirmek isterseniz:
    // if (event is PointerMoveEvent && _isActive) {
    //   _updatePosition(event.localPosition);
    // }
  }

  // **YENİ:** Dokunmatik (Pointer) bitişi (Parmak ekrandan kalktığında)
  void _handlePointerUp(final PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      setState(() {
        _isActive = false;
        _touchPosition = Offset.zero;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = context.isMobile;

    Widget cardWidget = _buildCard(context);

    // Animasyon sarmalayıcı (TweenAnimationBuilder'dan AnimatedBuilder'a dönüştürüldü)
    cardWidget = AnimatedBuilder(
      animation: _entryAnimation,
      builder: (final context, final child) {
        final safeValue = _entryAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: safeValue,
          child: Opacity(
            opacity:safeValue,
            child: child,
          ),
        );
      },
      child: cardWidget,
    );

    if (isMobile) {
      // MOBİL: Listener ile dokunma olaylarını yakala
      // Listener, Gesture Detector'dan farklı olarak, kaydırma başladığında olayı durdurmaz.
      return Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: cardWidget,
      );
    } else {
      // MASAÜSTÜ: MouseRegion ile hover olaylarını yakala
      return MouseRegion(
        onEnter: (final _) => setState(() => _isActive = true),
        onExit: (final _) => setState(() {
          _isActive = false;
          _touchPosition = Offset.zero;
        }),
        onHover: (final event) {
          if (_isActive) {
            _updatePosition(event.localPosition);
          }
        },
        cursor: SystemMouseCursors.click,
        child: cardWidget,
      );
    }
  }

  // ... (Geri kalan _buildCard, _buildImage, _buildGradientOverlay, vs. metodları aynı kalır)

  Widget _buildShineEffect() {
    return Positioned(
      // 3D Dönme ve Parlama efekti için _touchPosition kullanılıyor
      left: _touchPosition.dx * 100,
      top: _touchPosition.dy * 100,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(final BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'OYUN',
              style: TextStyle(
                fontSize: context.captionSize - 1,
                fontWeight: FontWeight.w900,
                color: WebColors.darkBlueBackground,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            widget.gameName,
            style: TextStyle(
              fontSize: context.bodySize + 2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 10),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (_isActive) ...[
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: WebColors.primaryGold,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Detayları Gör',
                    style: TextStyle(
                      fontSize: context.captionSize,
                      color: WebColors.primaryGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(final BuildContext context) {
    // Calculate 3D transform
    final rotateX = _isActive ? -_touchPosition.dy * 0.2 : 0.0;
    final rotateY = _isActive ? _touchPosition.dx * 0.2 : 0.0;
    final scale = _isActive ? 1.05 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateX(rotateX)
        ..rotateY(rotateY)
        ..translate(0.0, _isActive ? -15.0 : 0.0) // yukarı kayma
        ..scale(scale),
      child: Container(
        width: context.responsive(mobile: 220.0, desktop: 260.0),
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _isActive
                  ? WebColors.primaryGold.withOpacity(0.6)
                  : Colors.black.withOpacity(0.4),
              blurRadius: _isActive ? 40 : 20,
              spreadRadius: _isActive ? 5 : 0,
              offset: Offset(0, _isActive ? 20 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Image
              _buildImage(),

              // Gradient Overlay
              _buildGradientOverlay(),

              // Shine effect on hover/tap
              if (_isActive) _buildShineEffect(),

              // Border
              _buildBorder(),

              // Content
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Positioned.fill(
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
        errorWidget: (final context, final url, final error) => Container(
          color: WebColors.darkBlueSurface,
          child: const Icon(
            Icons.theater_comedy,
            size: 64,
            color: WebColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(_isActive ? 0.95 : 0.8),
            ],
            stops: const [0.3, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBorder() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isActive
                ? WebColors.primaryGold
                : WebColors.primaryGold.withOpacity(0.3),
            width: _isActive ? 3 : 2,
          ),
        ),
      ),
    );
  }
}
