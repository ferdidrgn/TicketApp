import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/scroll_down_indicator.dart';
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
      'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
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
            const Center(child: CircularProgressIndicator()),

          // Siyah overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // Başlık ve ikon
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height < 600 ? 40 : 100,
              ),
              child: Column(
                children: [
                  const Icon(Icons.theaters, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  AnimatedTitle(
                    glowAnimation: _glowAnimation,
                    text: 'Sahne Sanatları\nTiyatro Topluluğu',
                  ),
                ],
              ),
            ),
          ),

          // Scroll oku
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(child: ScrollDownIndicator()),
          ),
        ],
      ),
    );
  }
}
