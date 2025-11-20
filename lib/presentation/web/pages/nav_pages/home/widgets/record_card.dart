import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// WIDGET: DÖNEN PLAK VE 399 NUMARASI (FİNAL)
// ═══════════════════════════════════════════════════════════
class RecordPlayerCard extends StatefulWidget {
  const RecordPlayerCard({super.key});

  @override
  State<RecordPlayerCard> createState() => _RecordPlayerCardState();
}

class _RecordPlayerCardState extends State<RecordPlayerCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _glitchController;
  late Animation<double> _glitchAnimation;

  // 🔥 FIREBASE STORAGE URL'İNİZ
  final String _audioUrl =
      'https://firebasestorage.googleapis.com/v0/b/saglamspotflutter-2a1a8.firebasestorage.app/o/voice%2Fgoz_kap_vaz_yap_bakirkoyde_hastane.mp3?alt=media&token=ca5de861-384c-4c13-b6f7-2dec245b0f5e';

  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glitchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glitchController, curve: Curves.fastOutSlowIn),
    );

    // Ses dinleyicilerini kurun
    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      if (mounted) {
        setState(() {
          _playerState = s;
        });
      }
    });

    // Mobil/Web ayrımı: Mobil ilk yüklendiğinde kısa bir gösterim yapsın
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.isDesktop) {
        _glitchController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _glitchController.reverse();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glitchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------- SES ÇALMA MANTIKLARI ----------------
  void _playAudio() async {
    if (!_isPlaying) {
      await _audioPlayer.play(UrlSource(_audioUrl));
    }
  }

  void _stopAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
  }

  // WEB: Mouse üzerine gelince
  void _onHover(bool isHovering) {
    if (context.isDesktop) {
      if (isHovering) {
        _glitchController.forward();
      } else {
        _glitchController.reverse();
      }
    }
  }

  // MOBİL/WEB: Kartın 399 yazan kısmına tıklanınca
  void _onTap() {
    if (_isPlaying) {
      _stopAudio();
    } else {
      _playAudio();
    }
    // Glitch animasyonunu tekrar tetikle
    if (_glitchController.status != AnimationStatus.forward) {
      _glitchController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _glitchController.reverse();
        });
      });
    }
  }

  // ---------------- WIDGET BUILDER ----------------
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _glitchController, // Sadece görsel animasyonları dinler
        builder: (context, child) {
          bool isPlaying = _isPlaying;

          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isPlaying
                      ? WebColors.error
                      : WebColors.primaryGold.withOpacity(0.7),
                  width: isPlaying ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold
                      .withOpacity(_glitchAnimation.value * 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Dönen Plak
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: Icon(
                        Icons.audiotrack,
                        size: 32,
                        color: isPlaying
                            ? WebColors.error
                            : WebColors.primaryGoldLight,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 15),

                // 2. 399 NUMARA Bilgisi ve Tıkla Metni
                GestureDetector(
                  onTap: _onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPlaying
                            ? 'SES ÇALIYOR (Durdur)'
                            : 'EŞSİZ DENEY İÇİN TIKLAYINIZ',
                        style: TextStyle(
                          fontSize: context.captionSize,
                          color: isPlaying
                              ? WebColors.error
                              : WebColors.textSecondary,
                          fontWeight:
                              isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // 399 Numara Görünürlüğü (Animasyonlu Opaklık ve Ölçek)
                      Opacity(
                        opacity: 1.0,
                        child: Transform.scale(
                          scale: 0.9 + (_glitchAnimation.value * 0.1),
                          child: Text(
                            'SICIL NO: 399',
                            style: TextStyle(
                              fontSize: context.bodySize + 4,
                              fontWeight: FontWeight.w900,
                              color: WebColors.warning,
                              letterSpacing: 1.5,
                              shadows: [
                                BoxShadow(
                                    color: WebColors.warning
                                        .withOpacity(_glitchAnimation.value),
                                    blurRadius: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. STOP Butonu (Ses Çalarken Görünsün)
                if (isPlaying) ...[
                  const SizedBox(width: 15),
                  InkWell(
                    onTap: _stopAudio,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: WebColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.stop, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
