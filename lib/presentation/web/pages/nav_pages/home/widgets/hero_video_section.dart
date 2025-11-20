import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Modern, dramatik Hero Video Section
/// Parallax effects, animated text, floating premiere card
class HeroVideoSection extends StatefulWidget {
  const HeroVideoSection({super.key});

  @override
  State<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends State<HeroVideoSection>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _floatController;

  late Animation<double> _glowAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    // Glow animation (icon için)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Float animation (premiere card için)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Video setup
    _videoController = VideoPlayerController.network(
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        _videoController.play();
        setState(() => _isVideoReady = true);
        _textController.forward();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Video Background with parallax
          _buildVideoBackground(),

          // Gradient Overlays (multi-layer for depth)
          _buildGradientOverlays(),

          // Animated Content
          _buildMainContent(context),

          // Floating Premiere Card
          _buildFloatingPremiereCard(context),

          // Scroll Indicator
          _buildScrollIndicator(),

          // Decorative particles (optional)
          _buildDecorativeElements(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned.fill(
      child: _isVideoReady
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          : Image.network(
              "https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_205137.jpg?alt=media&token=79e2c500-6f44-42a3-a28d-8b62c84867af",
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildGradientOverlays() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WebColors.darkBlueBackground.withOpacity(0.8),
              Colors.transparent,
              WebColors.darkBlueBackground.withOpacity(0.9),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Positioned(
      top: context.responsive(mobile: 120.0, desktop: 180.0),
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Animated Icon with pulsing glow
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: WebColors.primaryGold
                              .withOpacity(_glowAnimation.value * 0.8),
                          blurRadius: 50 * _glowAnimation.value,
                          spreadRadius: 15 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: WebColors.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.theater_comedy_rounded,
                        size: context.responsive(mobile: 50.0, desktop: 70.0),
                        color: WebColors.darkBlueBackground,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Main Title with shader effect
              ShaderMask(
                shaderCallback: (bounds) =>
                    WebColors.goldGradient.createShader(bounds),
                child: Text(
                  'TiyatRol Sahne Sanatları\nTiyatro Topluluğu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 32.0,
                      tablet: 42.0,
                      desktop: 52.0,
                    ),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: WebColors.primaryGold.withOpacity(0.6),
                        blurRadius: 30,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subtitle with typewriter effect feel
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WebColors.primaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Sahneyle Büyüleyen, Sanatla Dönüştüren',
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 14.0,
                      desktop: 18.0,
                    ),
                    color: WebColors.primaryGoldLight,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPremiereCard(BuildContext context) {
    return Positioned(
      top: context.responsive(mobile: 20.0, desktop: 100.0),
      right: context.responsive(mobile: 15.0, desktop: 40.0),
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: _buildPremiereContent(context),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiereContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.responsive(mobile: 260.0, desktop: 340.0),
      ),
      padding: EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebColors.error,
            WebColors.warning,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WebColors.error.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎬', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PRÖMİYER',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 20.0, desktop: 24.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '27 Haziran 2025, Cuma',
            style: TextStyle(
              fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          Text(
            'Saat 20.00',
            style: TextStyle(
              fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Altunizade Kültür Merkezi',
            style: TextStyle(
              fontSize: context.responsive(mobile: 13.0, desktop: 15.0),
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🎫 Ücretsiz! Biletsiz katılım',
            style: TextStyle(
              fontSize: context.responsive(mobile: 12.0, desktop: 14.0),
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_pin, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Konumu Aç',
                    style: TextStyle(
                      fontSize: context.responsive(mobile: 12.0, desktop: 14.0),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _glowAnimation.value,
            child: Column(
              children: [
                Text(
                  'Keşfetmek İçin Kaydır',
                  style: TextStyle(
                    fontSize: context.captionSize + 2,
                    color: WebColors.primaryGoldLight,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Transform.translate(
                  offset: Offset(0, 10 * _glowAnimation.value),
                  child: Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    size: 36,
                    color: WebColors.primaryGold,
                    shadows: [
                      Shadow(
                        color: WebColors.primaryGold.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Sol üst dekoratif element
            Positioned(
              top: context.responsive(mobile: 100, desktop: 150),
              left: context.responsive(mobile: 20, desktop: 60),
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.1 + (_glowAnimation.value * 0.1),
                    child: Transform.rotate(
                      angle: _floatAnimation.value * 0.01,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              WebColors.primaryGold.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
