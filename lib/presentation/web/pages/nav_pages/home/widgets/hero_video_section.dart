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
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _videoController;
  bool _isVideoReady = false;

  @override
  bool get wantKeepAlive => true; // ✅ State'i koru

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
        ),
      )
        ..setLooping(true)
        ..setVolume(0)
        ..setPlaybackSpeed(0.5);

      await _videoController.initialize();

      if (mounted) {
        setState(() => _isVideoReady = true);
        await _videoController.play();
        debugPrint('✅ Video playing');
      }
    } catch (e) {
      debugPrint('❌ Video error: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Zorunlu

    return SizedBox(
      height: context.screenHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background
          if (_isVideoReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: const Color(0xFF0a0a1a)),

          // Overlay
          Container(
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
          ),

          // Content
          _buildContent(context),
          _buildGlassCard(context),
          if (!context.isMobile) _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 20, tablet: 60, desktop: 100),
        ),
        child: Column(
          mainAxisAlignment: context.isMobile
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          crossAxisAlignment: context.responsive(
            mobile: CrossAxisAlignment.center,
            desktop: CrossAxisAlignment.start,
          ),
          children: [
            if (context.isMobile) SizedBox(height: context.screenHeight * 0.15),
            Column(
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
                        fontSize: context.responsive(mobile: 12, desktop: 16),
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
                    fontSize:
                        context.responsive(mobile: 32, tablet: 50, desktop: 80),
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (!context.isMobile) ...[
                  const SizedBox(height: 16),
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
                ],
                const SizedBox(height: 32),
                _buildPlayButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: context.responsive(
              mobile: context.screenWidth - 32, tablet: 280, desktop: 320),
          padding: EdgeInsets.all(context.responsive(mobile: 16, desktop: 24)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const Icon(Icons.notifications_none, color: Colors.white70),
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
                        vertical: context.responsive(mobile: 12, desktop: 16)),
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
    );

    if (context.isMobile) {
      return Positioned(bottom: 20, left: 16, right: 16, child: card);
    } else {
      return Positioned(
        right: context.responsive(mobile: 0, tablet: 40, desktop: 60),
        top: context.responsive(mobile: 0, tablet: 180, desktop: 150),
        child: card,
      );
    }
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
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
  }
}
