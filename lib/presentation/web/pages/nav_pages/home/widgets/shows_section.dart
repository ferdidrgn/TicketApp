import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    Future.microtask(() {
      final state = ref.read(showProvider);
      if (!state.isLoading && state.dataList == null)
        ref.read(showProvider.notifier).loadShows(false);
    });
    // Animasyonu başlat
    _headerController.forward();
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
          FadeTransition(
            opacity: _headerFadeAnimation,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: _buildHeader(context),
            ),
          ),
          SizedBox(height: context.responsive(mobile: 40, desktop: 60)),
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

  // _buildHeader, _buildLoadingState, _buildErrorState, _buildEmptyState, _buildNavButton
  // Metotları orijinal kodunuzla birebir aynı kalabilir, buraya tekrar kopyalamadım.
  // Sadece kısalık olması açısından _buildShowsCarousel ve aşağısını ekliyorum.

  Widget _buildHeader(final BuildContext context) {
    return Column(
      children: [
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
    return Center(child: Text(message ?? 'Hata'));
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Oyun yok'));
  }

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: WebColors.primaryGold, shape: BoxShape.circle),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildShowsCarousel(
      final BuildContext context, final List<Show> shows) {
    return SizedBox(
      height: 450,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              top: 15.0,
              bottom: 15.0,
              left: context.responsive(mobile: 16.0, desktop: 80.0),
              right: context.responsive(mobile: 16.0, desktop: 80.0),
            ),
            itemCount: shows.length,
            itemBuilder: (final context, final index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // İsim değişikliği: _ShowCard3D -> _ShowCard
                child: _ShowCard(
                  imageUrl: shows[index].imageUrl ?? '',
                  gameName: shows[index].name ?? '',
                  index: index,
                  showId: shows[index].id ?? '',
                ),
              );
            },
          ),
          // Navigasyon butonları mantığı aynı kalabilir...
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
}

class _ShowCard extends StatefulWidget {
  final String showId; // YENİ: ID parametresi eklendi
  final String imageUrl;
  final String gameName;
  final int index;

  const _ShowCard({
    required this.showId, // YENİ
    required this.imageUrl,
    required this.gameName,
    required this.index,
  });

  @override
  State<_ShowCard> createState() => _ShowCardState();
}

class _ShowCardState extends State<_ShowCard>
    with SingleTickerProviderStateMixin {
  bool _isActive = false; // Efektin aktif olup olmadığını tutar
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    // Giriş animasyonu ayarları
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

  void _navigateToDetails() {
    // YÖNTEM A: İsim ile gitmek (Daha güvenli)
    // URL otomatik olarak /show-details/oyunIDsi şekline dönüşür
    //context.pushNamed('showDetail', pathParameters: {'id': widget.showId},);

    // YÖNTEM B: Direkt URL yazarak gitmek (Alternatif)
    // context.go('/show-details/${widget.showId}');

    // pushNamed yerine goNamed kullanıyoruz
    // Bu, tarayıcı adres çubuğunu kesin olarak günceller.
    context.goNamed(
      'showDetail',
      pathParameters: {'id': widget.showId},
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = context.isMobile;
    Widget cardWidget = _buildCard(context);

    // Sayfa ilk açıldığındaki giriş animasyonu (Fade + Scale)
    cardWidget = AnimatedBuilder(
      animation: _entryAnimation,
      builder: (final context, final child) {
        final safeValue = _entryAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: safeValue,
          child: Opacity(opacity: safeValue, child: child),
        );
      },
      child: cardWidget,
    );

    // Tıklama olayını (OnTap) en dışa GestureDetector koyarak yakalıyoruz.
    // Bu sayede Listener (Animation) ve Tap (Navigation) karışmaz.
    return GestureDetector(
      onTap: _navigateToDetails,
      child: isMobile
          ? Listener(
              // Mobil animasyon tetikleyicileri
              onPointerDown: (final _) => setState(() => _isActive = true),
              onPointerUp: (final _) => setState(() => _isActive = false),
              onPointerCancel: (final _) => setState(() => _isActive = false),
              child: cardWidget,
            )
          : MouseRegion(
              // Masaüstü animasyon tetikleyicileri
              onEnter: (final _) => setState(() => _isActive = true),
              onExit: (final _) => setState(() => _isActive = false),
              cursor: SystemMouseCursors.click,
              child: cardWidget,
            ),
    );
  }

  Widget _buildCard(final BuildContext context) {
    // Hover/Dokunma anındaki efektler
    // Scale 1.05 çok büyük gelirse 1.02 veya 1.03 yapabilirsin,
    // scroll sırasında takılma hissi vermemesi için.
    return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isActive ? -10.0 : 0.0) // Yukarı kalkma
          ..scale(_isActive ? 1.02 : 1.0),
        // Hafif büyüme (Mobilde çok büyütmemek daha iyidir)
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
                blurRadius: _isActive ? 30 : 20,
                spreadRadius: _isActive ? 2 : 0,
                offset: Offset(0, _isActive ? 15 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                _buildImage(),
                _buildGradientOverlay(),
                _buildBorder(),
                _buildContent(context),
              ],
            ),
          ),
        ));
  }

  Widget _buildImage() {
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.cover,
        placeholder: (final context, final url) => Container(
          color: WebColors.darkBlueSurface,
          child: const Center(
              child: CircularProgressIndicator(color: WebColors.primaryGold)),
        ),
        errorWidget: (final context, final url, final error) => Container(
          color: WebColors.darkBlueSurface,
          child: const Icon(Icons.theater_comedy,
              size: 64, color: WebColors.primaryGold),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  Widget _buildContent(final BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.5),
                    blurRadius: 10),
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
          Text(
            widget.gameName,
            style: TextStyle(
              fontSize: context.bodySize + 2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward,
                      color: WebColors.primaryGold, size: 18),
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
            crossFadeState: _isActive
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
