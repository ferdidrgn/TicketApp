import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../providers/home_asset_video_provider.dart';

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

  // Video tetikleme kontrolü
  bool _videoInitTriggered = false;

  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentSlide;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardOpacity;

  // 📸 FALLBACK GÖRSEL
  final String _fallbackImage = 'assets/images/main_theatre.png';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 1. Animasyon Controllerları
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Animasyon Tanımları
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

    // 🚀 DÜZELTME: Sayfa açılır açılmaz videoyu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndPlayVideo();

      if (widget.startAnimations) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant final HeroVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animasyon durumu değişirse tetikle
    if (!oldWidget.startAnimations && widget.startAnimations) {
      _controller.forward(from: 0);
      _initializeAndPlayVideo();
    }
  }

  // 🚀 VİDEO BAŞLATMA MANTIĞI (GÜNCELLENDİ)
  void _initializeAndPlayVideo() {
    if (_videoInitTriggered) return;
    _videoInitTriggered = true;

    // Provider üzerindeki videoyu başlatıyoruz
    final notifier = ref.read(homeAssetsProvider.notifier);

    // Önce initialize et (varsa metodun), sonra oynat
    // Not: initializeVideo metodun yoksa playVideo yeterli olabilir,
    // ancak playVideo'nun içini kontrol etmelisin.
    notifier.initializeVideo();

    // Küçük bir gecikme ile oynatmayı garantiye al (özellikle web için)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        notifier.playVideo();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // GÖRÜNÜRLÜK DEĞİŞİKLİĞİ
  void _handleVisibilityChanged(
      final VisibilityInfo info, final VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) return;

    if (info.visibleFraction == 0) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    } else {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final assetsState = ref.watch(homeAssetsProvider);
    final controller = assetsState.videoController;
    // Video hazır mı? VEYA controller initialize olmuş mu?
    final hasVideo = controller != null && controller.value.isInitialized;

    return VisibilityDetector(
      key: const Key('hero-video-visibility-key'),
      onVisibilityChanged: (final info) =>
          _handleVisibilityChanged(info, controller),
      child: SizedBox(
        height: context.screenHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // 1. ZEMİN
            Container(color: const Color(0xFF050505)),

            // 2. MASAÜSTÜ
            if (!context.isMobile) ...[
              Positioned.fill(
                child: _buildDesktopCinematicVideo(controller, hasVideo),
              ),
              Positioned.fill(
                child: _buildDesktopContent(context),
              ),
              _buildIntegratedGlassCard(context),
              // Scroll İkonu (Video yüklense de yüklenmese de animasyon başladıysa görünsün)
              if (widget.startAnimations)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: 1.0,
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

            // 3. MOBİL
            if (context.isMobile)
              _buildMobileEditorialLayout(context, controller, hasVideo),
          ],
        ),
      ),
    );
  }

  // ... (Geri kalan _buildMobileEditorialLayout, _buildDesktopCinematicVideo vb. kodların AYNI KALACAK)
  // Sadece yukarıdaki initState ve _initializeAndPlayVideo kısımlarını değiştirmen yeterli.

  // KOLAYLIK OLSUN DİYE DEĞİŞMEYEN KISIMLARI TEKRAR YAZMIYORUM,
  // SENİN KODUNDAKİ GİBİ KALABİLİR.

  // AŞAĞIDAKİLER SENİN KODUNUN AYNISI (KOPYALAYABİLİRSİN):

  Widget _buildMobileEditorialLayout(
    final BuildContext context,
    final VideoPlayerController? controller,
    final bool hasVideo,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            _fallbackImage,
            fit: BoxFit.cover,
            errorBuilder: (final context, final error, final stackTrace) =>
                Container(color: const Color(0xFF1A1A1A)),
          ),
        ),
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
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // ... (Diğer Widgetlar aynı)
        Positioned(
          top: 60,
          left: 24,
          child: Row(
            children: [
              // hasVideo kontrolü eklendi
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
        // ... (Geri kalanlar aynı)
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
        Positioned(
          top: 90,
          left: 24,
          right: 60,
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
              textAlign: TextAlign.left,
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
        Positioned(
          bottom: 270,
          left: 30,
          right: 30,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (final context, final child) {
              return Opacity(
                opacity: _contentOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, -_contentSlide.value),
                  child: child,
                ),
              );
            },
            child: Text(
              'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu sizi bekliyor.',
              textAlign: TextAlign.center,
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

  // MOBIL KART KODU AYNI
  Widget _buildMobileCard(final BuildContext context) {
    // (Senin kodunun aynısı)
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

  // DESKTOP VIDEO KODU AYNI
  Widget _buildDesktopCinematicVideo(
      final VideoPlayerController? controller, final bool hasVideo) {
    // (Senin kodunun aynısı)
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
                  Image.asset(
                    _fallbackImage,
                    fit: BoxFit.cover,
                  ),
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

  // DESKTOP CONTENT KODU AYNI
  Widget _buildDesktopContent(final BuildContext context) {
    // (Senin kodunun aynısı)
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

  // GLASS CARD KODU AYNI
  Widget _buildIntegratedGlassCard(final BuildContext context) {
    // (Senin kodunun aynısı)
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
