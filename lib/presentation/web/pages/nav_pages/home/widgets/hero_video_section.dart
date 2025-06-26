import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/scroll_down_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/widgets/custom_animated_title.dart';

class HeroVideoSection extends StatefulWidget {
  const HeroVideoSection({super.key});

  @override
  State<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends State<HeroVideoSection>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _videoController = VideoPlayerController.network(
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((final _) {
        _videoController.play();
        setState(() => _isVideoReady = true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          // Video
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
            Center(
                child: Image.network(
                    "https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_205137.jpg?alt=media&token=79e2c500-6f44-42a3-a28d-8b62c84867af")),

          // Siyah overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // Başlık ve ikon (orta üst)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height < 600 ? 40 : 100,
              ),
              child: Column(
                children: [
                  const Icon(Icons.theater_comedy_rounded,
                      size: 60, color: Colors.amber),
                  const SizedBox(height: 16),
                  AnimatedTitle(
                    glowAnimation: _glowAnimation,
                    text: 'TiyatRol Sahne Sanatları\nTiyatro Topluluğu',
                  ),
                ],
              ),
            ),
          ),

          // Scroll oku
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: ScrollDownIndicator()),
          ),

          _buildPremiereTag()
        ],
      ),
    );
  }

  Widget _buildPremiereTag() {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Positioned(
      top: isWeb ? 60 : 20,
      right: isWeb ? 40 : 15,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 24 : 15,
          vertical: isWeb ? 20 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: isWeb ? 320 : 260,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎬 PRÖMİYER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isWeb ? 20 : 16,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '27 Haziran 2025, Cuma\nSaat 20.00\nAltunizade Kültür Merkezi',
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 16 : 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🎫 Ücretsiz! Biletsiz katılım',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isWeb ? 14 : 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // Google Maps Link
            GestureDetector(
              onTap: () async {
                const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Konumu Aç (Google Haritalar)',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
