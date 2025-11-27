import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class HeroVideoSection extends StatefulWidget {
  const HeroVideoSection({super.key});

  @override
  State<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends State<HeroVideoSection>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _mainController;

  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _pulseAnimation;

  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _videoController = VideoPlayerController.network(
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..setPlaybackSpeed(0.5)
      ..initialize().then((final _) {
        if (mounted) {
          _videoController.play();
          setState(() => _isVideoReady = true);
          _mainController.forward();
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: context.screenHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoBackground(),
          _buildCinematicOverlay(),
          _buildHeroContent(context),
          _buildGlassPremiereCard(context),
          if (!context.isMobile) _buildScrollIndicator(context),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0a0a1a),
        child: ClipRect(
          child: ShaderMask(
            shaderCallback: (final rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.6, 0.9],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCinematicOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
            const Color(0xFF0a0a1a).withOpacity(0.7),
            const Color(0xFF0a0a1a),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeroContent(final BuildContext context) {
    final MainAxisAlignment mainAlign =
        context.isMobile ? MainAxisAlignment.start : MainAxisAlignment.center;

    final EdgeInsets margin = context.isMobile
        ? EdgeInsets.only(top: context.screenHeight * 0.15)
        : EdgeInsets.zero;

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 20, tablet: 60, desktop: 100),
        ),
        child: Column(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: context.responsive(
            mobile: CrossAxisAlignment.center,
            desktop: CrossAxisAlignment.start,
          ),
          children: [
            SizedBox(height: margin.top),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideUpAnimation,
                child: Column(
                  crossAxisAlignment: context.responsive(
                    mobile: CrossAxisAlignment.center,
                    desktop: CrossAxisAlignment.start,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: context.responsive(
                        mobile: MainAxisAlignment.center,
                        desktop: MainAxisAlignment.start,
                      ),
                      children: [
                        Icon(Icons.theater_comedy,
                            color: WebColors.primaryGold,
                            size: context.responsive(mobile: 20, desktop: 30)),
                        const SizedBox(width: 8),
                        Text(
                          'SAHNE SANATLARI',
                          style: TextStyle(
                            color: WebColors.primaryGold,
                            fontSize:
                                context.responsive(mobile: 12, desktop: 16),
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HİKAYELER\nGERÇEĞE DÖNÜŞÜYOR',
                      textAlign: context.responsive(
                          mobile: TextAlign.center, desktop: TextAlign.left),
                      style: TextStyle(
                        fontSize: context.responsive(
                            mobile: 32, tablet: 50, desktop: 80),
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 10),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!context.isMobile) ...[
                      Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Text(
                          'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    _buildPlayButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 20, desktop: 32),
          vertical: context.responsive(mobile: 10, desktop: 16),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: WebColors.primaryGold, width: 1),
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill,
                color: WebColors.primaryGold,
                size: context.responsive(mobile: 20, desktop: 32)),
            SizedBox(width: context.responsive(mobile: 8, desktop: 16)),
            Text(
              'SEZON TANITIMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive(mobile: 12, desktop: 16),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPremiereCard(final BuildContext context) {
    if (context.isMobile) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: _buildCardContent(context),
      );
    } else {
      return Positioned(
        // ✅ DÜZELTİLDİ: mobile parametresi '0' olarak eklendi.
        // Bu blok sadece desktop/tablet'te çalışsa bile parametre zorunlu.
        right: context.responsive(mobile: 0, tablet: 40, desktop: 60),
        top: context.responsive(mobile: 0, tablet: 180, desktop: 150),
        child: _buildCardContent(context),
      );
    }
  }

  Widget _buildCardContent(final BuildContext context) {
    final double width = context.responsive(
      mobile: context.screenWidth - 32,
      tablet: 280,
      desktop: 320,
    );

    final EdgeInsets margin =
        context.isMobile ? const EdgeInsets.only(bottom: 20) : EdgeInsets.zero;

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: width,
              padding:
                  EdgeInsets.all(context.responsive(mobile: 16, desktop: 24)),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
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
                      if (!context.isMobile)
                        const Icon(Icons.notifications_none,
                            color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'METAFOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive(mobile: 20, desktop: 28),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Times New Roman',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '27 Haziran 2025 • 20:00\nAltunizade Kültür Merkezi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: context.responsive(mobile: 12, desktop: 14),
                      height: 1.4,
                    ),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(
                            vertical:
                                context.responsive(mobile: 12, desktop: 16)),
                      ),
                      child: Text('KONUMU GÖR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  context.responsive(mobile: 12, desktop: 14))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollIndicator(final BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (final context, final child) {
            return Transform.translate(
              offset: Offset(0, _pulseAnimation.value),
              child: Column(
                children: [
                  Text(
                    'AŞAĞI KAYDIR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: WebColors.primaryGold.withOpacity(0.8),
                    size: 30,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
