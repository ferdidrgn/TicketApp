import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/home/domain/entities/audio_highlight.dart';

/// 🎧 "Sesli Deneyim" bölümündeki tek bir monolog/tirat kaydını çalan,
/// yeniden kullanılabilir kart. `record_player_card.dart`'ın aksine tek bir
/// sabit ses dosyasına bağlı DEĞİL — herhangi bir [AudioHighlight] ile
/// çalışır, bu yüzden küratörün Firestore'a eklediği her yeni kayıt otomatik
/// olarak burada çalınabilir olur.
class AudioHighlightCard extends StatefulWidget {
  final AudioHighlight highlight;
  const AudioHighlightCard({super.key, required this.highlight});

  @override
  State<AudioHighlightCard> createState() => _AudioHighlightCardState();
}

class _AudioHighlightCardState extends State<AudioHighlightCard> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((final s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((final d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((final p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((final _) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (!_loaded) {
      _loaded = true;
      await _player.play(UrlSource(widget.highlight.audioUrl));
    } else {
      await _player.resume();
    }
  }

  String _fmt(final Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying
              ? WebColors.primaryGold.withOpacity(0.5)
              : WebColors.microBorder,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: widget.highlight.coverImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.highlight.coverImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: WebColors.darkBlueAccent,
                          alignment: Alignment.center,
                          child: const Icon(Icons.mic_rounded,
                              color: WebColors.primaryGoldLight, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.highlight.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                    if (widget.highlight.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(widget.highlight.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _toggle,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: WebColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: WebColors.darkBlueAccent,
                    valueColor: const AlwaysStoppedAnimation(
                        WebColors.primaryGoldLight),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _duration == Duration.zero ? '--:--' : _fmt(_duration),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
