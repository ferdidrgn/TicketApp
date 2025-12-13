import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
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

  // 📸 FALLBACK GÖRSEL (Asset)
  final String _fallbackImage = 'assets/images/main_theatre.png';

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

// ✅ 2. VİDEO KONTROL MANTIĞI
  // Görünürlük değişince bu fonksiyon çalışacak
  void _handleVisibilityChanged(
      final VisibilityInfo info, final VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) return;

    // visibleFraction: 0.0 (Hiç görünmüyor) ile 1.0 (Tamamen görünüyor) arası değer alır.
    if (info.visibleFraction == 0) {
      // Video ekrandan tamamen çıktıysa DURDUR
      if (controller.value.isPlaying) {
        controller.pause();
        debugPrint(
            '🙈 Video ekrandan çıktı, durduruldu (Performans tasarrufu).');
      }
    } else {
      // Video ekrana girdiyse (veya bir kısmı görünüyorsa) OYNAT
      if (!controller.value.isPlaying) {
        controller.play();
        debugPrint('👁️ Video ekrana girdi, oynatılıyor.');
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final assetsState = ref.watch(homeAssetsProvider);
    final controller = assetsState.videoController;
    final isReady = assetsState.isVideoReady;
    final hasVideo = controller != null && controller.value.isInitialized;

    // ✅ 3. SARMALAMA İŞLEMİ
    return VisibilityDetector(
      key: const Key('hero-video-visibility-key'),
      // Her detector için benzersiz key şart
      onVisibilityChanged: (final info) =>
          _handleVisibilityChanged(info, controller),
      child: SizedBox(
        height: context.screenHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // 1. ZEMİN (Koyu Tema)
            Container(color: const Color(0xFF050505)),

            // 2. MASAÜSTÜ GÖRÜNÜMÜ
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

            // 3. MOBİL GÖRÜNÜM
            if (context.isMobile)
              _buildMobileEditorialLayout(context, controller, hasVideo),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT: RESİM/VİDEO TAM EKRAN + YAZILAR DOĞRU YERDE
  // ===========================================================================
  Widget _buildMobileEditorialLayout(
    final BuildContext context,
    final VideoPlayerController? controller,
    final bool hasVideo,
  ) {
    return Stack(
      children: [
        // KATMAN 1: FALLBACK RESİM (En Altta, Tam Ekran)
        Positioned.fill(
          child: Image.asset(
            _fallbackImage,
            fit: BoxFit.cover,
            errorBuilder: (final context, final error, final stackTrace) =>
                Container(color: const Color(0xFF1A1A1A)),
          ),
        ),

        // KATMAN 2: VİDEO (Varsa Resmin Üstüne Biner, Tam Ekran)
        if (hasVideo)
          Positioned.fill(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),

        // KATMAN 3: KARARTMA GRADIENT
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6), // Başlık için koyu üst
                  Colors.transparent,
                  Colors.black.withOpacity(0.6), // Yazı için koyu alt
                  Colors.black.withOpacity(0.95), // Kart için tam koyu
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // KATMAN 4: İÇERİKLER

        // 4.1 SOL ÜST: CANLI "ON AIR" ETİKETİ
        Positioned(
          top: 60,
          left: 24,
          child: Row(
            children: [
              hasVideo && controller!.value.isPlaying
                  ? FadeTransition(
                      opacity: _pulseController,
                      child: _buildRedDot(),
                    )
                  : _buildRedDot(),
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

        // 4.2 SAĞ ÜST: DİKEY İMZA
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

        // 4.3 SOL ÜST: ANA BAŞLIK (On Air'in Altında)
        // BURASI DÜZELTİLDİ: Artık ortaya değil, sol yukarıya sabitli.
        Positioned(
          top: 90,
          left: 24,
          right: 60, // Sağdaki yazıya çarpmaması için
          child: AnimatedBuilder(
            animation: _controller,
            builder: (final context, final child) {
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
              textAlign: TextAlign.left, // Sola hizalı
              style: TextStyle(
                fontSize: 42,
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

        // 4.4 ALT ORTA: UZUN AÇIKLAMA METNİ (Kartın Üzerinde)
        // BURASI AYRILDI: Başlıktan bağımsız olarak aşağıda ortalı.
        Positioned(
          bottom: 270, // Kartın yüksekliğine göre yukarıda
          left: 30,
          right: 30,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (final context, final child) {
              return Opacity(
                opacity: _contentOpacity.value,
                // Başlık yukarıdan, bu aşağıdan gelsin diye ters efekt
                child: Transform.translate(
                  offset: Offset(0, -_contentSlide.value),
                  child: child,
                ),
              );
            },
            child: Text(
              'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu sizi bekliyor.',
              textAlign: TextAlign.center, // Ortalanmış metin
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
                ],
              ),
            ),
          ),
        ),

        // 4.5 EN ALT: BİLDİRİM KARTI (Sabit)
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
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
            child: _buildMobileCard(context),
          ),
        ),
      ],
    );
  }

  // 🎫 MOBİL KART (Web Tarzı)
  Widget _buildMobileCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.9),
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
          Text(
            'METAFOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
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
  // 🖥️ DESKTOP: SİNEMATİK VİDEO MASKESİ + RESİM
  // ===========================================================================
  Widget _buildDesktopCinematicVideo(
      final VideoPlayerController? controller, final bool hasVideo) {
    return Row(
      children: [
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child: ShaderMask(
            shaderCallback: (final Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                  Colors.black,
                ],
                stops: const [0.0, 0.3, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Resim (Altta)
                  Image.asset(
                    _fallbackImage,
                    fit: BoxFit.cover,
                  ),

                  // 2. Video (Varsa Üstte)
                  if (hasVideo)
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: controller!.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                ],
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
  // 🎫 DESKTOP: BİLDİRİM KARTI
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

  Widget _buildRedDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: WebColors.error,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: WebColors.error, blurRadius: 6)],
      ),
    );
  }
}
