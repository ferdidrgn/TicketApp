import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'home_asset_video_provider.dart';

class HeroVideoSection extends ConsumerStatefulWidget {
  final bool startAnimations;

  const HeroVideoSection({
    super.key,
    this.startAnimations = false,
  });

  @override
  ConsumerState<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends ConsumerState<HeroVideoSection>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseController;

  // ignore: unused_field
  bool _videoPlayAttempted = false;

  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentSlide;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardOpacity;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    );

    _cardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    if (widget.startAnimations) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant final HeroVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.startAnimations && widget.startAnimations) {
      _controller.forward(from: 0);
      _attemptVideoPlay();
    }
  }

  void _attemptVideoPlay() {
    if (!_videoPlayAttempted) {
      _videoPlayAttempted = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(homeAssetsProvider.notifier).playVideo();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final assetsState = ref.watch(homeAssetsProvider);
    final controller = assetsState.videoController;
    final isReady = assetsState.isVideoReady;
    final hasVideo = controller != null && controller.value.isInitialized;

    if (hasVideo && !controller.value.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) ref.read(homeAssetsProvider.notifier).playVideo();
      });
    }

    return SizedBox(
      height: context.screenHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. ZEMİN (Koyu Tema)
          Container(color: const Color(0xFF050505)),

          // 2. MASAÜSTÜ GÖRÜNÜMÜ (Mevcut hali koruyoruz)
          if (!context.isMobile) ...[
            Positioned.fill(
              child: _buildDesktopCinematicVideo(controller, hasVideo),
            ),
            Positioned.fill(
              child: _buildDesktopContent(context),
            ),
            _buildIntegratedGlassCard(context),
            if (isReady)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    opacity: widget.startAnimations ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Text(
                          'KEŞFETMEK İÇİN KAYDIR',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            letterSpacing: 4,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down,
                            color: WebColors.primaryGold.withOpacity(0.6)),
                      ],
                    ),
                  ),
                ),
              ),
          ],

          // 3. MOBİL GÖRÜNÜM (YENİ EDITORIAL TASARIM)
          if (context.isMobile)
            _buildMobileEditorialLayout(context, controller, hasVideo),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🖥️ DESKTOP: SİNEMATİK VİDEO MASKESİ
  // ===========================================================================
  Widget _buildDesktopCinematicVideo(
      final VideoPlayerController? controller, final bool hasVideo) {
    if (!hasVideo) return const SizedBox();

    return Row(
      children: [
        const Spacer(flex: 2), // Sol tarafı boş bırak (Yazılar için)
        Expanded(
          flex: 5,
          child: ShaderMask(
            shaderCallback: (final Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent, // Sol taraf erimiş
                  Colors.black.withOpacity(0.5),
                  Colors.black, // Sağ taraf net
                ],
                stops: const [0.0, 0.3, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🖋️ DESKTOP: YAZI İÇERİĞİ
  // ===========================================================================
  Widget _buildDesktopContent(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (final context, final child) {
                return Opacity(
                  opacity: _contentOpacity.value,
                  child: Transform.translate(
                    offset: Offset(_contentSlide.value, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 2,
                              width: 40,
                              color: WebColors.primaryGold,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'SAHNE SANATLARI SEZONU',
                              style: TextStyle(
                                color: WebColors.primaryGold,
                                fontSize: 14,
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'HİKAYELER\nGERÇEĞE\nDÖNÜŞÜYOR',
                          style: TextStyle(
                            fontSize: 96,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(4, 4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 500,
                          child: Text(
                            'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu sizi bekliyor.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎫 DESKTOP: KOYU & ŞIK BİLDİRİM KARTI
  // ===========================================================================
  Widget _buildIntegratedGlassCard(final BuildContext context) {
    return Positioned(
      right: 80,
      bottom: 80,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          return Opacity(
            opacity: _cardOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _cardSlide.value),
              child: child,
            ),
          );
        },
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WebColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YAKINDA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.notifications_active_outlined,
                          color: WebColors.primaryGold.withOpacity(0.8),
                          size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'METAFOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Times New Roman',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '27 Haziran 2025 • 20:00',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Altunizade Kültür Merkezi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          const url =
                              'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WebColors.primaryGold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('BİLET AL & KONUM',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎫 MOBİL KART: WEB TASARIMININ AYNISI (Responsive)
  Widget _buildMobileCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.9), // Koyu ve net zemin
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst Kısım: Etiket ve İkon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YAKINDA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Icon(Icons.notifications_active_outlined,
                  color: WebColors.primaryGold.withOpacity(0.8), size: 18),
            ],
          ),
          const SizedBox(height: 12),

          // Başlık: Times New Roman
          Text(
            'METAFOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              // Mobilde biraz daha küçük ama hala büyük
              fontWeight: FontWeight.w900,
              fontFamily: 'Times New Roman',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          // Detaylar
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '27 Haziran • 20:00',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                'Altunizade Kültür Merkezi',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Altın Buton (Tam Genişlik)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () async {
                  const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebColors.primaryGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('BİLET AL & KONUM',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT: YENİ HİYERARŞİ (Başlık Sol Üst, Yazı Alt Orta, Kart En Alt)
  // ===========================================================================
  Widget _buildMobileEditorialLayout(
    BuildContext context,
    VideoPlayerController? controller,
    bool hasVideo,
  ) {
    return Stack(
      children: [
        // 1. VİDEO: Tam Ekran Arka Plan
        Positioned.fill(
          child: hasVideo
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              : Container(color: Colors.black),
        ),

        // 2. GRADIENT: Okunabilirlik için
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  // Üst kısım daha koyu (Başlık için)
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  // Alt kısım koyu (Yazı ve Kart için)
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // 3. SOL ÜST: CANLI "ON AIR" ETİKETİ
        Positioned(
          top: 60,
          left: 24,
          child: Row(
            children: [
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: WebColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: WebColors.error, blurRadius: 6)
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SEZON TANITIMI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // 4. SAĞ ÜST: DİKEY İMZA
        Positioned(
          top: 60,
          right: 24,
          child: RotatedBox(
            quarterTurns: 1,
            child: Text(
              'TIYATROL 2025',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // 5. SOL ÜST: ANA BAŞLIK (ON AIR'in Altında)
        Positioned(
          top: 90, // ON AIR'den biraz aşağıda
          left: 24,
          right: 60, // Sağdaki imzaya çarpmaması için
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _contentOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: child,
                ),
              );
            },
            child: Text(
              'HİKAYELER\nGERÇEĞE\nDÖNÜŞÜYOR',
              style: TextStyle(
                fontSize: 42,
                // Mobilde biraz daha dengeli boyut
                height: 0.95,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. ALT ORTA: UZUN AÇIKLAMA METNİ (Kartın Üzerinde)
        Positioned(
          bottom: 280,
          // Kartın yüksekliğine göre ayarlandı (Kartın üstünde kalacak)
          left: 30,
          right: 30,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _contentOpacity.value,
                // Başlıktan biraz daha geç gelsin diye slide değerini tersledik
                child: Transform.translate(
                  offset: Offset(0, -_contentSlide.value / 2),
                  child: child,
                ),
              );
            },
            child: Text(
              'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu sizi bekliyor.',
              textAlign: TextAlign.center, // Ortalanmış
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(1.0),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]),
            ),
          ),
        ),

        // 7. EN ALT: BİLDİRİM KARTI (Sabit)
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _cardOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: child,
                ),
              );
            },
            child: _buildMobileCard(context),
          ),
        ),
      ],
    );
  }
}
