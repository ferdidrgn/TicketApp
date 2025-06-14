import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:video_player/video_player.dart';

class ArtCurationVideoSection extends StatefulWidget {
  const ArtCurationVideoSection({super.key});

  @override
  State<ArtCurationVideoSection> createState() =>
      _ArtCurationVideoSectionState();
}

class _ArtCurationVideoSectionState extends State<ArtCurationVideoSection> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FKitapseverleri%20Darlıyorum%20%40bigaripokurlar.mp4?alt=media&token=4d1aed61-2469-4e2a-a54d-4e43eaffd155',
    )..initialize().then((final _) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomSectionTitle(
            title: 'Sanat Kürasyonu', textColor: Colors.amber, fontSize: 50),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 9 / 16,
          child: _controller.value.isInitialized
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoPlayer(_controller),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
