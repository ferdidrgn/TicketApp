import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../core/theme/app_colors.dart';

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
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/voices%2Fgoz_kap_vaz_yap_bakirkoyde_hastane.mp3?alt=media&token=deb93736-6fd8-45eb-8c8b-8a8f298e5b14';

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
    _audioPlayer.onPlayerStateChanged.listen((final PlayerState s) {
      if (mounted) {
        setState(() {
          _playerState = s;
        });
      }
    });

    // Mobil/Web ayrımı: Mobil ilk yüklendiğinde kısa bir gösterim yapsın
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!context.isDesktop) {
        _glitchController.forward().then((final _) {
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
  Future<void> _playAudio() async {
    if (!_isPlaying) {
      await _audioPlayer.play(UrlSource(_audioUrl));
    }
  }

  Future<void> _stopAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
  }

  // WEB: Mouse üzerine gelince
  void _onHover(final bool isHovering) {
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
      _glitchController.forward().then((final _) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _glitchController.reverse();
        });
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = !context.isDesktop;

    // MAKSİMUM KÜÇÜLTME DEĞERLERİ
    final double cardPadding = isMobile ? 6.0 : 15.0; // 6 piksel
    final double iconSize = isMobile ? 16.0 : 32.0; // 16 piksel
    final double spacing = isMobile ? 4.0 : 15.0;

    final double headlineSize =
        isMobile ? 8.0 : context.captionSize; // "EŞSİZ DENEY..."
    final double sicilNoSize =
        isMobile ? 12.0 : context.bodySize + 4; // "SICIL NO: 399"

    final double stopButtonPadding = isMobile ? 2.0 : 8.0;
    final double stopIconSize = isMobile ? 12.0 : 20.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => _onHover(true),
      onExit: (final _) => _onHover(false),
      child: AnimatedBuilder(
        animation: _glitchController,
        builder: (final context, final child) {
          final bool isPlaying = _isPlaying;

          return Container(
            // Kartın iç padding'i minimize edildi
            padding: EdgeInsets.all(cardPadding),
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
              // İkon ve metin birbirine daha yakın durmalı
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Dönen Plak
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (final context, final child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: Icon(
                        Icons.audiotrack,
                        size: iconSize, // Minimize edildi
                        color: isPlaying
                            ? WebColors.error
                            : WebColors.primaryGoldLight,
                      ),
                    );
                  },
                ),
                SizedBox(width: spacing), // Boşluk minimize edildi

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
                          fontSize: headlineSize, // Minimize edildi
                          color: isPlaying
                              ? WebColors.error
                              : WebColors.textSecondary,
                          fontWeight:
                              isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: isMobile ? 1 : 5),
                      // 399 Numara
                      Opacity(
                        opacity: 1.0,
                        child: Transform.scale(
                          scale: 0.9 + (_glitchAnimation.value * 0.1),
                          child: Text(
                            'SICIL NO: 399',
                            style: TextStyle(
                              fontSize: sicilNoSize,
                              // Minimize edildi
                              fontWeight: FontWeight.w900,
                              color: WebColors.warning,
                              letterSpacing: isMobile ? 0.5 : 1.5,
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
                  SizedBox(width: spacing),
                  InkWell(
                    onTap: _stopAudio,
                    child: Container(
                      padding: EdgeInsets.all(stopButtonPadding),
                      // Minimize edildi
                      decoration: BoxDecoration(
                        color: WebColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: stopIconSize, // Minimize edildi
                      ),
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
